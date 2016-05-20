//
//  ICSEAVAssetItem.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/2/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import AVFoundation

struct ICSEAVAssetItem {
  let avAsset: AVURLAsset
  let audioAssetTrack: AVAssetTrack
  let duration: CMTime
}