//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

final class ICSEPresenter {
  let configuration: ICSEConfiguration
  weak var view: ICSEViewProtocol!
  var interactor: ICSEInteractorInputProtocol!
  var wireframe: ICSEWireframeProtocol!
  
  init(withICSEConfiguration configuration: ICSEConfiguration = ICSEDefaultConfiguration()) {
    self.configuration = configuration
  }
  
  private func shiftPlayTimeWithStartTime(time: Double) -> Double {
    return time-configuration.timeShiftSeconds < 0 ? 0 : time-configuration.timeShiftSeconds
  }
}

// MARK: - methods for communication VIEW -> PRESENTER
extension ICSEPresenter: ICSEPresenterProtocol {

  func didRequestWaveformMonoPoints(atTime seconds: Double) -> [CGPoint] {
    return interactor.fetchWaveformMonoPoints(atTime: seconds)
  }

  func didRequestClipAtTime(startTime: Double, endTime: Double) {
    view.disableSaveButton()
    view.showSpinner()
    interactor.requestClipAtTime(startTime, endTime: endTime)
  }
  
  func didRequestCancel() {
    interactor.requestPausePlayback()
    view.hideExtensionWithCompletionHandler({ (Bool) -> Void in
      self.wireframe.exitICSEModule()
    })
  }
  
  func didRequestPlayPauseAtTime(startTime: Double, endTime: Double) {
    interactor.requestPlayPauseAtTime(startTime, duration: endTime-startTime)
  }
  
  func clipShareDidFinishWithResult(icseViewShareResult: ICSEViewShareResult?, messageComposeResult: MessageComposeResult?, mailComposeResult: MFMailComposeResult?, mailComposeError: NSError?) {
    if let icseViewResult = icseViewShareResult where icseViewResult == .ShareMessageResultAddAttachmentFailed {
      view.showErrorWithSummary("Could not attach clip to the message", message: nil)
    } else if let messageResult = messageComposeResult where messageResult == MessageComposeResultFailed {
      view.showErrorWithSummary("Could not send the message", message:nil)
    } else if let mailResult = mailComposeResult where mailResult == MFMailComposeResultFailed {
      view.showErrorWithSummary("Could not send the email", message: mailComposeError?.localizedDescription)
    }
  }
}

// MARK: - methods for communication INTERACTOR -> PRESENTER
extension ICSEPresenter: ICSEInteractorOutputProtocol {
  
  func configureWaveform(withDuration duration: Double, hostAppCurrentTime currentTime: Double) {
    
    let playStartTime = self.shiftPlayTimeWithStartTime(currentTime)
    view.configure(withDuration: duration, playStartTime: playStartTime)
  }

  func playerReadyToPlay() {
    self.view.readyToPlay()
  }
  
  func playerRateDidChange(newRate rate: Float) {
    if rate == 0.0 {
      view.showPlayButton()
    } else {
      view.showPauseButton()
    }
  }
  
  func playerTimeDidChange(newTime time: Double) {
    view.playerTimeDidChange(newTime: time)
  }

  func replyClipWithURL(url: NSURL) {
    view.showClipShareWithURL(url)
    view.hideSpinner()
    view.enableSaveButton()
  }
  
  func replyClipFailedWithSummary(summary: String, message: String?) {
    view.hideSpinner()
    view.enableSaveButton()
    view.showErrorWithSummary(summary, message: message)
  }

  func interactorDidFailWithResult(result: ICSEInteractorResult, error: NSError?) {
    let errmsg = error?.localizedDescription
    switch result {
    case .AVPlayerManagerPlayerStatusFailed:
      view.showErrorWithSummary("Audio player error", message: errmsg)
    case .AVPlayerManagerAudioSessionFailed:
      view.showErrorWithSummary("Could not retrieve podcast current time from host app", message: errmsg)
    case .ExtensionDataManagerPodcastURLFailed:
      view.showErrorWithSummary("Could not retrieve podcast URL from host app", message: errmsg)
    case .ExtensionDataManagerPodcastCurrentTimeFailed:
      view.showErrorWithSummary("Could not retrieve podcast current time from host app", message: errmsg)
    case .ExtensionDataManagerIncompleteData:
      view.showErrorWithSummary("Could not retrieve podcast info from host app", message: errmsg)
    case .AssetDataManagerMissingAudioTrack:
      view.showErrorWithSummary("Podcast missing audio track", message: errmsg)
    case .AssetDataManagerMissingAudioFormatDescription:
      view.showErrorWithSummary("Audio track missing format description", message: errmsg)
    case .AssetDataManagerAudioMustBeMonoOrStereo:
      view.showErrorWithSummary("Audio track must be mono or stereo", message: errmsg)
    case .AssetDataManagerCouldNotCreateWaveformData:
      view.showErrorWithSummary("Could not create waveform data", message: errmsg)        }
  }
}