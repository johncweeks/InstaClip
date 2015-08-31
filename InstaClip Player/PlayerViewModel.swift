//
//  PlayerViewModel.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/27/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import Foundation
import MediaPlayer

func calcProgress(divisor divisor: CMTime?, dividend: CMTime?) -> Float {
    guard divisor != nil && dividend != nil else {
        return 0.0
    }
    let numerator = Float(CMTimeGetSeconds(divisor!))
    let denomator = Float(CMTimeGetSeconds(dividend!))
    if numerator.isNaN || denomator.isNaN {
        return 0.0
    }
    return numerator / denomator
}

// Model of the Views: PlayerView & iOS lock screen
// One should exist at all times so make it a singleton

class PlayerViewModel: NSObject { //, PlayerModelDelegate
    
    static let sharedInstance = PlayerViewModel()

    // observed by PlayerView
    dynamic var progress: Float = 0.0
    dynamic var rate: Float = 0.0
    
    var nowPlayingInfo: [String : AnyObject] = [:]
    
    var showMediaItem: MPMediaItem? {
        didSet {
            if let showURL = PodcastMedia.showURLForShowMediaItem(showMediaItem) {
                if PlayerModel.sharedInstance.showURL != showURL {
                    PlayerModel.sharedInstance.showURL = showURL
                }
                nowPlayingInfo = [
                    MPMediaItemPropertyTitle : PodcastMedia.showTitleForShowMediaItem(showMediaItem),
                    MPMediaItemPropertyAlbumTitle : PodcastMedia.podcastTitleForShowMediaItem(showMediaItem),
                    MPMediaItemPropertyArtwork : PodcastMedia.artworkForShowMediaItem(showMediaItem)
                ]
                if let player = PlayerModel.sharedInstance.player, currentItem = player.currentItem {
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: CMTimeGetSeconds(player.currentTime()))
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(double: CMTimeGetSeconds(currentItem.duration))
                    progress = calcProgress(divisor: player.currentTime(), dividend: currentItem.duration)
                    rate = player.rate
                }
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
                addObservers()
            }
        }
    }
    
    private var timeObserver: AnyObject? = nil
    private var kvoRate = "rate"
    private let PlayerViewModelCurrentTimeKey = "PlayerViewModelCurrentTimeKey"

    private func setShowMediaItemDuringInit(newShowMediaItem: MPMediaItem) {
        // workaround to get showMediaItem didSet called from init()
        showMediaItem = newShowMediaItem
    }
    
    private override init() {   // prevent others from using the singleton's default initializer
        super.init()

        //PlayerModel.sharedInstance.delegate = self

        if let showURL = PlayerModel.sharedInstance.showURL, showMediaItem = PodcastMedia.sharedInstance.showMediaItemForShowURL(showURL) {
            setShowMediaItemDuringInit(showMediaItem)
        }
        
        // lock screen & headphone remote control
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (remoteCommandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPauseButtonPress()
            return .Success
        }
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (remoteCommandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPauseButtonPress()
            return .Success
        }
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (remoteCommandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.playPauseButtonPress()
            return .Success
        }
        MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (remoteCommandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.reverseButtonPress()
            return .Success
        }
        MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (remoteCommandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.forwardButtonPress()
            return .Success
        }
    }
    
    private func addObservers () {
        guard timeObserver == nil && PlayerModel.sharedInstance.player != nil else {
            return
        }
        PlayerModel.sharedInstance.player?.addObserver(self, forKeyPath: kvoRate, options: [.New], context: &kvoRate)
        timeObserver = PlayerModel.sharedInstance.player?.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(Float64(1.0), Int32(NSEC_PER_SEC)), queue: dispatch_get_main_queue()) { (time :CMTime) -> Void in
            if UIApplication.sharedApplication().applicationState == .Active {
                // update observable property for PlayerView
                self.progress = calcProgress(divisor: time, dividend: PlayerModel.sharedInstance.player?.currentItem?.duration)
            } else if UIApplication.sharedApplication().applicationState == .Background {
                // update iOS lock screen
                if let player = PlayerModel.sharedInstance.player, currentItem = player.currentItem {
                    self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: CMTimeGetSeconds(player.currentTime()))
                    self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(double: CMTimeGetSeconds(currentItem.duration))
                }
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.nowPlayingInfo
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoRate {
            if let newValue = change?["new"] as? Float {
                rate = newValue
            }
        }
    }
    
    func playerCurrentTime() -> String? {
        if let player = PlayerModel.sharedInstance.player {
            return String(CMTimeGetSeconds(player.currentTime()))
        }
        return nil
    }
    
    func savePlayerCurrentTime() {
        if let player = PlayerModel.sharedInstance.player {
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            NSUserDefaults.standardUserDefaults().setFloat(currentTime, forKey: PlayerViewModelCurrentTimeKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func restorePlayerCurrentTime() {
        let currentTimeFloat64 = Float64(NSUserDefaults.standardUserDefaults().floatForKey(PlayerViewModelCurrentTimeKey))
        PlayerModel.sharedInstance.player?.seekToTime(CMTimeMakeWithSeconds(currentTimeFloat64, Int32(NSEC_PER_SEC)))
    }
    
    func playPauseButtonPress() {
        if PlayerModel.sharedInstance.player?.rate==0.0 {
            PlayerModel.sharedInstance.player?.play()
        } else {
            PlayerModel.sharedInstance.player?.pause()
            savePlayerCurrentTime()
        }
    }
    
    func reverseButtonPress() {
        if let player = PlayerModel.sharedInstance.player {
            player.seekToTime(CMTimeSubtract(player.currentTime(), CMTimeMakeWithSeconds(Float64(30.0), player.currentTime().timescale)))
        }
    }
    
    func forwardButtonPress() {
        if let player = PlayerModel.sharedInstance.player {
            player.seekToTime(CMTimeAdd(player.currentTime(), CMTimeMakeWithSeconds(Float64(30.0), player.currentTime().timescale)))
        }
    }
    
}