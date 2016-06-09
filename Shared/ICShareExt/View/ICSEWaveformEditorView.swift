//
//  ICSEWaveformEditorView.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/2/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import UIKit

private enum PanType {
  case leftTrim, rightTrim, playhead, waveform
}

class ICSEWaveformEditorView: UIView {
  
  private let waveformContentView: ICSEWaveformContentView
  private let playheadView: ICSEPlayheadView
  private let clipView: ICSEClipView
  
  private var panStartBounds = CGRectZero
  private var panClipViewStartFrame = CGRectZero
  private var panPlayheadViewStartFrame = CGRectZero
  private var panningFor = PanType.waveform
  
  private var configuration: ICSEConfiguration!
  
  var enabeled: Bool
  
  required init?(coder aDecoder: NSCoder) {
    enabeled = false
    waveformContentView = ICSEWaveformContentView()
    playheadView = ICSEPlayheadView()
    clipView = ICSEClipView()
    configuration = ICSEDefaultConfiguration()

    super.init(coder: aDecoder)
    
    addSubview(waveformContentView)
    addSubview(clipView)
    addSubview(playheadView)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ICSEWaveformEditorView.handlePanGesture(_:)))
    addGestureRecognizer(panGestureRecognizer)
  }
  
  @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
    guard enabeled else {
      return  // disabled during playback
    }
    
    if panGesture.state == .Began {
      self.panStartBounds = self.bounds
      self.panClipViewStartFrame = self.clipView.frame
      self.panPlayheadViewStartFrame = self.playheadView.frame
      
      let x  = panGesture.locationInView(self).x
      
      let rightTrimX = CGRectGetMaxX(self.clipView.frame)
      let leftTrimX = CGRectGetMinX(self.clipView.frame)
      let playHeadX = CGRectGetMidX(self.playheadView.frame)
      
      if hitTestAtX(x, withTargetX: rightTrimX) {
        self.panningFor = .rightTrim
      } else if hitTestAtX(x, withTargetX: leftTrimX) {
        self.panningFor = .leftTrim
      } else if hitTestAtX(x, withTargetX: playHeadX) {
        self.panningFor = .playhead
      } else {
        self.panningFor = .waveform
      }
    } else if panGesture.state == .Changed {
      let translation = panGesture.translationInView(self)
      
      switch self.panningFor {
      case .waveform:
        var newBounds = panStartBounds
        newBounds.origin.x -= translation.x
        self.bounds = newBounds
      case .playhead:
        var playheadFrame = self.panPlayheadViewStartFrame
        playheadFrame.origin.x += translation.x
        self.playheadView.frame = playheadFrame
      case .rightTrim:
        var clipFrame = self.panClipViewStartFrame
        clipFrame.size.width += translation.x
        self.clipView.frame = clipFrame
      case .leftTrim:
        var clipFrame = self.panClipViewStartFrame
        clipFrame.size.width -= translation.x
        clipFrame.origin.x += translation.x
        self.clipView.frame = clipFrame
      }
    }
    else if panGesture.state == .Ended {
      // scroll bounce
      if self.bounds.origin.x < 0 {
        UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
          self.bounds.origin.x = 0
          }, completion: nil)
      } else if self.bounds.origin.x > waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width {
        UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
          self.bounds.origin.x = self.waveformContentView.frame.size.width - UIScreen.mainScreen().bounds.size.width
          }, completion: nil)
      }
    }
  }
}

extension ICSEWaveformEditorView: ICSEWaveformEditorViewProtocol {

  func configure(withDuration duration: Double, playStartTime: Double, presenter: ICSEPresenterProtocol, configuration: ICSEConfiguration = ICSEDefaultConfiguration()) {
    
    waveformContentView.configure(withDuration: duration, presenter: presenter)
    
    self.configuration = configuration
    
    let newBounds = calcEditorViewBounds(forPlayStartTime: playStartTime)
    
    let clipFrame = calcClipFrame(forPlayStartTime: playStartTime)
    
    let playheadFrame = CGRect(x: clipFrame.origin.x, y: 0, width: 2, height: self.frame.size.height)
    
    bounds = newBounds
    clipView.frame = clipFrame
    playheadView.frame = playheadFrame
  }
  
  private func getX(forTime time: Double) -> CGFloat {
    var x = CGFloat(time) * self.configuration.pointsPerSecond //ceil(CGFloat(time) * self.configuration.pointsPerSecond)
    if x < 0 {
      x = 0
    } else if x > waveformContentView.frame.size.width-UIScreen.mainScreen().bounds.size.width {
      x = waveformContentView.frame.size.width-UIScreen.mainScreen().bounds.size.width
    }
    return x
  }
  
  private func getTime(forX x: CGFloat) -> Double {
    return Double(x / self.configuration.pointsPerSecond)
  }
  
