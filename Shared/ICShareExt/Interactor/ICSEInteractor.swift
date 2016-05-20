//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation
import AVFoundation

enum ICSEInteractorResult {
  case AVPlayerManagerPlayerStatusFailed
  case AVPlayerManagerAudioSessionFailed
  
  case ExtensionDataManagerPodcastURLFailed
  case ExtensionDataManagerPodcastCurrentTimeFailed
  case ExtensionDataManagerIncompleteData
  
  case AssetDataManagerMissingAudioTrack
  case AssetDataManagerMissingAudioFormatDescription
  case AssetDataManagerAudioMustBeMonoOrStereo
  case AssetDataManagerCouldNotCreateWaveformData
}


class ICSEInteractor {
  
  weak var presenter: ICSEInteractorOutputProtocol!
  var extensionDataManager: ICSEExtensionDataManagerProtocolWithObserver! {
    didSet {
      self.extensionDataManager.icseExtensionItemDidChange = { [unowned self] extensionDataManager in
        guard let icseExtensionItem = self.extensionDataManager.icseExtensionItem else {
          assert(false)
          return
        }
        self.avAssetDataManager = ICSEAVAssetDataManager(interactor: self,  nsURL: icseExtensionItem.iPodLibraryAssetURL)
      }
    }
  }
  
  var avAssetDataManager: ICSEAVAssetDataManagerProtocolWithObserver! {
    didSet {
      self.avAssetDataManager.icseAVAssetItemDidChange = { [unowned self] avAssetDataManager in
        guard let icseAVAssetItem = self.avAssetDataManager.icseAVAssetItem, icseExtensionItem = self.extensionDataManager.icseExtensionItem else {
          assert(false)
          return
        }
        self.presenter.configureWaveform(withDuration: CMTimeGetSeconds(icseAVAssetItem.duration), hostAppCurrentTime: icseExtensionItem.hostAppCurrentTime)
        self.avPlayerManager = ICSEAVPlayerManager(interactor: self, asset: icseAVAssetItem.avAsset)
      }
    }
  }
  
  var avPlayerManager: ICSEAVPlayerManagerInputProtocol!
  
}

// MARK: - methods for communication AVPlayerManager -> INTERACTOR
extension ICSEInteractor: ICSEAVPlayerManagerOutputProtocol {
  
  func avPlayerManagerReady() {
    self.presenter.playerReadyToPlay()
  }
  
  func avPlayerRateDidChange(newRate rate: Float) {
    self.presenter.playerRateDidChange(newRate: rate)
  }
  
  func avPlayerTimeDidChange(newTime time: CMTime) {
    self.presenter.playerTimeDidChange(newTime: CMTimeGetSeconds(time))
  }
}

// MARK: - methods for communication PRESENTER -> INTERACTOR
extension ICSEInteractor: ICSEInteractorInputProtocol {
  
  func fetchWaveformMonoPoints(atTime seconds: Double) -> [CGPoint] {
    return self.avAssetDataManager.monoPointsLEI16(startingAt: Float64(seconds))
  }
  
  func requestPlayPauseAtTime(startTime: Double, duration: Double) {
    self.avPlayerManager.playPause(atTime: startTime, duration: duration)
  }

  func requestClipAtTime(startTime: Double, endTime: Double) {
    guard (self.avAssetDataManager != nil) else {
      self.presenter.replyClipFailedWithSummary("Can't access podcast", message: "Host app did not provide proper info")
      return
    }
    self.avAssetDataManager.newClipAtTime(startTime, endTime: endTime, completionHandler: { (result) -> Void in
      switch result {
      case let .Success(clipURL):
        self.presenter.replyClipWithURL(clipURL)
      case let .Failure(summary, message):
        self.presenter.replyClipFailedWithSummary(summary, message: message)
      }
    })
  }
  
  func requestPausePlayback() {
    guard avPlayerManager != nil else {
      return
    }
    avPlayerManager.pause()
  }
}

// MARK: - methods for communication DataManager(s) -> INTERACTOR
extension ICSEInteractor: ICSEDataManagerOutputProtocol {
  func dataManagerDidFailWithResult(result: ICSEInteractorResult, error: NSError?) {
    self.presenter.interactorDidFailWithResult(result, error: error)
  }
}
