//
//  WaveformEditorView.swift
//  InstaClip Player
//
//  Created by John Weeks on 10/30/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import AVFoundation
//import QuartzCore

let kWaveformSampleSeconds: CGFloat = 20 //37.5 //10
let kPointsPerSecond: CGFloat = 10


class WaveformEditorView: UIView {
    
    private var currentTime: CMTime!
    private var panStartBounds = CGRectZero
    private var waveformContentView: WaveformContentView! {
        didSet {
            self.waveformContentView.widthDidChange = { [unowned self] waveformContentView in
                var newBounds = self.bounds
                newBounds.origin.x = ceil(CGFloat(CMTimeGetSeconds(self.currentTime)) * kPointsPerSecond)
                
                if newBounds.origin.x > waveformContentView.width - UIScreen.mainScreen().bounds.size.width {
                    newBounds.origin.x = waveformContentView.width - UIScreen.mainScreen().bounds.size.width
                    //print("newBounds x \(newBounds.origin.x)")
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.bounds = newBounds
                })
            }
        }
    }

    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        // wrap in closure so didSet gets called in init() 
        ({self.waveformContentView = WaveformContentView()})()
        self.addSubview(self.waveformContentView)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WaveformEditorView.handlePanGesture(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .Began {
            panStartBounds = self.bounds
        } else if panGesture.state == .Changed {
            let translation = panGesture.translationInView(self)
            var newBounds = panStartBounds
            newBounds.origin.x -= translation.x
            if newBounds.origin.x < 0 {
                newBounds.origin.x = 0 
            }
            if newBounds.origin.x > waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width {
                newBounds.origin.x = waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width
                //print("newBounds x \(newBounds.origin.x)")
            }
            self.bounds = newBounds
        }
    }
    
    
    func configure(podcastURL: NSURL, currentTime: CMTime) {
        self.currentTime = currentTime
        var newBounds = self.bounds
        newBounds.origin.x = ceil(CGFloat(CMTimeGetSeconds(currentTime)) * kPointsPerSecond)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.bounds = newBounds
        })

        waveformContentView.configure(podcastURL)
    }
    

}
