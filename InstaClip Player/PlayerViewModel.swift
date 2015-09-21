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


extension Dictionary {
    func filterKeys(check: Key -> Bool) -> [Key: Value] {
        var result = [Key: Value]()
        for x in self  {
            if check(x.0) {
                print("keeping \(x.0)")
                result[x.0] = x.1
            } else {
                print("DELETING \(x.0)")
            }
        }
        return result
    }
}


// Model of the Views: PlayerView & iOS lock screen
// One should exist at all times so make it a singleton

class PlayerViewModel: NSObject {
    
    static let sharedInstance = PlayerViewModel()

    // observed by PlayerView
    dynamic var progress: Float = 0.0
    dynamic var rate: Float = 0.0
    
    var nowPlayingInfo = [String : AnyObject]()
    
    var showMediaItem: MPMediaItem? {
        didSet {
            if let showURL = showMediaItem?.showURLValue {
                if PlayerModel.sharedInstance.showURL != showURL {
                    PlayerModel.sharedInstance.showURL = showURL
                }
                if let show = showMediaItem {
                    nowPlayingInfo = [
                        MPMediaItemPropertyTitle : show.showTitleValue,
                        MPMediaItemPropertyAlbumTitle : show.podcastTitleValue,
                        MPMediaItemPropertyArtwork : show.mediaItemArtworkValue
                    ]
                }
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
    private let PodcastShowCurrentTime = "PodcastShowCurrentTime"

    private func setShowMediaItemDuringInit(newShowMediaItem: MPMediaItem) {
        // workaround to get showMediaItem didSet called from init()
        showMediaItem = newShowMediaItem
    }
    
    private override init() {   // prevent others from using the singleton's default initializer
        super.init()

        if let showURL = PlayerModel.sharedInstance.showURL, showMediaItem = PodcastMedia.sharedInstance.podcastQuery[showURL] {
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
        timeObserver = PlayerModel.sharedInstance.player?.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(Double(1.0), Int32(NSEC_PER_SEC)), queue: dispatch_get_main_queue()) { (time :CMTime) -> Void in
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
    
    // MARK: - bookmark show current time
    
    func saveShowCurrentTime() {
        guard showMediaItem != nil else {
            return
        }
        // var podcastsShowsCurrentTime : [String : [String : Double]] =
        var podcastsShowsCurrentTime = NSUserDefaults.standardUserDefaults().dictionaryForKey(PodcastShowCurrentTime) as? [String : [String : Double]] ?? [String : [String : Double]]()
        var showsCurrentTime : [String : Double] = podcastsShowsCurrentTime[showMediaItem!.podcastTitleValue] ?? [String : Double]()
        
        
        if let player = PlayerModel.sharedInstance.player {
            showsCurrentTime[showMediaItem!.showTitleValue] = CMTimeGetSeconds(player.currentTime())
            podcastsShowsCurrentTime[showMediaItem!.podcastTitleValue] = showsCurrentTime
            
            // filter non existant podcasts
            //var filteredPodcastsShowsCurrentTime = podcastsShowsCurrentTime.filterKeys({ PodcastMedia.sharedInstance.podcastForPodcastTitle($0) != nil ? true : false })
            var filteredPodcastsShowsCurrentTime = podcastsShowsCurrentTime.filterKeys({ PodcastMedia.sharedInstance.podcastQuery[$0] != nil ? true : false })

            // filter non existant shows in this podcast
            let podcast = PodcastMedia.sharedInstance.podcastQuery[showMediaItem!.podcastTitleValue] //PodcastMedia.sharedInstance.podcastForPodcastTitle(podcastTitle)
            //let filteredShowsCurrentTime = showsCurrentTime.filterKeys({ PodcastMedia.showMediaItemForPodcast(podcast, withShowTitle: $0) != nil ? true : false })
            let filteredShowsCurrentTime = showsCurrentTime.filterKeys({ podcast?[$0] != nil ? true : false })
            
            filteredPodcastsShowsCurrentTime[showMediaItem!.podcastTitleValue] = filteredShowsCurrentTime
        
            NSUserDefaults.standardUserDefaults().setObject(filteredPodcastsShowsCurrentTime, forKey: PodcastShowCurrentTime)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func restoreShowCurrentTime() {
        guard showMediaItem != nil && PlayerModel.sharedInstance.player != nil else {
            return
        }
        if let podcastsShowsCurrentTime = NSUserDefaults.standardUserDefaults().dictionaryForKey(PodcastShowCurrentTime) {
            if let showsCurrentTime = podcastsShowsCurrentTime[showMediaItem!.podcastTitleValue] as? [String : Double] {
                if let showCurrentTime = showsCurrentTime[showMediaItem!.showTitleValue] {
                    PlayerModel.sharedInstance.player?.seekToTime(CMTimeMakeWithSeconds(showCurrentTime, Int32(NSEC_PER_SEC)))
                }
            }
        }
    }
    
    func savePlayerCurrentTime() {
        if let player = PlayerModel.sharedInstance.player {
            let currentTime = Double(CMTimeGetSeconds(player.currentTime()))
            NSUserDefaults.standardUserDefaults().setDouble(currentTime, forKey: PlayerViewModelCurrentTimeKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func restorePlayerCurrentTime() {
        let currentTime = NSUserDefaults.standardUserDefaults().doubleForKey(PlayerViewModelCurrentTimeKey)
        PlayerModel.sharedInstance.player?.seekToTime(CMTimeMakeWithSeconds(currentTime, Int32(NSEC_PER_SEC)))
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
            player.seekToTime(CMTimeSubtract(player.currentTime(), CMTimeMakeWithSeconds(Double(30.0), player.currentTime().timescale)))
        }
    }
    
    func forwardButtonPress() {
        if let player = PlayerModel.sharedInstance.player {
            player.seekToTime(CMTimeAdd(player.currentTime(), CMTimeMakeWithSeconds(Double(30.0), player.currentTime().timescale)))
        }
    }
    
}