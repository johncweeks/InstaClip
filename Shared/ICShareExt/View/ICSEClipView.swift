//
//  ICSEClipView.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/7/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import UIKit

class ICSEClipView: UIView {
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.opaque = false
    self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
    
    //let leftHandle = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 128))
    let leftHandle = UIView()
    leftHandle.translatesAutoresizingMaskIntoConstraints = false
    leftHandle.backgroundColor = .purpleColor()
    self.addSubview(leftHandle)
    NSLayoutConstraint(item: leftHandle, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0).active = true
    NSLayoutConstraint(item: leftHandle, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0).active = true
    NSLayoutConstraint(item: leftHandle, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0).active = true
    NSLayoutConstraint(item: leftHandle, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 2).active = true
    
    let rightHandle = UIView()
    rightHandle.translatesAutoresizingMaskIntoConstraints = false
    rightHandle.backgroundColor = .purpleColor()
    self.addSubview(rightHandle)
    NSLayoutConstraint(item: rightHandle, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0).active = true
    NSLayoutConstraint(item: rightHandle, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0).active = true
    NSLayoutConstraint(item: rightHandle, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 2).active = true
    NSLayoutConstraint(item: rightHandle, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 2).active = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
