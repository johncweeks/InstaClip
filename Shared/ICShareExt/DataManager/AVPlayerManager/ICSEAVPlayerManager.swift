//
//  ICSEAVPlayerManager.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/5/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import AVFoundation

enum ICSEAVPlayerManagerResult {
  case PlayerStatusFailed
  case AudioSessionFailed
}

final class ICSEAVPlayerManager: NSObject {
  
  private let interactor: protocol<ICSEAVPlayerManagerOutputProtocol, ICSEDataManagerOutputProtocol>
  
  private let player: AVPlayer
  private let playerItem: AVPlayerItem
  private var timeObserver: AnyObject!
  private var kvoStatus = "status"
  private var kvoRate = "rate"
  
  init(interactor: protocol<ICSEAVPlayerManagerOutputProtocol, ICSEDataManagerOutputProtocol>, asset: AVAsset) {
    
    self.interactor = interactor
    playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration"]) // loading duration to use it's timescale in playPause()
    player = AVPlayer(playerItem: self.playerItem)
    
    super.init()
    
    player.addObserver(self, forKeyPath: kvoStatus, options: [.New], context: &kvoStatus)
    player.addObserver(self, forKeyPath: kvoRate, options: [.New], context: &kvoRate)
  }
  
  deinit {
    player.removeObserver(self, forKeyPath: kvoStatus)
    player.removeObserver(self, forKeyPath: kvoRate)
    if timeObserver == nil {
      player.removeTimeObserver(timeObserver)
    }
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if context == &kvoStatus {
      switch self.player.status {
      case .ReadyToPlay:
        self.interactor.avPlayerManagerReady()
      case .Failed:
        self.interactor.dataManagerDidFailWithResult(.AVPlayerManagerPlayerStatusFailed, error: self.player.error)
      case .Unknown:
        assert(false)
        break
      }
    } else if context == &kvoRate {
      self.interactor.avPlayerRateDidChange(newRate: self.player.rate)
    }
  }
}

extension ICSEAVPlayerManager: ICSEAVPlayerManagerInputProtocol {
  
  func playPause(atTime seconds: Double, duration: Double) {
    
    if self.player.rate == 0.0 {
      let itemDuration = self.playerItem.duration
      let startTime = CMTimeMakeWithSeconds(seconds, itemDuration.timescale)
      let endTime = CMTimeMakeWithSeconds(seconds+duration, itemDuration.timescale)
      playerItem.seekToTime(startTime)
      playerItem.forwardPlaybackEndTime = endTime
      
      // wait until first play to setup audio session and time observer
      if AVAudioSession().category != AVAudioSessionCategoryPlayback {
        do {
          try AVAudioSession().setCategory(AVAudioSessionCategoryPlayback)
          try AVAudioSession().setActive(true)
        } catch let error as NSError {
          self.interactor.dataManagerDidFailWithResult(.AVPlayerManagerAudioSessionFailed, error: error)
        }
      }
      if timeObserver == nil {
        let interval = CMTimeMakeWithSeconds(1/60, 60)  // that's 60 fps
        timeObserver = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue(), usingBlock:  { (nowTime) in
          self.interactor.avPlayerTimeDidChange(newTime: nowTime)
        })
      }

      player.play()
    } else {
      player.pause()
    }
  }
  
  func pause() {
    player.pause()
  }
}