//
//  TMButton.swift
//  InstaClip Player
//
//  Created by John Weeks on 11/22/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit

class TMButton: UIButton {

    override func awakeFromNib() {
        self.layer.borderWidth = 1.0
        self.layer.borderColor = self.titleColorForState(.Normal)?.CGColor
    }

}
