//
//  PlayerModel.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/24/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

// need to play even when UI controls not visible (e.g. only Podcast Master View visible or app in background)
// so make it a singleton

class PlayerModel {
    
    static let sharedInstance = PlayerModel()
    private init() {}    // prevent others from using the default initializer
        
    var player: AVPlayer? {
        didSet {
            if AVAudioSession().category != AVAudioSessionCategoryPlayback {
                do {
                    try AVAudioSession().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession().setActive(true)
                } catch let error as NSError {
                    // try... lands here
                    showAlertWithTitle("Problem setting up AVAudioSession", message: error.localizedDescription)
                } catch {
                    showAlertWithTitle("Problem setting up AVAudioSession", message: "Encountered an unknown error \(error)")
                }
            }
        }
    }
    
    var showURL: NSURL? {
        didSet {
            guard showURL != nil else {
                return
            }
            if player == nil {
                player = AVPlayer(URL: showURL!)
            } else {
                player?.pause()
                player?.replaceCurrentItemWithPlayerItem(AVPlayerItem.init(URL: showURL!))
            }
        }
    }

}