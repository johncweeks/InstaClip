//
//  WaveformContentView.swift
//  InstaClip Player
//
//  Created by John Weeks on 4/7/16.
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


protocol WaveformContentViewObserverProtocol {
    var width: CGFloat! { get }
    var widthDidChange: ((WaveformContentViewObserverProtocol) -> ())? { get set }
}

class WaveformContentView: UIView, WaveformContentViewObserverProtocol {
    
    
    var width: CGFloat! {
        didSet {
            self.widthDidChange?(self)
        }
    }
    var widthDidChange: ((WaveformContentViewObserverProtocol) -> ())?

    
    private var waveformViewModel: WaveformViewModelProtocol! {
        didSet {
            self.waveformViewModel.durationDidChange = { [unowned self] waveformViewModel in
                let layer = self.layer as! CATiledLayer
                let scale = UIScreen.mainScreen().scale
                layer.contentsScale = scale
                // tile size should be multiple of
                layer.tileSize = CGSize(width: kWaveformSampleSeconds * kPointsPerSecond * scale,
                                        height: self.superview!.bounds.size.height * scale) // same height as superview
                // entire podcast is scrollable, countable infinity
                self.width = ceil(CGFloat(CMTimeGetSeconds(self.waveformViewModel.duration)) * kPointsPerSecond)
                //print("WaveformContentView width \(width)")
                let height = self.superview!.frame.size.height
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.frame = CGRect(x: 0, y: 0, width: self.width, height: height)
                    // trigger calls to drawLayer for visible tiles
                    self.setNeedsDisplay()
                })
            }
        }
    }
    
    override class func layerClass() -> AnyClass {
        return TiledLayer.self
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    private func initialize() {
        self.backgroundColor = UIColor.clearColor()
    }
    
    
    override func drawRect(rect: CGRect) {
        print("drawRect \(rect)")
    }
    
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        
        UIGraphicsPushContext(ctx)
        
        let rect = CGContextGetClipBoundingBox(ctx)
        print(rect)
        let fill = UIColor.whiteColor()// UIColor(red: r, green: g, blue: b, alpha: 1.0)
        fill.setFill()
        fill.setStroke()
        let startSecs = Double(rect.origin.x / kPointsPerSecond)
        // xlate x to startTime
        
        // faster but less accurate for stereo: draw one channel and then flip it to approximate the other channel
        // via http://supermegaultragroovy.com/2009/10/06/drawing-waveforms/
        let monoPoints = self.waveformViewModel.monoPointsLEI16(startingAt: startSecs)
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
        path.stroke()
        
        UIGraphicsPopContext()
        //print("drawLayer \(rect) duration: \(NSDate().timeIntervalSinceDate(start)))")
        return
    }
    
    func configure(podcastURL: NSURL) {
        waveformViewModel = WaveformViewModel(podcastURL)
    }
}


