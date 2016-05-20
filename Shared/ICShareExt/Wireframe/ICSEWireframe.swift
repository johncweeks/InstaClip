//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import UIKit

final class ICSEWireframe {
  
  let view: ICSEViewProtocol = ICSEView()
  let presenter: protocol<ICSEPresenterProtocol, ICSEInteractorOutputProtocol>
  let interactor: protocol<ICSEInteractorInputProtocol, ICSEAVPlayerManagerOutputProtocol, ICSEDataManagerOutputProtocol> = ICSEInteractor()
  var rootWireframe: RootWireframe!
  
  init(withICSEConfiguration configuration: ICSEConfiguration = ICSEDefaultConfiguration()) {
    
    self.presenter = ICSEPresenter(withICSEConfiguration: configuration)
    
    view.presenter = presenter
    presenter.view = view
    presenter.wireframe = self
    presenter.interactor = interactor
    interactor.presenter = presenter
  }
}

// MARK: - methods for communication WIREFRAME -> ROOTWIREFRAME
extension ICSEWireframe: ICSEWireframeProtocol {

  // FIXME: ?need another protocol for this?
  func configureICSEModule(withExtensionContext context: NSExtensionContext) {
    interactor.extensionDataManager = ICSEExtensionDataManager(interactor: interactor, extensionContext: context)
  }
  
  func exitICSEModule() {
    rootWireframe.exitICSEModule()
  }
}