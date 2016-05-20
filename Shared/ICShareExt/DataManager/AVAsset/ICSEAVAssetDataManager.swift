//
//  ICSEAVAssetDataManager.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/1/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit


enum ICSEAVAssetDataManagerClipResult: ErrorType {
  case Success(NSURL)
  case Failure(summary: String, description: String?)
}

final class ICSEAVAssetDataManager: ICSEAVAssetDataManagerProtocolWithObserver {
  
  var icseAVAssetItemDidChange: ((ICSEAVAssetDataManagerObserverProtocol) -> ())?
  var icseAVAssetItem: ICSEAVAssetItem? {
    didSet {
      self.icseAVAssetItemDidChange?(self)
    }
  }
  
  private var outputSettings: [String: AnyObject] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVLinearPCMIsBigEndianKey: false,
    AVLinearPCMIsFloatKey: true,
    AVLinearPCMBitDepthKey:  sizeof(Float32) * 8 ]
  private var channelCount: Int!
  private var reduceBy: Int!
  private var sampleRate: CGFloat!
  private let icShareExtConfiguration: ICSEConfiguration
  private let serialQueue: dispatch_queue_t
  private let interactor: ICSEDataManagerOutputProtocol
  
  init(interactor: ICSEDataManagerOutputProtocol, nsURL: NSURL, icseConfiguration configuration: ICSEConfiguration = ICSEDefaultConfiguration()) {
    self.interactor = interactor
    self.icShareExtConfiguration = configuration
    self.serialQueue = dispatch_queue_create("net.MoonriseSoftware.ICSEAVAssetDataManager.newClip", DISPATCH_QUEUE_SERIAL)
    let urlAsset = AVURLAsset(URL: nsURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    urlAsset.loadValuesAsynchronouslyForKeys(["tracks"]) { () -> Void in
      
      guard let audioAssetTrack = urlAsset.tracksWithMediaType(AVMediaTypeAudio).first else {
        self.interactor.dataManagerDidFailWithResult(.AssetDataManagerMissingAudioTrack, error: nil)
        return
      }
      
      guard let formatDescription = audioAssetTrack.formatDescriptions.first else {
        self.interactor.dataManagerDidFailWithResult(.AssetDataManagerMissingAudioFormatDescription, error: nil)
        return
      }
      
      let audioFormatDescription = formatDescription as! CMAudioFormatDescription
      let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)
      
      guard asbd.memory.mChannelsPerFrame == 1 || asbd.memory.mChannelsPerFrame == 2 else {
        self.interactor.dataManagerDidFailWithResult(.AssetDataManagerAudioMustBeMonoOrStereo, error: nil)
        return
      }
      self.channelCount = Int(asbd.memory.mChannelsPerFrame)
      
      self.sampleRate = CGFloat(asbd.memory.mSampleRate)
      self.reduceBy = Int(ceil(self.sampleRate / (self.icShareExtConfiguration.pointsPerSecond * UIScreen.mainScreen().scale))) - 1 // need n + 1 points to draw from 0 to n
      
      self.icseAVAssetItem = ICSEAVAssetItem(avAsset: urlAsset, audioAssetTrack: audioAssetTrack, duration: audioAssetTrack.timeRange.duration)
      
      return
    }
  }
  
  func monoPointsLEI16(startingAt startTime: Float64) -> [CGPoint] {
    
    guard let icseAVAssetItem = self.icseAVAssetItem else {
      assert(false)
      return [CGPoint]()
    }
    
    // TODO: unit tests for mono and stereo file
    var monoPoints = [CGPoint]()
    monoPoints.reserveCapacity(Int(ceil(icShareExtConfiguration.waveformSampleSeconds * self.icShareExtConfiguration.pointsPerSecond * UIScreen.mainScreen().scale + 1)))
    
    guard startTime < CMTimeGetSeconds(icseAVAssetItem.duration) else {
      return monoPoints
    }
    let stopTime: Float64 = startTime + Float64(icShareExtConfiguration.waveformSampleSeconds) > CMTimeGetSeconds(icseAVAssetItem.duration) ? CMTimeGetSeconds(icseAVAssetItem.duration) : startTime + Float64(icShareExtConfiguration.waveformSampleSeconds)
    let startTimeCMT = CMTimeMakeWithSeconds(startTime, icseAVAssetItem.duration.timescale)
    let stopTimeCMT = CMTimeMakeWithSeconds(stopTime, icseAVAssetItem.duration.timescale)
    let outputSettingsLEI16: [String: AnyObject] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMBitDepthKey:  sizeof(Int16) * 8 ]
    
    do {
      let assetReader = try AVAssetReader(asset: icseAVAssetItem.avAsset)
      
      let assetReaderTrackOutput = AVAssetReaderTrackOutput.init(track: icseAVAssetItem.audioAssetTrack, outputSettings: outputSettingsLEI16)
      
      assetReader.timeRange = CMTimeRangeFromTimeToTime(startTimeCMT, stopTimeCMT)
      assetReader.addOutput(assetReaderTrackOutput)
      assetReader.startReading()
      
      var tempBuffer = ContiguousArray<Int16>()
      var x: CGFloat = 0.0
      var maxY: Int16 = Int16.min
      var samplesProcessed = 0
      
      while (assetReader.status == .Reading) {
        if let sampleBuffer = assetReaderTrackOutput.copyNextSampleBuffer(),
          blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
          
          var returnedPtr: UnsafeMutablePointer<Int8> = nil
          let lengthInBytes = CMBlockBufferGetDataLength(blockBuffer)
          if tempBuffer.capacity < lengthInBytes/sizeof(Int16) {
            tempBuffer.reserveCapacity(lengthInBytes/sizeof(Int16))
          }
          let osStatus = CMBlockBufferAccessDataBytes(blockBuffer, 0, lengthInBytes, &tempBuffer, &returnedPtr)
          if osStatus == kCMBlockBufferNoErr {
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
                  if point.y < 0 || point.y > 1 {
                    assert(false, "y must be 0...1 \(point) \(maxY)")
                  }
                  monoPoints.append(point)
                  x += 1.0 / UIScreen.mainScreen().scale
                  maxY = Int16.min
                }
              }
            } else {
              assert(false, "failed to returnedPtr")
            }
          } else {
            assert(false, "failed to access buffer \(osStatus)")
          }
        }
      }
      assert(assetReader.status == .Completed)
      
      if samplesProcessed % self.reduceBy != 0 || samplesProcessed < self.reduceBy {
        let point = CGPoint(x: x, y: CGFloat(maxY)/CGFloat(Int16.max))
        monoPoints.append(point)
      }
      // TODO: move these checks to unit test
      //            if Int(ceil(icShareExtConfiguration.waveformSampleSeconds * self.icShareExtConfiguration.pointsPerSecond * UIScreen.mainScreen().scale + 1)) != monoPoints.count {
      //                //assert(false, "need n + 1 points to draw from 0 to n\n\(Int(ceil(kWaveformSampleSeconds * kPointsPerSecond * UIScreen.mainScreen().scale + 1))) != \(monoPoints.count)")
      //            }
      //            if samplesProcessed != Int((stopTime - startTime) * Float64(self.sampleRate)) {
      //                //print("monoPoints incorrect sample count. was \(samplesProcessed) should be \((stopTime - startTime) * Float64(self.sampleRate))")
      //            }
    } catch let error as NSError {
      self.interactor.dataManagerDidFailWithResult(.AssetDataManagerCouldNotCreateWaveformData, error: error)
    }
    
    return monoPoints
  }
  
  func newClipAtTime(startTime: Float64, endTime: Float64, completionHandler completion: (ICSEAVAssetDataManagerClipResult) -> Void) {
    guard let icShareExtAVAssetItem = self.icseAVAssetItem where
      endTime > startTime &&
        startTime >= 0 &&
        endTime <= CMTimeGetSeconds(icShareExtAVAssetItem.duration) else {
          assert(false)
          return
    }
    // TODO: add fade in https://developer.apple.com/library/ios/qa/qa1730/_index.html
    
    if let exportSession = AVAssetExportSession(asset: icShareExtAVAssetItem.avAsset, presetName: AVAssetExportPresetAppleM4A) {
      let outputFile = NSTemporaryDirectory() + "InstaClip.m4a"
      let outputURL = NSURL.fileURLWithPath(outputFile)
      
      if NSFileManager.defaultManager().fileExistsAtPath(outputFile) {
        // delete previous clip file so exportSession can create a new one
        do {
          try NSFileManager.defaultManager().removeItemAtURL(outputURL)
        } catch let error as NSError {
          completion(ICSEAVAssetDataManagerClipResult.Failure(summary: "Can't delete previous clip", description: error.localizedDescription))
          return
        }
      }
      exportSession.outputURL = outputURL
      exportSession.shouldOptimizeForNetworkUse = true
      exportSession.outputFileType = AVFileTypeAppleM4A
      
      let startCMT = CMTimeMakeWithSeconds(startTime, icShareExtAVAssetItem.duration.timescale)
      let stopCMT = CMTimeMakeWithSeconds(endTime, icShareExtAVAssetItem.duration.timescale)
      let clipTimeRange = CMTimeRangeFromTimeToTime(startCMT, stopCMT)
      exportSession.timeRange = clipTimeRange
      
      exportSession.exportAsynchronouslyWithCompletionHandler({
        //NSThread.sleepForTimeInterval(3)
        switch exportSession.status {
        case .Completed:
          completion(ICSEAVAssetDataManagerClipResult.Success(outputURL))
        case .Failed, .Cancelled, .Unknown, .Waiting, .Exporting:
          if exportSession.error != nil {
            completion(ICSEAVAssetDataManagerClipResult.Failure(summary: "Can't create clip", description: exportSession.error!.description))
          } else {
            completion(ICSEAVAssetDataManagerClipResult.Failure(summary: "Can't create clip", description: "AVAssetExportSession status \(exportSession.status.rawValue)"))
          }
        }
      })
    } else {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        completion(ICSEAVAssetDataManagerClipResult.Failure(summary: "Can't create AVAssetExportSession", description: nil))
      })
    }
    
    return
  }
}