  private func calcEditorViewBounds(forPlayStartTime time: Double) -> CGRect {
    let x = getX(forTime: time - Double((self.frame.size.width/self.configuration.pointsPerSecond) / 2))
    return CGRect(x: x, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
  }
  
  private func calcClipFrame(forPlayStartTime time: Double) -> CGRect {
    let x = getX(forTime: time - (self.configuration.clipInitialDurationSeconds/2))
    return CGRect(x: x, y: 0, width: ceil(CGFloat(self.configuration.clipInitialDurationSeconds)*self.configuration.pointsPerSecond), height: self.frame.size.height)
  }
  
  private func hitTestAtX(x: CGFloat, withTargetX t: CGFloat) -> Bool {
    let tolerence: CGFloat = 20
    if x > t-tolerence && x < t+tolerence {
      return true
    } else {
      return false
    }
  }
  
  private func roundToPixel(point: CGFloat) -> CGFloat {
    let toNearest = 1/UIScreen.mainScreen().nativeScale
    return round(point/toNearest)*toNearest
  }
  
  func getClipStartEndTimes() -> (Double, Double) {
    return (getTime(forX: CGRectGetMinX(self.clipView.frame)), getTime(forX: CGRectGetMaxX(self.clipView.frame)))
  }
  
  func getClipPlayheadEndTimes() -> (Double, Double) {
    return (getTime(forX: CGRectGetMinX(self.playheadView.frame)), getTime(forX: CGRectGetMaxX(self.clipView.frame)))
  }
  
  func handlePlayerTimeChange(newTime time: Double) {
    // we are running on the main queue
    var newPlayheadFrame = self.playheadView.frame
    newPlayheadFrame.origin.x = roundToPixel(CGFloat(time)*self.configuration.pointsPerSecond)
    
    var newBounds = self.bounds
    if CGRectGetMaxX(self.clipView.frame) < self.bounds.origin.x  {                 // if clip offscreen then center playhead on screen
      newBounds.origin.x = roundToPixel(newPlayheadFrame.origin.x-(self.bounds.size.width/2))
    } else if (CGRectGetMinX(self.clipView.frame) > self.bounds.origin.x+self.bounds.size.width) {
      newBounds.origin.x = roundToPixel(newPlayheadFrame.origin.x+(self.bounds.size.width/2))
    }
    if newPlayheadFrame.origin.x > (self.bounds.origin.x+self.bounds.size.width)-30 && newPlayheadFrame.origin.x < self.waveformContentView.frame.size.width-30 { // scroll waveform to keep playhead onscreen
      newBounds.origin.x = roundToPixel(newBounds.origin.x+(newPlayheadFrame.origin.x-self.playheadView.frame.origin.x))
    }
    self.playheadView.frame = newPlayheadFrame
    if self.bounds.origin.x != newBounds.origin.x {
      self.bounds = newBounds
    }
  }
  
  func movePlayheadToBeginOfClip() {
    var playheadFrame = self.playheadView.frame
    playheadFrame.origin.x = self.clipView.frame.origin.x
    UIView.animateWithDuration(0.25, animations: {
      self.playheadView.frame = playheadFrame
    })
  }
  
  func movePlayheadToEndOfClip() {
    var playheadFrame = self.playheadView.frame
    playheadFrame.origin.x = self.clipView.frame.origin.x+self.clipView.frame.size.width//-self.playheadView.frame.size.width
    UIView.animateWithDuration(0.25, animations: {
      self.playheadView.frame = playheadFrame
    })
  }
  
  func shiftClipForward() {
    let shiftPoints = (CGFloat(self.configuration.timeShiftSeconds)*self.configuration.pointsPerSecond)
    var shiftedClipViewFrame = self.clipView.frame
    shiftedClipViewFrame.origin.x += shiftPoints
    if shiftedClipViewFrame.origin.x+shiftedClipViewFrame.size.width > waveformContentView.frame.size.width {
      shiftedClipViewFrame.origin.x = waveformContentView.frame.size.width-shiftedClipViewFrame.size.width
    }
    
    var playheadFrame = self.playheadView.frame
    playheadFrame.origin.x += (shiftedClipViewFrame.origin.x-self.clipView.frame.origin.x)
    
    var newBounds = self.bounds
    newBounds.origin.x += shiftPoints
    if newBounds.origin.x < playheadFrame.origin.x || newBounds.origin.x > shiftedClipViewFrame.origin.x+shiftedClipViewFrame.size.width {
      newBounds.origin.x = playheadFrame.origin.x-(newBounds.size.width/2)
    }
    if newBounds.origin.x >  waveformContentView.frame.size.width-self.frame.size.width {
      newBounds.origin.x =  waveformContentView.frame.size.width-self.frame.size.width
    }
    
    UIView.animateWithDuration(0.25, animations: {
      self.clipView.frame = shiftedClipViewFrame
      self.playheadView.frame = playheadFrame
      self.bounds = newBounds
    })
  }
  
  func shiftClipBackward() {
    let shiftPoints = (CGFloat(self.configuration.timeShiftSeconds)*self.configuration.pointsPerSecond)
    var shiftedClipViewFrame = self.clipView.frame
    shiftedClipViewFrame.origin.x -= shiftPoints
    if shiftedClipViewFrame.origin.x < 0 {
      shiftedClipViewFrame.origin.x = 0
    }
    
    var playheadFrame = self.playheadView.frame
    playheadFrame.origin.x -= (self.clipView.frame.origin.x-shiftedClipViewFrame.origin.x)
    
    var newBounds = self.bounds
    newBounds.origin.x -= shiftPoints
    if newBounds.origin.x < playheadFrame.origin.x || newBounds.origin.x > shiftedClipViewFrame.origin.x+shiftedClipViewFrame.size.width {
      newBounds.origin.x = playheadFrame.origin.x-(newBounds.size.width/2)
    }
    if newBounds.origin.x < 0 {
      newBounds.origin.x = 0
    }
    
    UIView.animateWithDuration(0.25, animations: {
      self.clipView.frame = shiftedClipViewFrame
      self.playheadView.frame = playheadFrame
      self.bounds = newBounds
    })
  }
}