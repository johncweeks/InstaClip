//
//  WaveformViewModel.swift
//  InstaClip Player
//
//  Created by John Weeks on 4/7/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

// MVVM observer bindings from https://medium.com/ios-os-x-development/ios-architecture-patterns-ecba4c38de52#.s1rv9gq2f

protocol WaveformViewModelProtocol: class {
    var duration: CMTime! { get }
    var durationDidChange: ((WaveformViewModelProtocol) -> ())? { get set } // function to call when duration did change
    init(_ podcastURL: NSURL)
    func monoPointsLEI16(startingAt startTime: Float64) -> [CGPoint]
}


class WaveformViewModel: WaveformViewModelProtocol {
    
    private var urlAssetModel: AVURLAsset!
    private var audioAssetTrackModel: AVAssetTrack!
    private var outputSettings: [String: AnyObject] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMBitDepthKey:  sizeof(Float32) * 8 ]
    private var channelCount: Int!
    private var reduceBy: Int!
    private var sampleRate: CGFloat!
    
    var duration: CMTime! {
        didSet {
            self.durationDidChange?(self)
        }
    }
    var durationDidChange: ((WaveformViewModelProtocol) -> ())?
    
    private init() {}
    
    convenience required init(_ podcastURL: NSURL) {
        
        self.init()

        self.urlAssetModel = AVURLAsset(URL: podcastURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.urlAssetModel.loadValuesAsynchronouslyForKeys(["tracks"]) { () -> Void in
            
            self.audioAssetTrackModel = self.urlAssetModel.tracksWithMediaType(AVMediaTypeAudio).first
            guard self.audioAssetTrackModel != nil else {
                assert(false, "Must have an audio track")
                return
            }
            guard let formatDescription = self.audioAssetTrackModel.formatDescriptions.first else {
                assert(false, "Audio track must have format description")
                return
            }
            //let formatDescription = self.audioAssetTrackModel.formatDescriptions.first! as! CMAudioFormatDescription

            let audioFormatDescription = formatDescription as! CMAudioFormatDescription
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)
            
            guard asbd.memory.mChannelsPerFrame == 1 || asbd.memory.mChannelsPerFrame == 2 else {
                assert(false, "Audio track must be mono or stereo")
                return
            }
            self.channelCount = Int(asbd.memory.mChannelsPerFrame)

            self.sampleRate = CGFloat(asbd.memory.mSampleRate)
            self.reduceBy = Int(ceil(self.sampleRate / (kPointsPerSecond * UIScreen.mainScreen().scale))) - 1 // need n + 1 points to draw from 0 to n
            
            //print("duration \(CMTimeGetSeconds(self.audioAssetTrackModel.timeRange.duration))")
            self.duration = self.audioAssetTrackModel.timeRange.duration

            return
        }
    }
    
    func monoPointsLEI16(startingAt startTime: Float64) -> [CGPoint] {
        // TODO: unit tests for mono and stereo file
        //var start = NSDate()
        var monoPoints = [CGPoint]()
        monoPoints.reserveCapacity(Int(ceil(kWaveformSampleSeconds * kPointsPerSecond * UIScreen.mainScreen().scale + 1)))
        
        guard startTime < CMTimeGetSeconds(self.duration) else {
            return monoPoints
        }
        let stopTime: Float64 = startTime + Float64(kWaveformSampleSeconds) > CMTimeGetSeconds(self.duration) ? CMTimeGetSeconds(self.duration) : startTime + Float64(kWaveformSampleSeconds)
        let startTimeCMT = CMTimeMakeWithSeconds(startTime, self.duration.timescale)
        let stopTimeCMT = CMTimeMakeWithSeconds(stopTime, self.duration.timescale)
        //print("monoPointsLEI16 \(startTime) \(stopTime)")
        let outputSettingsLEI16: [String: AnyObject] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey:  sizeof(Int16) * 8 ]
        do {
            let assetReader = try AVAssetReader(asset: self.urlAssetModel)
            
            let assetReaderTrackOutput = AVAssetReaderTrackOutput.init(track: self.audioAssetTrackModel, outputSettings: outputSettingsLEI16)
            
            assetReader.timeRange = CMTimeRangeFromTimeToTime(startTimeCMT, stopTimeCMT)
            assetReader.addOutput(assetReaderTrackOutput)
            assetReader.startReading()
            
            var tempBuffer = ContiguousArray<Int16>()
            var x: CGFloat = 0.0
            var maxY: Int16 = Int16.min
            var samplesProcessed = 0
            
            //print("monoPoints duration: \(NSDate().timeIntervalSinceDate(start)))")
            //start = NSDate()
            while (assetReader.status == .Reading) {
                if let sampleBuffer = assetReaderTrackOutput.copyNextSampleBuffer(),
                    blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                    
                    //let audioFormatDescription: CMAudioFormatDescription? = CMSampleBufferGetFormatDescription(sampleBuffer)
                    //let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription!)
                    //print(asbd.memory)
                    
                    var returnedPtr: UnsafeMutablePointer<Int8> = nil
                    let lengthInBytes = CMBlockBufferGetDataLength(blockBuffer)
                    if tempBuffer.capacity < lengthInBytes/sizeof(Int16) {
                        tempBuffer.reserveCapacity(lengthInBytes/sizeof(Int16))
                    }
                    let status = CMBlockBufferAccessDataBytes(blockBuffer, 0, lengthInBytes, &tempBuffer, &returnedPtr)
                    if status == kCMBlockBufferNoErr {
                        if returnedPtr != nil {
                            let samplePtr = unsafeBitCast(returnedPtr, UnsafeMutablePointer<Int16>.self)
                            for i in 0.stride(to: lengthInBytes/sizeof(Int16), by: self.channelCount) {
                                samplesProcessed += 1
                                // abs(Int16.min)) overflows because it's value is Int16.max+1
                                let absValue = (samplePtr+i).memory == Int16.min ? Int16.max : abs((samplePtr+i).memory)
                                if absValue > maxY {
                                    maxY = absValue
                                }
                                if samplesProcessed % self.reduceBy == 0 {
                                    let point = CGPoint(x: x, y: CGFloat(maxY)/CGFloat(Int16.max))
                                    // TODO: move this to unit test
                                    if point.y < 0 || point.y > 1 {
                                        assert(false, "y must be 0...1 \(point) \(maxY)")
                                    }
                                    monoPoints.append(point)
                                    x += 1.0 / UIScreen.mainScreen().scale
                                    //print(maxY)
                                    maxY = Int16.min
                                }
                            }
                        } else {
                            assert(false, "failed to returnedPtr")
                        }
                    } else {
                        assert(false, "failed to access buffer \(status)")
                    }
                } else {
                    assert(assetReader.status == .Completed, "failed to get next buffer")
                }
            }
            if samplesProcessed % self.reduceBy != 0 || samplesProcessed < self.reduceBy {
                let point = CGPoint(x: x, y: CGFloat(maxY)/CGFloat(Int16.max))
                monoPoints.append(point)
            }
            // TODO: move this to unit test
            if Int(ceil(kWaveformSampleSeconds * kPointsPerSecond * UIScreen.mainScreen().scale + 1)) != monoPoints.count {
                //assert(false, "need n + 1 points to draw from 0 to n\n\(Int(ceil(kWaveformSampleSeconds * kPointsPerSecond * UIScreen.mainScreen().scale + 1))) != \(monoPoints.count)")
            }
            if samplesProcessed != Int((stopTime - startTime) * Float64(self.sampleRate)) {
                print("monoPoints incorrect sample count. was \(samplesProcessed) should be \((stopTime - startTime) * Float64(self.sampleRate))")
            }
        } catch let error as NSError {
            assert(false, String(error))
        } catch {
            assert(false, String(error))
        }
        
        //print("monoPoints duration: \(NSDate().timeIntervalSinceDate(start)))")
        return monoPoints
    }
    
}

