//
//  Clip.swift
//  InstaClip
//
//  Created by John Weeks on 8/9/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

// TODO: checkout AVAssetExportSession, possibly simpler
// TODO: clip from streaming media??

import Foundation
import AVFoundation

typealias ClipCompletionHandler = (ClipResult) -> Void

enum ClipResult: ErrorType {
    case Success(NSURL)
    case Failure(String)
}

struct Clip {
    
    let transcodeQueue = dispatch_queue_create("net.moonrisesoftware.clipcaster.transcodequeue", nil)
    
    func newFromURL(podcastURL :NSURL, startTimeCMT: CMTime, completionHandler: ClipCompletionHandler) -> Void {
        
        let urlAsset = AVURLAsset(URL: podcastURL)
        
        do {
            let assetReader = try AVAssetReader(asset: urlAsset)
            let stopTimeCMT = CMTimeAdd(startTimeCMT, CMTimeMakeWithSeconds(Float64(20.0), Int32(NSEC_PER_SEC)))
            let clipTimeRange = CMTimeRangeFromTimeToTime(startTimeCMT, stopTimeCMT)
            assetReader.timeRange = clipTimeRange
            
            let assetReaderOutput = AVAssetReaderAudioMixOutput(audioTracks: urlAsset.tracksWithMediaType(AVMediaTypeAudio), audioSettings: nil)
            if !assetReader.canAddOutput(assetReaderOutput) {
                throw ClipResult.Failure("Asset Reader Can't Add Output")
            }
            assetReader.addOutput(assetReaderOutput)
            
            let outputFile = NSTemporaryDirectory() + NSUUID().UUIDString + ".m4a"
            let outputURL = NSURL.fileURLWithPath(outputFile)
            let assetWriter = try AVAssetWriter(URL: outputURL, fileType: AVFileTypeMPEG4) //AVFileTypeMPEG4
            assetWriter.metadata = urlAsset.commonMetadata
            
            // need sampleRate & channelCount for AVAssetWriterInput output settings
            let audioFile = try AVAudioFile(forReading: podcastURL)
            let processingFormat = audioFile.processingFormat
            let channelCount = Int(processingFormat.channelCount)
            // bad parameters will cause AVFoundation to throw an Objective C exception and that crashes a Swift app
            //“Although Swift error handling resembles exception handling in Objective-C, it is entirely separate functionality. If an Objective-C method throws an exception during runtime, Swift triggers a runtime error. There is no way to recover from Objective-C exceptions directly in Swift. Any exception handling behavior must be implemented in Objective-C code used by Swift.”
            // Excerpt From: Apple Inc. “Using Swift with Cocoa and Objective-C (Swift 2 Prerelease).” iBooks. https://itun.es/us/utTW7.l
            if !(channelCount==1 || channelCount==2)  {
                throw ClipResult.Failure("Input invalid channel count")
            }
            var sampleRate = processingFormat.sampleRate
            if sampleRate < 800.0 {
                sampleRate = 800.0
            } else if sampleRate > 44100.0 {
                sampleRate = 44100.0
            }
            let assetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: sampleRate, AVNumberOfChannelsKey: channelCount]) // processingFormat.sampleRate
            if !assetWriter.canAddInput(assetWriterInput) {
                throw ClipResult.Failure("Asset Writer Can't Add Input")
            }
            assetWriter.addInput(assetWriterInput)
            
            if !assetWriter.startWriting() {
                if assetWriter.status == .Failed {
                    // docs say error object will exist so forced unwrapped succeeds
                    throw ClipResult.Failure(assetWriter.error!.localizedDescription)
                } else {
                    throw ClipResult.Failure("Error startWriting \(String(reflecting:assetWriter.status))")
                }
            }
            if !assetReader.startReading() {
                if assetReader.status == .Failed {
                    // docs say error object will exist so forced unwrapped succeeds
                    throw ClipResult.Failure(assetReader.error!.localizedDescription)
                } else {
                    throw ClipResult.Failure("Error startReading \(String(reflecting:assetReader.status))")
                }
            }
            
            assetWriter.startSessionAtSourceTime(startTimeCMT)
            
            assetWriterInput.requestMediaDataWhenReadyOnQueue(self.transcodeQueue, usingBlock: { () -> Void in
                while assetWriterInput.readyForMoreMediaData {
                    if let nextBuffer = assetReaderOutput.copyNextSampleBuffer() {
                        if !assetWriterInput.appendSampleBuffer(nextBuffer) {
                            if assetWriter.status == .Failed {
                                completionHandler(ClipResult.Failure(assetWriter.error!.localizedDescription))
                                return
                            } else {
                                completionHandler(ClipResult.Failure("Error appendSampleBuffer \(String(reflecting:assetWriter.status))"))
                                return
                            }
                        }
                        // cfrelease is unavailable core foundation objects are automatically memory managed
                        // CFRelease(nextBuffer)
                    } else {
                        assetReader.cancelReading()
                        assetWriterInput.markAsFinished()
                        assetWriter.finishWritingWithCompletionHandler({ () -> Void in
                            guard assetWriter.status != .Failed else {
                                // docs say error object exists so forced unwrapped succeeds
                                completionHandler(ClipResult.Failure(assetWriter.error!.localizedDescription))
                                return
                            }
                            guard assetWriter.status == .Completed else {
                                completionHandler(ClipResult.Failure(String(reflecting:assetWriter.status)))
                                return
                            }
                            completionHandler(ClipResult.Success(outputURL))
                        })
                    }
                }
            })
            
        } catch let clipResult as ClipResult {
            completionHandler(clipResult)
        } catch let error as NSError {
            // let try... lands here
            completionHandler(ClipResult.Failure(error.localizedDescription))
        } catch {
            completionHandler(ClipResult.Failure("Encountered an unknown error \(error)"))
        }
    }
}