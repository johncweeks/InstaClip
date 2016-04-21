//
//  PlayerView.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/24/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer


class PlayerView: UITableViewCell {
    
    @IBOutlet weak var artWorkImageView: UIImageView!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var timeProgressView: UIProgressView!

    private var observers = false
    private var kvoProgress = "progress"
    private var kvoRate = "rate"
    
    var showMediaItem: MPMediaItem? {
        didSet {
            if showMediaItem == PlayerViewModel.sharedInstance.showMediaItem {
                reverseButton.enabled=true
                playPauseButton.enabled=true
                forwardButton.enabled=true
                addObservers()
            } else {
                removeObservers()
            }
        }
    }
    
    //weak var delegate: PlayerViewModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        timeProgressView.progressTintColor = UIColor.blackColor()
        frameView.layer.cornerRadius = 4
        frameView.layer.masksToBounds = true
        frameView.layer.borderWidth = 1
        frameView.layer.borderColor = UIColor.darkGrayColor().CGColor
    }
        
    deinit {
        removeObservers()
    }
    
    private func addObservers() {
        if !observers {
            PlayerViewModel.sharedInstance.addObserver(self, forKeyPath: kvoProgress, options: [.Initial, .New], context: &kvoProgress)
            PlayerViewModel.sharedInstance.addObserver(self, forKeyPath: kvoRate, options: [.Initial, .New], context: &kvoRate)
            observers = true
        }
    }
    
    private func removeObservers() {
        if observers {
            PlayerViewModel.sharedInstance.removeObserver(self, forKeyPath: kvoProgress)
            PlayerViewModel.sharedInstance.removeObserver(self, forKeyPath: kvoRate)
            observers = false
        }
    }
    
    @IBAction func playPauseButtonPress(sender: UIButton) {
        PlayerViewModel.sharedInstance.playPauseButtonPress()
    }
    
    @IBAction func reverseButtonPress(sender: UIButton) {
        PlayerViewModel.sharedInstance.skipBackwardButtonPress()
    }
    @IBAction func forwardButtonPress(sender: UIButton) {
        PlayerViewModel.sharedInstance.skipForwardButtonPress()
    }

    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        //print(self)
        if context == &kvoProgress {
            if let newValue = change?["new"] as? Float {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.timeProgressView.setProgress(newValue, animated: false)
                })
            }
        } else if context == &kvoRate {
            if let newValue = change?["new"] as? Float {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if newValue == 0.0 {
                        self.playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
                    } else {
                        self.playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
                    }
                })
            }
        }
    }

}
