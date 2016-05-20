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
import QuartzCore

enum TranscodeError: ErrorType {
    case Fatal(String)
}

// We will have a custom UI so no need to subclass SLComposeServiceViewController
class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var waveformEditorView: WaveformEditorView!
    
    var podcastURL: NSURL?
    var currentTime: CMTime?
    var clipURL: NSURL?
    let clip = Clip()
    
    var waveform: Waveform?
    
    var lastPanLocation: CGPoint!
    
    // should have an index type !
    var index: Int = 2250
    var leftTrimIndex: Int = 2250 + (100 * 2)
    var rightTrimIndex: Int = 2250 + (100 * 2) + (100 * 4)
    var playHeadIndex: Int = 0
    
    var player: AVPlayer?
    
    
    
    override func viewDidLoad() {
        
        if let gradientLayer = self.view.layer as? CAGradientLayer {
            gradientLayer.colors = [UIColor(red: 11.0/255.0, green: 35.0/255.0, blue: 66.0/255.0, alpha: 1.0).CGColor,
                                    UIColor(red: 9.0/255.0, green: 11.0/255.0, blue: 20.0/255.0, alpha: 1.0).CGColor]
        }
        

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

//        guard MFMessageComposeViewController.canSendAttachments() else {
//            self.showAlertWithTitle("Can't create a clip", message: "This device can not send attachments in MMS, iMessage messages.")
//            return
//        }

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
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.podcastURL = podcastURL
                                    self.itemLoadComplete()
                                })
                            })
                        }
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) {
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                                guard let currentTimeString = data as? String else {
                                    // if cast fails docs guarantee error object exists so implicit unwrapped optional succeeds
                                    self.showAlertWithTitle("Could not load \(String(kUTTypePlainText))", message: error.localizedDescription)
                                    return
                                }
                                guard let currentTimeDouble = Double(currentTimeString) else {
                                    self.showAlertWithTitle("Could not convert start time \"\(currentTimeString)\" to double", message: nil)
                                    return
                                }
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.currentTime = CMTimeMakeWithSeconds(currentTimeDouble, Int32(NSEC_PER_SEC))
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
        guard let podcastURL = self.podcastURL, currentTime = self.currentTime else {
            // need both to make the clip
            return
        }
        
        waveformEditorView.configure(podcastURL, currentTime: currentTime)
        
//        self.waveform = Waveform(podcastURL: podcastURL, mtlDevice: mtlDevice, currentTime: currentTime)
        
//        self.waveform?.readAndConflate(startTimeCMT, completionHandler: { (waveform) -> Void in
//                self.waveformArray = waveform
//            })
        
        //return
        //return

        clip.newFromURL(podcastURL, startTime: currentTime, completionHandler: { (result) -> Void in
            switch result {
            case let .Success(clipURL):
                self.clipURL = clipURL
                let txtMessageVC = MFMessageComposeViewController()
                txtMessageVC.messageComposeDelegate = self
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
    
    @IBAction func playButtonPress(sender: UIButton) {
        guard let waveform = waveform else {
            return
        }
        let playerItem = AVPlayerItem(asset: waveform.urlAsset)
        player = AVPlayer(playerItem: playerItem)
        
        let startTime = waveform.indexToTime(Float(leftTrimIndex))
        let stopTime = waveform.indexToTime(Float(rightTrimIndex))
        print(CMTimeCopyDescription(kCFAllocatorDefault, currentTime!), CMTimeCopyDescription(kCFAllocatorDefault, startTime), CMTimeCopyDescription(kCFAllocatorDefault, stopTime))
        
        playerItem.seekToTime(startTime)
        playerItem.forwardPlaybackEndTime = stopTime
        //print(playerItem.status.rawValue, player?.status.rawValue, player?.muted, player?.volume)
        
        while (playerItem.status != .ReadyToPlay && player?.status != .ReadyToPlay) {
            NSThread.sleepForTimeInterval(1.0)
            print("z", terminator:"")
        }
        
        if AVAudioSession().category != AVAudioSessionCategoryPlayback {
            do {
                try AVAudioSession().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession().setActive(true)
            } catch let error as NSError {
                // try... lands here
                showAlertWithTitle("Problem setting up AVAudioSession", message: error.localizedDescription)
            } catch {
                showAlertWithTitle("Problem setting up AVAudioSession", message: "Encountered an unknown error \(error)")
            }
        }

        player?.play()
    }
    
    @IBAction func doneButtonPress(sender: UIButton) {
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }
}