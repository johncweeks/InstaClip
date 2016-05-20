//
//  ICSEExtensionDataManager.swift
//  InstaClip Player
//
//  Created by John Weeks on 5/1/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MobileCoreServices

final class ICSEExtensionDataManager: ICSEExtensionDataManagerProtocolWithObserver {
  
  var icseExtensionItemDidChange: ((ICSEExtensionDataManagerObserverProtocol) -> ())?
  var icseExtensionItem: ICSEExtensionItem? {
    didSet {
      self.icseExtensionItemDidChange?(self)
    }
  }
  
  private let interactor: ICSEDataManagerOutputProtocol
  private var hostAppCurrentTime: Double?
  private var iPodLibraryAssetURL: NSURL?
  
  init(interactor: ICSEDataManagerOutputProtocol, extensionContext: NSExtensionContext) {
    self.interactor = interactor
    var loadItemCount = 0
    if let inputItems = extensionContext.inputItems as? [NSExtensionItem] {
      for extensionItem in inputItems     {
        if let attachments = extensionItem.attachments as? [NSItemProvider] {
          for itemProvider in attachments {
            if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
              loadItemCount += 1
              itemProvider.loadItemForTypeIdentifier(String(kUTTypeURL), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                guard let podcastURL = data as? NSURL else {
                  self.interactor.dataManagerDidFailWithResult(.ExtensionDataManagerPodcastURLFailed, error: error)
                  return
                }
                // serialize to prevent potential race condition with other load item completionHandler
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                  self.iPodLibraryAssetURL = podcastURL
                  self.itemLoadComplete()
                })
              })
            }
            if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) {
              loadItemCount += 1
              itemProvider.loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                guard let currentTimeString = data as? String else {
                  self.interactor.dataManagerDidFailWithResult(.ExtensionDataManagerPodcastCurrentTimeFailed, error: error)
                  return
                }
                guard let currentTimeDouble = Double(currentTimeString) else {
                  self.interactor.dataManagerDidFailWithResult(.ExtensionDataManagerPodcastCurrentTimeFailed, error: error)
                  return
                }
                // serialize to prevent potential race condition with other load item completionHandler
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                  self.hostAppCurrentTime = currentTimeDouble
                  self.itemLoadComplete()
                })
              })
            }
          }
        }
      }
    }
    if loadItemCount <= 1 {
      self.interactor.dataManagerDidFailWithResult(.ExtensionDataManagerIncompleteData, error: nil)
    }
  }
  
  private func itemLoadComplete() {
    guard let iPodLibraryAssetURL = self.iPodLibraryAssetURL, hostAppCurrentTime = self.hostAppCurrentTime else {
      return
    }
    self.icseExtensionItem = ICSEExtensionItem(hostAppCurrentTime: hostAppCurrentTime, iPodLibraryAssetURL: iPodLibraryAssetURL)
  }
}
