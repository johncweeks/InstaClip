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
import Metal

typealias MetalPositionComponent = Float32  // metal shaders require 32 bit float component values in vertex, position

private let SAMPLE_DURATION = 60*2  // length of sample in seconds
private let SAMPLE_SCALE = 20       // seconds of sample displayed in screen width

private let BUFFER_COUNT = 3

class Waveform {
    
//    var ringBuf: RingBuffer<Float32>
    
    let urlAsset: AVURLAsset
    let mtlDevice: MTLDevice
    
    private let mtlBuffers: [MTLBuffer]
    private var availableMtlBufferIndex: Int = 0
    var avaliableMtlBufferSemaphore = dispatch_semaphore_create(BUFFER_COUNT)
    
    private var assetTrack: AVAssetTrack? = nil
    private var outputSettings: [String: AnyObject]? = nil
    
    private var channelCount: Int = 0
    private var conflateBucketSize: Int = 0
    
    private let currentTime: CMTime
    private var waveform: ContiguousArray<MetalPositionComponent> = []
    
    private var portraitNormalizedY: ContiguousArray<MetalPositionComponent> = []    // Left Y 0...1, Right Y 0...-1, sized to portrait pixel count
    private var landscapeNormalizedY: ContiguousArray<MetalPositionComponent> = []   // Left Y 0...1, Right Y 0...-1, sized to landscape pixel count
    
    
    init(podcastURL :NSURL, mtlDevice: MTLDevice, currentTime: CMTime) {
        urlAsset = AVURLAsset(URL: podcastURL)
        self.mtlDevice = mtlDevice
        self.currentTime = currentTime
        
        // Size buffer large enough for landscape
        let mtlBufferLength = Int(max(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * UIScreen.mainScreen().scale) * sizeof(MetalPositionComponent) * 2
        var mBufs = [MTLBuffer]()
        for _ in 0..<BUFFER_COUNT {
            let buf = mtlDevice.newBufferWithLength(mtlBufferLength, options: MTLResourceOptions.CPUCacheModeDefaultCache) //MTLResourceOptions.CPUCacheModeDefaultCache
            mBufs.append(buf)
        }
        mtlBuffers = mBufs
        // mark buffers as unavailble. Available once waveform is created
        for _ in 0..<BUFFER_COUNT{
            dispatch_semaphore_wait(avaliableMtlBufferSemaphore, DISPATCH_TIME_FOREVER)
        }
        
//        do {
//            ringBuf = try RingBuffer<Float32>(count: 8192)
//        } catch {
//            return
//        }
        
//        ringBuf =  RingBuffer<Float32>()
//        do {
//            try ringBuf.reserveCapacity(8124)
//        } catch {
//            print("handle this error")
//        }
//        
//        let value: Float32 = ringBuf[0]
        
        urlAsset.loadValuesAsynchronouslyForKeys(["tracks"]) { () -> Void in
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
            self.assetTrack = self.urlAsset.tracksWithMediaType(AVMediaTypeAudio).first
            guard self.assetTrack != nil,
                let formatDescription = self.assetTrack?.formatDescriptions.first else {
                    print("Missing audio track or it's format description")
                    return
            }
            

            // as! CMFormatDescription should always succeed
            guard CMFormatDescriptionGetMediaType(formatDescription as! CMFormatDescription) == kCMMediaType_Audio else {
                print("format description is NOT Audio")
                return
            }
            self.outputSettings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMBitDepthKey: sizeof(MetalPositionComponent) * 8
            ]
            
            // as! CMAudioFormatDescription should always succeed
            let audioFormatDescription = formatDescription as! CMAudioFormatDescription
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)
            self.channelCount = Int(asbd.memory.mChannelsPerFrame)
            self.conflateBucketSize = (Int(asbd.memory.mSampleRate)*Int(asbd.memory.mChannelsPerFrame)*SAMPLE_SCALE) / Int(min(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * UIScreen.mainScreen().scale)
            
            
            self.waveform.reserveCapacity((SAMPLE_DURATION/SAMPLE_SCALE) * Int(max(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * UIScreen.mainScreen().scale) * 2)
            
            self.portraitNormalizedY.reserveCapacity((SAMPLE_DURATION/SAMPLE_SCALE) * Int(min(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * UIScreen.mainScreen().scale) * 2)
            self.landscapeNormalizedY.reserveCapacity((SAMPLE_DURATION/SAMPLE_SCALE) * Int(max(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height) * UIScreen.mainScreen().scale) * 2)

            self.readAndConflate(currentTime, duration: SAMPLE_DURATION)
        }
    }
    
    deinit {
        for _ in 0..<BUFFER_COUNT{
            dispatch_semaphore_signal(avaliableMtlBufferSemaphore)
        }
    }
    
    func vertexMtlBuffer2(index: Int) -> (mtlBuffer: MTLBuffer, vertexCount: Int, avaliableMtlBufferSemaphore: dispatch_semaphore_t) {
        
        
        dispatch_semaphore_wait(avaliableMtlBufferSemaphore, DISPATCH_TIME_FOREVER)
        
        let mtlBuffer = mtlBuffers[availableMtlBufferIndex]
        availableMtlBufferIndex = (availableMtlBufferIndex+1) % BUFFER_COUNT
        
        // FIXME: should be &ringBuf[]
        memcpy(mtlBuffer.contents(), &waveform[(index*2)], mtlBuffer.length)
        return (mtlBuffer, mtlBuffer.length/sizeof(MetalPositionComponent), avaliableMtlBufferSemaphore)
        
    }
    
    func vertexMtlBuffer(index: Int) -> (mtlBuffer: MTLBuffer, vertexCount: Int, avaliableMtlBufferSemaphore: dispatch_semaphore_t) {
        
        dispatch_semaphore_wait(avaliableMtlBufferSemaphore, DISPATCH_TIME_FOREVER)
        
        let mtlBuffer = mtlBuffers[availableMtlBufferIndex]
        availableMtlBufferIndex = (availableMtlBufferIndex+1) % BUFFER_COUNT
        
        memcpy(mtlBuffer.contents(), &waveform[(index*2)], mtlBuffer.length)
        
        return (mtlBuffer, mtlBuffer.length/sizeof(MetalPositionComponent), avaliableMtlBufferSemaphore) //Int(max(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)) * 2)
    }
    
    func indexToTime(index: Float) -> CMTime {
        
        let delta = Float64((index / Float(waveform.count/2)) * Float(SAMPLE_DURATION))
        let timeSec = CMTimeGetSeconds(currentTime) + delta
        
        return CMTimeMakeWithSeconds(timeSec, currentTime.timescale)
    }
    
    private func readAndConflate(startTimeCMT: CMTime, duration: Int) {
        
        let start = NSDate()
        let assetReaderTrackOutput = AVAssetReaderTrackOutput.init(track: assetTrack!, outputSettings: outputSettings)
        
        do {
            let assetReader = try AVAssetReader(asset: self.urlAsset)
            
            let stopTimeCMT = CMTimeAdd(startTimeCMT, CMTimeMakeWithSeconds(Double(duration), Int32(NSEC_PER_SEC)))
            assetReader.timeRange = CMTimeRangeFromTimeToTime(startTimeCMT, stopTimeCMT)
            assetReader.addOutput(assetReaderTrackOutput)
            assetReader.startReading()
            
            var tempBuffer = ContiguousArray<MetalPositionComponent>() //[SampleType]() //(count:(32*1024)/sizeof(SampleType), repeatedValue: 0)
            var leftMax: MetalPositionComponent = -1.0
            var rightMax: MetalPositionComponent = -1.0
            var sampleTotal: UInt64 = 0
            var sampleCount: Int = 0
            while (assetReader.status == .Reading) {
                if let sampleBuffer = assetReaderTrackOutput.copyNextSampleBuffer(),
                    //formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
                    blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                        //print(CMBlockBufferGetDataLength(blockBuffer))
                        //print(CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer)))
                        // AudioStreamBasicDescription
                        //See CoreAudioTypes.h for the definition of AudioStreamBasicDescription.
                        //                            if sampleCount == 0 {
                        //                                print(formatDescription)
                        //                            }
                        var length = CMBlockBufferGetDataLength(blockBuffer)
                        if tempBuffer.capacity < length / sizeof(MetalPositionComponent) {
                            tempBuffer.reserveCapacity(length / sizeof(MetalPositionComponent))
                        }
                        sampleTotal += UInt64(length / sizeof(MetalPositionComponent))
                        var returnedPtr: UnsafeMutablePointer<Int8> = nil
                        let status = CMBlockBufferAccessDataBytes(blockBuffer, 0, length, &tempBuffer, &returnedPtr)
                        if status == kCMBlockBufferNoErr {
                            if returnedPtr != nil {
                                var samplePtr = unsafeBitCast(returnedPtr, UnsafeMutablePointer<MetalPositionComponent>.self)
                                for ( ; length>0; length-=(sizeof(MetalPositionComponent)*2), samplePtr+=2) {
                                    sampleCount += 2
                                    if samplePtr.memory > leftMax {
                                        leftMax = samplePtr.memory
                                    }
                                    if (samplePtr+1).memory > rightMax {
                                        rightMax = (samplePtr+1).memory
                                    }
                                    if sampleCount % conflateBucketSize == 0 {
                                        waveform.append((leftMax+1.0)/2.0)              // map from PCM sample -1...1 to metal vertex y 0...1
                                        waveform.append(((rightMax+1.0)/2.0) * -1.0)    // map from PCM sample -1...1 to metal vertex y -1...0
                                        leftMax = -1.0
                                        rightMax = -1.0
                                    }
                                }
                            } else {
                                print("The desired amount of block buffer data could not be accessed at the given offset.")
                            }
                        } else {
                            print("Error OSStatus ", status)
                        }
                }
            }
            print(NSDate().timeIntervalSinceDate(start))
            print(waveform.count, waveform.capacity, conflateBucketSize)
            
            // allow waveform, buffers to be accessed
            for _ in 0..<BUFFER_COUNT{
                dispatch_semaphore_signal(avaliableMtlBufferSemaphore)
            }
            
        }
        catch let error as NSError {
            print(error)
        }
        catch {
            print(error)
        }
    }
}