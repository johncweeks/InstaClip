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
    private let waveformContentView = WaveformContentView()
//    private lazy var waveformContentView: WaveformContentView = {
//        return WaveformContentView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
//    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
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
//        waveformContentView.frame.size.width == 0 so this code fails
//        if newBounds.origin.x > waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width {
//            newBounds.origin.x = waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width
//            //print("newBounds x \(newBounds.origin.x)")
//        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.bounds = newBounds
        })
        waveformContentView.configure(podcastURL)
    }
    
}
