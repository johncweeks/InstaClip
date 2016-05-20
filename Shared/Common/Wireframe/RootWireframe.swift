//
//  RootWireframe.swift
//  InstaClip Player
//
//  Created by John Weeks on 4/28/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import UIKit

@objc(RootWireframe)

class RootWireframe: UINavigationController {
    
    let icShareExtWireframe: ICSEWireframeProtocol = ICSEWireframe()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    func commonInit() {
        icShareExtWireframe.rootWireframe = self
        pushViewController(icShareExtWireframe.view as! UIViewController, animated: true)
    }
    
    override func beginRequestWithExtensionContext(context: NSExtensionContext) {
        super.beginRequestWithExtensionContext(context)
        icShareExtWireframe.configureICSEModule(withExtensionContext: context)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height)
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.transform = CGAffineTransformIdentity
        })
    }
}

extension RootWireframe: RootWireframeProtocol {
  
  func exitICSEModule() {
    self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
  }
}