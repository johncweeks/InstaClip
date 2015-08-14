//
//  ViewController.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/14/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playPauseButton: UIButton!
    
    let player = AVPlayer(URL: NSBundle.mainBundle().URLForResource("developing_perspective_224", withExtension: "mp3")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MPMediaPickerController not woring for .Podcast so I will hard code an audio file for v0.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func shareButtonPress(sender: UIBarButtonItem) {
        if let podcastURL = NSBundle.mainBundle().URLForResource("developing_perspective_224", withExtension: "mp3") {
            if !(player.rate==0.0) {
                player.pause()
                playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
            }
            // Here is where we pass the file URL and starting time parameters for the clip
            let activityVC = UIActivityViewController(activityItems: [podcastURL, String(CMTimeGetSeconds(player.currentTime()))], applicationActivities: nil)
            presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func playPauseButtonPress(sender: UIButton) {
        if player.rate==0.0 {
            player.play()
            playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
        } else {
            player.pause()
            playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
        }
    }
}

