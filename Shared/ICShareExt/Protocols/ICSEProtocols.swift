//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MessageUI

protocol ICSEConfiguration {
  var clipInitialDurationSeconds: Double { get }
  var timeShiftSeconds: Double { get }
  var pointsPerSecond: CGFloat { get }
  var waveformSampleSeconds: CGFloat  { get }
}

protocol ICSEViewProtocol: class {
  var presenter: ICSEPresenterProtocol! { get set }
  /**
   * Add here your methods for communication PRESENTER -> VIEW
   */
  func hideExtensionWithCompletionHandler(completion:(Bool) -> Void)
  func configure(withDuration duration: Double, playStartTime: Double)
  func readyToPlay()
  func showPlayButton()
  func showPauseButton()
  func playerTimeDidChange(newTime time: Double)
  func showErrorWithSummary(summary: String, message: String?)
  func showClipShareWithURL(url: NSURL)
  func showSpinner()
  func hideSpinner()
  func enableSaveButton()
  func disableSaveButton()
}

protocol ICSEWaveformEditorViewProtocol: class {
  func configure(withDuration duration: Double, playStartTime: Double, presenter: ICSEPresenterProtocol, configuration: ICSEConfiguration)
  
  func getClipPlayheadEndTimes() -> (Double, Double)
  func getClipStartEndTimes() -> (Double, Double)
  func handlePlayerTimeChange(newTime time: Double)
  func movePlayheadToBeginOfClip()
  func movePlayheadToEndOfClip()
  func shiftClipBackward()
  func shiftClipForward()
}

protocol ICSEWaveformContentViewProtocol: class {
  var presenter: ICSEPresenterProtocol! { get }
  
  func configure(withDuration duration: Double, presenter: ICSEPresenterProtocol, configuration: ICSEConfiguration)
  
}

protocol RootWireframeProtocol: class {
  var icShareExtWireframe: ICSEWireframeProtocol  { get }
  /**
   * Add here your methods for communication WIREFRAME -> ROOTWIREFRAME
   */
  func exitICSEModule()
}

protocol ICSEWireframeProtocol: class
{
  var view: ICSEViewProtocol { get }
  var rootWireframe: RootWireframe! { get set }
  
  init(withICSEConfiguration configuration: ICSEConfiguration)
  func configureICSEModule(withExtensionContext context: NSExtensionContext)
  /**
   * Add here your methods for communication PRESENTER -> WIREFRAME
   */
  func exitICSEModule()
}

protocol ICSEPresenterProtocol: class {
  var view: ICSEViewProtocol! { get set }
  var interactor: ICSEInteractorInputProtocol! { get set }
  var wireframe: ICSEWireframeProtocol! { get set }
  
  init(withICSEConfiguration configuration: ICSEConfiguration)
  
  /**
   * Add here your methods for communication VIEW -> PRESENTER
   */
  func didRequestClipAtTime(startTime: Double, endTime: Double)
  func didRequestCancel()
  func didRequestPlayPauseAtTime(startTime: Double, endTime: Double)
  
  func didRequestWaveformMonoPoints(atTime seconds: Double) -> [CGPoint]
  
  func clipShareDidFinishWithResult(icseViewShareResult: ICSEViewShareResult?, messageComposeResult: MessageComposeResult?, mailComposeResult: MFMailComposeResult?, mailComposeError: NSError?)
}

protocol ICSEInteractorOutputProtocol: class {
  /**
   * Add here your methods for communication INTERACTOR -> PRESENTER
   */
  func configureWaveform(withDuration duration: Double, hostAppCurrentTime currentTime: Double)
  func playerReadyToPlay()
  func playerRateDidChange(newRate rate: Float)
  func playerTimeDidChange(newTime time: Double)
  
  func replyClipFailedWithSummary(summary: String, message: String?)
  func replyClipWithURL(url: NSURL)
  
  func interactorDidFailWithResult(result: ICSEInteractorResult, error: NSError?)
}

protocol ICSEInteractorInputProtocol: class {
  var presenter: ICSEInteractorOutputProtocol! { get set }
  var extensionDataManager: ICSEExtensionDataManagerProtocolWithObserver! { get set }
//  var avAssetDataManager: ICSEAVAssetDataManagerProtocolWithObserver! { get }
//  var avPlayerManager: ICSEAVPlayerManagerInputProtocol! { get }
  /**
   * Add here your methods for communication PRESENTER -> INTERACTOR
   */
  func fetchWaveformMonoPoints(atTime seconds: Double) -> [CGPoint]
  func requestClipAtTime(startTime: Double, endTime: Double)
  func requestPlayPauseAtTime(startTime: Double, duration: Double)
  func requestPausePlayback()
}

protocol ICSEDataManagerOutputProtocol: class {
  func dataManagerDidFailWithResult(result: ICSEInteractorResult, error: NSError?)
}

protocol ICSEExtensionDataManagerInputProtocol: class {
  init(interactor: ICSEDataManagerOutputProtocol, extensionContext: NSExtensionContext)
}

protocol ICSEExtensionDataManagerObserverProtocol {
  var icseExtensionItemDidChange: ((ICSEExtensionDataManagerObserverProtocol) -> ())? { get set }
  var icseExtensionItem: ICSEExtensionItem? { get }
}

typealias ICSEExtensionDataManagerProtocolWithObserver = protocol<ICSEExtensionDataManagerInputProtocol, ICSEExtensionDataManagerObserverProtocol>

protocol ICSEAVAssetDataManagerInputProtocol: class{
  init(interactor: ICSEDataManagerOutputProtocol, nsURL: NSURL, icseConfiguration configuration: ICSEConfiguration)
  func monoPointsLEI16(startingAt startTime: Float64) -> [CGPoint]
  func newClipAtTime(startTime: Float64, endTime: Float64, completionHandler completion: (ICSEAVAssetDataManagerClipResult) -> Void)
}

protocol ICSEAVAssetDataManagerObserverProtocol {
  var icseAVAssetItemDidChange: ((ICSEAVAssetDataManagerObserverProtocol) -> ())? { get set }
  var icseAVAssetItem: ICSEAVAssetItem? { get }
}

typealias ICSEAVAssetDataManagerProtocolWithObserver = protocol<ICSEAVAssetDataManagerInputProtocol, ICSEAVAssetDataManagerObserverProtocol>


protocol ICSEAVPlayerManagerOutputProtocol: class {
  /**
   * Add here your methods for communication ICSEAVPlayerManager -> INTERACTOR
   */
  func avPlayerManagerReady()
  func avPlayerRateDidChange(newRate rate: Float)
  func avPlayerTimeDidChange(newTime time: CMTime)
}

protocol ICSEAVPlayerManagerInputProtocol: class {
  init(interactor: protocol<ICSEAVPlayerManagerOutputProtocol, ICSEDataManagerOutputProtocol>, asset: AVAsset)
  
  /**
   * Add here your methods for communication INTERACTOR -> ICSEAVPlayerManager
   */
  func playPause(atTime seconds: Double, duration: Double)
  func pause()
}