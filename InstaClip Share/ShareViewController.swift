//
//  ShareViewController.swift
//  InstaClip Share
//
//  Created by John Weeks on 8/14/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import MobileCoreServices
import MessageUI
import AVFoundation

enum TranscodeError: ErrorType {
    case Fatal(String)
}

// We will have a custom UI so no need to subclass SLComposeServiceViewController
class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    var podcastURL: NSURL?
    var startTimeCMT: CMTime?
    var clipURL: NSURL?
    let clip = Clip()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard MFMessageComposeViewController.canSendAttachments() else {
            self.showAlertWithTitle("Can't create a clip", message: "This device can not send attachments in MMS or iMessage messages.")
            return
        }
        
        if let inputItems = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for extensionItem in inputItems     {
                if let attachments = extensionItem.attachments as? [NSItemProvider] {
                    for itemProvider in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) { //kUTTypeFileURL
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypeURL), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                                guard let podcastURL = data as? NSURL else {
                                    // if cast fails docs guarantee error object exists so implicit unwrapped optional succeeds
                                    self.showAlertWithTitle("Could not load \(String(kUTTypeURL))", message: error.localizedDescription)
                                    return
                                }
                                self.podcastURL = podcastURL
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.itemLoadComplete()
                                })
                            })
                        }
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) {
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                                guard let startTimeString = data as? String else {
                                    // if cast fails docs guarantee error object exists so implicit unwrapped optional succeeds
                                    self.showAlertWithTitle("Could not load \(String(kUTTypePlainText))", message: error.localizedDescription)
                                    return
                                }
                                guard let startTimeDouble = Double(startTimeString) else {
                                    self.showAlertWithTitle("Could not convert start time \"\(startTimeString)\" to double", message: nil)
                                    return
                                }
                                self.startTimeCMT = CMTimeMakeWithSeconds(startTimeDouble, Int32(NSEC_PER_SEC))
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.itemLoadComplete()
                                })
                            })
                        }
                    }
                }
            }
        }
    }
    
    private func itemLoadComplete() {
        
        guard let podcastURL=self.podcastURL, startTimeCMT=self.startTimeCMT else {
            // need both to make the clip
            return
        }
        clip.newFromURL(podcastURL, startTimeCMT: startTimeCMT, completionHandler: { (result) -> Void in
            switch result {
            case let .Success(clipURL):
                self.clipURL = clipURL
                let txtMessageVC = MFMessageComposeViewController()
                txtMessageVC.messageComposeDelegate = self
                txtMessageVC.recipients = ["1-609-647-3942"]
                if !txtMessageVC.addAttachmentURL(clipURL, withAlternateFilename: nil) {
                    self.showAlertWithTitle("Unable to attach clip to message", message: nil)
                    return
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.presentViewController(txtMessageVC, animated: true, completion: nil)
                })
            case let .Failure(msg):
                self.showAlertWithTitle("Can't create the clip", message: msg)
            }
        })
        let waveform = Waveform(podcastURL: podcastURL)
        waveform.readAndReduce(startTimeCMT)
    }
    
    private func showAlertWithTitle(title: String, message: String?) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "Okay", style: .Default) { (action) -> Void in
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
        }
        alertVC.addAction(defaultAction)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(alertVC, animated: true, completion: nil)
        })
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            do {
                // MFMessageComposeViewController is only created if clipURL exisits so forced unwrap succeeds
                try NSFileManager.defaultManager().removeItemAtURL(self.clipURL!)
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            } catch let error as NSError {
                self.showAlertWithTitle("Error deleting temporary clip file", message: error.localizedDescription)
            } catch {
                self.showAlertWithTitle("Encountered an unknown error", message: String(error))
            }
        }
    }
    
}