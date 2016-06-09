//
//  ICShareWaveformContentView.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/2/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

class TiledLayer: CATiledLayer {
  override class func fadeDuration() -> CFTimeInterval {
    return 0.1
  }
}


class ICSEWaveformContentView: UIView {
  
  var presenter: ICSEPresenterProtocol!
  private var icShareExtConfiguration: ICSEConfiguration = ICSEDefaultConfiguration()
  
  override class func layerClass() -> AnyClass {
    return TiledLayer.self
  }
  
  override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
    //print(CGContextGetClipBoundingBox(ctx))
    
    UIGraphicsPushContext(ctx)
    
    let rect = CGContextGetClipBoundingBox(ctx)
        
    self.superview?.backgroundColor?.setFill()
    UIRectFill(rect)
    
    let fill = UIColor.blackColor()
    fill.setFill()
    //fill.setStroke()
    let startSecs = Double(rect.origin.x / self.icShareExtConfiguration.pointsPerSecond)
    // xlate x to startTime
    
    // faster but less accurate for stereo: draw one channel and then flip it to approximate the other channel
    // via http://supermegaultragroovy.com/2009/10/06/drawing-waveforms/
    
    let monoPoints = self.presenter.didRequestWaveformMonoPoints(atTime: startSecs)
    //let start = NSDate()
    let monoPath = UIBezierPath()
    
    monoPath.moveToPoint(CGPoint(x: 0, y: 0))
    //print("drawLayer x \(rect) \(monoPoints.count) \(monoPoints.first!) \(monoPoints.last!)")
    for point in monoPoints {
      monoPath.addLineToPoint(point)
    }
    monoPath.addLineToPoint(CGPoint(x: monoPoints.last!.x, y: 0))
    //print(rect, monoPath)
    let path = UIBezierPath(CGPath: monoPath.CGPath)
    path.lineWidth = 0.5 // thinest for device
    let scaleY = self.bounds.height / 2.0
    let transform = CGAffineTransformMake(1, 0, 0, -scaleY, rect.origin.x, scaleY)
    path.applyTransform(transform)
    
    let flipped = CGAffineTransformMake(1, 0, 0, scaleY, rect.origin.x, scaleY)
    monoPath.applyTransform(flipped)
    path.appendPath(monoPath)
    
    path.fill()
    //path.stroke()
    
    UIGraphicsPopContext()
    //print("drawLayer \(rect) duration: \(NSDate().timeIntervalSinceDate(start)))")
    return
  }
  

  
}

extension ICSEWaveformContentView: ICSEWaveformContentViewProtocol {
  
  func configure(withDuration duration: Double, presenter: ICSEPresenterProtocol, configuration: ICSEConfiguration = ICSEDefaultConfiguration()) {
    
    self.presenter = presenter
    
    let layer = self.layer as! CATiledLayer
    let scale = UIScreen.mainScreen().scale
    layer.contentsScale = scale
    
    layer.tileSize = CGSize(width: configuration.waveformSampleSeconds*configuration.pointsPerSecond*scale,
                            height: self.superview!.bounds.size.height*scale)
    
    let width = ceil(CGFloat(duration))*configuration.pointsPerSecond
    let height = self.superview!.bounds.size.height
    self.frame = CGRect(x: 0, y: 0, width: width, height: height)
    //dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.setNeedsDisplay()
    //})
  }
}