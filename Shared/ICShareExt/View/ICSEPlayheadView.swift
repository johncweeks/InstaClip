//
//  ICSEPlayheadView.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/6/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import UIKit

class ICSEPlayheadView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.redColor()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
