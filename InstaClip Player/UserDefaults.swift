//
//  UserDefaults.swift
//  InstaClip Player
//
//  Created by John Weeks on 9/15/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//
//  Static Type Dictionary for NSUserDefaults
//  Inspired from http://radex.io/swift/nsuserdefaults/static

import Foundation

class DefaultsKeys {
    private init() {}
}

class DefaultsKey<ValueType>: DefaultsKeys {
    let _key: String
    
    init(_ key: String) {
        self._key = key
    }
}

extension NSUserDefaults {
    
    subscript(key: String) -> Any? {
        get {
            return self[key]
        }
        set {
            switch newValue {
            case let v as NSObject: setObject(v, forKey: key)
            case nil: removeObjectForKey(key)
            default: assertionFailure("Invalid value type")
            }
        }
    }

}

extension NSUserDefaults {
    subscript(key: DefaultsKey<[String : [String : Double]]>) -> [String : [String : Double]] {
        get { return dictionaryForKey(key._key) as? [String : [String : Double]] ?? [String : [String : Double]]() }
        set { self[key._key] = newValue }
    }

}

