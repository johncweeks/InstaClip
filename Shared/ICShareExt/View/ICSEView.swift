//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation
import UIKit
import MessageUI


enum ICSEViewShareResult {
  case ShareMessageResultAddAttachmentFailed
}

class ICSEView: UIViewController {
  @IBOutlet weak var controlView: UIView!
  @IBOutlet weak var waveformEditorView: ICSEWaveformEditorView!
  @IBOutlet weak var playPauseButton: UIButton!
  @IBOutlet weak var beginButton: UIButton!
  @IBOutlet weak var endButton: UIButton!
  @IBOutlet weak var shiftForwardButton: UIButton!
  @IBOutlet weak var shiftBackwardButton: UIButton!
  
  
  var presenter: ICSEPresenterProtocol!
  
  private var spinnerView: UIView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    controlView.layer.cornerRadius = 4
    controlView.layer.masksToBounds = true
    controlView.layer.borderWidth = 1
    controlView.layer.borderColor = UIColor.darkGrayColor().CGColor
    
    navigationItem.title = "InstaClip Editor"
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancelButtonPress))
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: #selector(composeButtonPress))
  }
  
  // MARK: methods for communication VIEW -> PRESENTER
  
  func composeButtonPress(sender: UIBarButtonItem) {
    let (start, end) = waveformEditorView.getClipStartEndTimes()
    presenter.didRequestClipAtTime(start, endTime: end)
  }
  
  func cancelButtonPress(sender: UIBarButtonItem) {
    presenter.didRequestCancel()
  }
  
  @IBAction func shiftBackwardButtonPress(sender: UIButton) {
    waveformEditorView.shiftClipBackward()
  }
  
  @IBAction func shiftForwardButtonPress(sender: UIButton) {
    waveformEditorView.shiftClipForward()
  }
  
  @IBAction func beginButtonPress(sender: UIButton) {
    waveformEditorView.movePlayheadToBeginOfClip()
  }
  
  @IBAction func endButtonPress(sender: UIButton) {
    waveformEditorView.movePlayheadToEndOfClip()
  }
  
  
  @IBAction func playPauseButtonPress(sender: UIButton) {
    let (startTime, endTime) = waveformEditorView.getClipPlayheadEndTimes()
    presenter.didRequestPlayPauseAtTime(startTime, endTime: endTime)
  }
}

extension ICSEView: ICSEViewProtocol {
  // MARK: communication PRESENTER -> VIEW
  
  func hideExtensionWithCompletionHandler(completion:(Bool) -> Void) {
    UIView.animateWithDuration(0.20, animations: { () -> Void in
      self.navigationController!.view.transform = CGAffineTransformMakeTranslation(0, self.navigationController!.view.frame.size.height)
      },
                               completion: completion)
  }
  
