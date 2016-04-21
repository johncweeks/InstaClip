//
//  SplitViewController.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/17/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//
import UIKit
import AVFoundation

class SplitViewController: UISplitViewController {

    // MARK: - state restoration
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        if let showURL = PlayerViewModel.sharedInstance.showMediaItem?.showURLValue {
            coder.encodeObject(showURL.absoluteString, forKey: "ShowURLString")
            PlayerViewModel.sharedInstance.savePlayerCurrentTime()
        }
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        if let showURLString = coder.decodeObjectForKey("ShowURLString") as? String, showURL = NSURL.init(string: showURLString)  {
            PlayerViewModel.sharedInstance.showMediaItem = PodcastMedia.sharedInstance.podcastQuery[showURL]
        }
        PlayerViewModel.sharedInstance.restorePlayerCurrentTime()
        super.decodeRestorableStateWithCoder(coder)
    }
}
