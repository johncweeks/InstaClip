//
//  ICSEDefaultConfiguration.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/2/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import UIKit

struct ICSEDefaultConfiguration: ICSEConfiguration {
    let clipInitialDurationSeconds: Double = 20
    let timeShiftSeconds: Double = 15
    let pointsPerSecond: CGFloat = 10
    let waveformSampleSeconds: CGFloat = 20
}
