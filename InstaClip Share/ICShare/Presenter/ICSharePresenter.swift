//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation

class ICSharePresenter: ICSharePresenterProtocol, ICShareInteractorOutputProtocol
{
    weak var view: ICShareViewProtocol?
    var interactor: ICShareInteractorInputProtocol?
    var wireFrame: ICShareWireFrameProtocol?
    
    init() {}
}