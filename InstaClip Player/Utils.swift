//
//  Utils.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/28/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit

func showAlertWithTitle(title: String, message: String?) {
    let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let defaultAction = UIAlertAction(title: "Okay", style: .Default) { (action) -> Void in
    }
    alertVC.addAction(defaultAction)
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertVC, animated: true, completion: nil)
    })
}

func isNil(o: AnyObject?) -> Bool {
    return o == nil ? true : false
}