  func configure(withDuration duration: Double, playStartTime: Double) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.waveformEditorView.configure(withDuration: duration, playStartTime: playStartTime, presenter: self.presenter)
    })
  }
  
  func readyToPlay() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.playPauseButton.enabled = true
      //self.playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
      self.beginButton.enabled = true
      self.endButton.enabled = true
      self.shiftForwardButton.enabled = true
      self.shiftBackwardButton.enabled = true
      self.waveformEditorView.enabeled = true
    })
  }
  
  func showPlayButton() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      //self.playPauseButton.setTitle("play", forState: .Normal)
      self.playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
      self.beginButton.enabled = true
      self.endButton.enabled = true
      self.shiftForwardButton.enabled = true
      self.shiftBackwardButton.enabled = true
      self.waveformEditorView.enabeled = true
    })
  }
  
  func showPauseButton() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      //self.playPauseButton.setTitle("pause", forState: .Normal)
      self.playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
      self.beginButton.enabled = false
      self.endButton.enabled = false
      self.shiftForwardButton.enabled = false
      self.shiftBackwardButton.enabled = false
      self.waveformEditorView.enabeled = false
    })
  }
  
  func playerTimeDidChange(newTime time: Double) {
    waveformEditorView.handlePlayerTimeChange(newTime: time)
  }
  
  func showErrorWithSummary(summary: String, message: String? = nil) {
    assert(false, "\(summary) \(message)")
    let alertAC = UIAlertController(title: summary, message: message, preferredStyle: .Alert)
    let defaultAction = UIAlertAction(title: "Okay", style: .Default, handler: nil)
    alertAC.addAction(defaultAction)
    
    // Delay for view to appear otherwise get this: Presenting view controllers on detached view controllers is discouraged
    // This is a simple soultion but not perfect. Seems reasonable since Alert appears without delay. KISS principal.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.987654321 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
      self.presentViewController(alertAC, animated: true, completion: nil)
    })
  }
  
  func showClipShareWithURL(url: NSURL) {
    let actionAC = UIAlertController(title: "Share Clip via:", message: nil, preferredStyle: .ActionSheet)
    actionAC.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    actionAC.addAction(cancelAction)
    
    if MFMessageComposeViewController.canSendText() {
      let messageAction = UIAlertAction(title: "message", style: .Default) { (alertAction) in
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        if messageVC.addAttachmentURL(url, withAlternateFilename: nil) {
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(messageVC, animated: true, completion: nil)
          })
        } else {
          self.presenter.clipShareDidFinishWithResult(ICSEViewShareResult.ShareMessageResultAddAttachmentFailed,
                                                      messageComposeResult: nil, mailComposeResult: nil, mailComposeError: nil)
        }
      }
      actionAC.addAction(messageAction)
    }
    
    if let data = NSData(contentsOfURL: url) where MFMailComposeViewController.canSendMail() {
      let emailAction = UIAlertAction(title: "email", style: .Default) { (alertAction) in
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setSubject("checkout this audio clip...")
        let fileName = url.lastPathComponent ?? "InstaClip.m4a"
        mailVC.addAttachmentData(data, mimeType: "audio/mp4", fileName: fileName)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.presentViewController(mailVC, animated: true, completion: nil)
        })
      }
      actionAC.addAction(emailAction)
    }
    // trigger loadView() to fix this warning during presentViewController()
    // Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates.
    let _ = actionAC.view
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.presentViewController(actionAC, animated: true, completion: nil)
    })
  }
  
  func enableSaveButton() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.navigationItem.rightBarButtonItem?.enabled = true
    })
  }
  
  func disableSaveButton() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.navigationItem.rightBarButtonItem?.enabled = false
    })
  }
  
  func showSpinner() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.spinnerView = UIView()
      self.spinnerView!.translatesAutoresizingMaskIntoConstraints = false
      self.spinnerView!.backgroundColor = UIColor.clearColor()
      
      self.view.addSubview(self.spinnerView!)
      NSLayoutConstraint(item: self.spinnerView!, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0).active = true
      NSLayoutConstraint(item: self.spinnerView!, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0).active = true
      NSLayoutConstraint(item: self.spinnerView!, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1, constant: 0).active = true
      NSLayoutConstraint(item: self.spinnerView!, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1, constant: 0).active = true
      
      let activityView = UIActivityIndicatorView.init(activityIndicatorStyle: .WhiteLarge)
      activityView.translatesAutoresizingMaskIntoConstraints = false
      activityView.alpha = 0
      
      self.spinnerView!.addSubview(activityView)
      NSLayoutConstraint(item: self.spinnerView!, attribute: .CenterX, relatedBy: .Equal, toItem: activityView, attribute: .CenterX, multiplier: 1, constant: 0).active = true
      NSLayoutConstraint(item: self.spinnerView!, attribute: .CenterY, relatedBy: .Equal, toItem: activityView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
      
      activityView.startAnimating()
      
      UIView.animateWithDuration(0.25, delay: 0.25, options: [], animations: {
        self.spinnerView!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        activityView.alpha = 1
        }, completion: nil )
    })
  }
  
  func hideSpinner() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.spinnerView?.removeFromSuperview()
      self.spinnerView = nil
    })
  }
}

extension ICSEView: MFMessageComposeViewControllerDelegate {

  // MARK: - MFMessageComposeViewControllerDelegate
  func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
    controller.dismissViewControllerAnimated(true) {
      self.presenter.clipShareDidFinishWithResult(nil, messageComposeResult: result, mailComposeResult: nil, mailComposeError: nil)
    }
  }
}

extension ICSEView: MFMailComposeViewControllerDelegate {
  
  // MARK:  MFMailComposeViewControllerDelegate
  func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
    controller.dismissViewControllerAnimated(true) {
      self.presenter.clipShareDidFinishWithResult(nil, messageComposeResult: nil, mailComposeResult: result, mailComposeError: error)
    }
  }
}
