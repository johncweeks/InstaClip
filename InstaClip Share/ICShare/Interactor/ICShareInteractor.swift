//
// Created by John Weeks
// Copyright (c) 2016 John Weeks. All rights reserved.
//

import Foundation

class ICShareInteractor: ICShareInteractorInputProtocol
{
    weak var presenter: ICShareInteractorOutputProtocol?
    var APIDataManager: ICShareAPIDataManagerInputProtocol?
    var localDatamanager: ICShareLocalDataManagerInputProtocol?
    
    init() {}
}