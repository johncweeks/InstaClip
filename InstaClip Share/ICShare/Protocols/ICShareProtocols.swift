//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation

protocol ICShareViewProtocol: class
{
    var presenter: ICSharePresenterProtocol? { get set }
    /**
    * Add here your methods for communication PRESENTER -> VIEW
    */
}

protocol ICShareWireFrameProtocol: class
{
    class func presentICShareModule(fromView view: AnyObject)
    /**
    * Add here your methods for communication PRESENTER -> WIREFRAME
    */
}

protocol ICSharePresenterProtocol: class
{
    var view: ICShareViewProtocol? { get set }
    var interactor: ICShareInteractorInputProtocol? { get set }
    var wireFrame: ICShareWireFrameProtocol? { get set }
    /**
    * Add here your methods for communication VIEW -> PRESENTER
    */
}

protocol ICShareInteractorOutputProtocol: class
{
    /**
    * Add here your methods for communication INTERACTOR -> PRESENTER
    */
}

protocol ICShareInteractorInputProtocol: class
{
    var presenter: ICShareInteractorOutputProtocol? { get set }
    var APIDataManager: ICShareAPIDataManagerInputProtocol? { get set }
    var localDatamanager: ICShareLocalDataManagerInputProtocol? { get set }
    /**
    * Add here your methods for communication PRESENTER -> INTERACTOR
    */
}

protocol ICShareDataManagerInputProtocol: class
{
    /**
    * Add here your methods for communication INTERACTOR -> DATAMANAGER
    */
}

protocol ICShareAPIDataManagerInputProtocol: class
{
    /**
    * Add here your methods for communication INTERACTOR -> APIDATAMANAGER
    */
}

protocol ICShareLocalDataManagerInputProtocol: class
{
    /**
    * Add here your methods for communication INTERACTOR -> LOCALDATAMANAGER
    */
}
