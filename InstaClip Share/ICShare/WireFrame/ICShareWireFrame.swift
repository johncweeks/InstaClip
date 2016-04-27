//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation

class ICShareWireFrame: ICShareWireFrameProtocol
{
    class func presentICShareModule(fromView view: AnyObject)
    {
        // Generating module components
        var view: ICShareViewProtocol = ICShareView()
        var presenter: protocol<ICSharePresenterProtocol, ICShareInteractorOutputProtocol> = ICSharePresenter()
        var interactor: ICShareInteractorInputProtocol = ICShareInteractor()
        var APIDataManager: ICShareAPIDataManagerInputProtocol = ICShareAPIDataManager()
        var localDataManager: ICShareLocalDataManagerInputProtocol = ICShareLocalDataManager()
        var wireFrame: ICShareWireFrameProtocol = ICShareWireFrame()
        
        // Connecting
        view.presenter = presenter
        presenter.view = view
        presenter.wireFrame = wireFrame
        presenter.interactor = interactor
        interactor.presenter = presenter
        interactor.APIDataManager = APIDataManager
        interactor.localDatamanager = localDataManager
    }
}