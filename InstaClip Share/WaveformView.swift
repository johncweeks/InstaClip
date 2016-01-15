//
//  WaveformView.swift
//  InstaClip Player
//
//  Created by John Weeks on 10/30/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import QuartzCore

class WaveformView: UIView {

    override class func layerClass() -> AnyClass {
        return CAMetalLayer.self
    }
}
