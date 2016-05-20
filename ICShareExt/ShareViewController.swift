//
//  ShareViewController.swift
//  ICShareExt
//
//  Created by John Weeks on 4/27/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        
        if let gradientLayer = self.view.layer as? CAGradientLayer {
            gradientLayer.colors = [UIColor(red: 11.0/255.0, green: 35.0/255.0, blue: 66.0/255.0, alpha: 1.0).CGColor,
                                    UIColor(red: 9.0/255.0, green: 11.0/255.0, blue: 20.0/255.0, alpha: 1.0).CGColor]
        }
    }
}
