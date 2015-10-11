//
//  Waveform.swift
//  InstaClip Player
//
//  Created by John Weeks on 10/5/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import Foundation
import AVFoundation
import CoreAudioKit

private typealias SampleType = Float32

private let SAMPLE_DURATION = 20

class Waveform {
    
    let urlAsset: AVURLAsset
    
    init(podcastURL :NSURL) {
        urlAsset = AVURLAsset(URL: podcastURL)
    }
    
    func readAndReduce(startTimeCMT: CMTime) {
        urlAsset.loadValuesAsynchronouslyForKeys(["tracks"]) { () -> Void in
            let start = NSDate()
            var error: NSError?
            let status = self.urlAsset.statusOfValueForKey("tracks", error: &error)
            guard  status == .Loaded else {
                if error != nil {
                    print("tracks NOT loaded, status: \(status)")
                } else {
                    print(error)
                }
                return
            }
            guard let assetTrack = self.urlAsset.tracksWithMediaType(AVMediaTypeAudio).first,
                formatDescription = assetTrack.formatDescriptions.first else {
                    print("Missing audio track or it's format description")
                    return
            }
            // as! CMFormatDescription should always succeed
            guard CMFormatDescriptionGetMediaType(formatDescription as! CMFormatDescription) == kCMMediaType_Audio else {
                print("format description is NOT Audio")
                return
            }
            
            let outputSettings: [String: AnyObject] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMBitDepthKey: sizeof(SampleType)*8
            ]
            let assetReaderTrackOutput = AVAssetReaderTrackOutput.init(track: assetTrack, outputSettings: outputSettings)
            var waveform: [SampleType] = []
            let audioFormatDescription = formatDescription as! CMAudioFormatDescription
            print(audioFormatDescription)
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)
            waveform.reserveCapacity(SAMPLE_DURATION)
            print(Int(asbd.memory.mSampleRate))
            do {
                let assetReader = try AVAssetReader(asset: self.urlAsset)
                
                let stopTimeCMT = CMTimeAdd(startTimeCMT, CMTimeMakeWithSeconds(Double(SAMPLE_DURATION), Int32(NSEC_PER_SEC)))
                assetReader.timeRange = CMTimeRangeFromTimeToTime(startTimeCMT, stopTimeCMT)
                assetReader.addOutput(assetReaderTrackOutput)
                assetReader.startReading()
                
                var tempBuffer = [SampleType](count:(32*1024)/sizeof(SampleType), repeatedValue: 0)
                var min: Float32 = 0
                var max: Float32 = 0
                var sampleCount: UInt64 = 0
                while (assetReader.status == .Reading) {
                    if let sampleBuffer = assetReaderTrackOutput.copyNextSampleBuffer(),
                        formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
                        blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                            //print(CMBlockBufferGetDataLength(blockBuffer))
                            //print(CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer)))
                            // AudioStreamBasicDescription
                            //See CoreAudioTypes.h for the definition of AudioStreamBasicDescription.
                            if sampleCount == 0 {
                                print(formatDescription)
                            }
                            let offset = 0
                            var length = CMBlockBufferGetDataLength(blockBuffer)
                            if tempBuffer.capacity * sizeof(SampleType) < length {
                                tempBuffer = [SampleType](count:length/sizeof(SampleType), repeatedValue: 0)
                            }
                            sampleCount += UInt64(length / sizeof(SampleType))
                            var returnedPtr: UnsafeMutablePointer<Int8> = nil
                            let status = CMBlockBufferAccessDataBytes(blockBuffer, offset, length, &tempBuffer, &returnedPtr)
                            if status == kCMBlockBufferNoErr {
                                if returnedPtr != nil {
                                    var samplePtr = unsafeBitCast(returnedPtr, UnsafeMutablePointer<SampleType>.self)
                                    for ( ; length>0; length-=sizeof(SampleType), samplePtr+=1) {
                                        let shiftedSample = samplePtr.memory //+ 1
                                        if shiftedSample < min {
                                            min = shiftedSample
                                        }
                                        if shiftedSample > max {
                                            max = shiftedSample
                                        }
                                    }
                                }
                            } else {
                                print("Error OSStatus ", status)
                            }
                    } 
                }
                print(sampleCount, sampleCount/UInt64(asbd.memory.mSampleRate))
                print(NSDate().timeIntervalSinceDate(start))
                print(min, max)
            }
            catch let error as NSError {
                print(error)
            }
            catch {
                print(error)
            }
        }
    }
}