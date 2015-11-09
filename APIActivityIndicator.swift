//
//  APIActivityIndicator.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation


public protocol APIActivityIndicator {
    
    func apiCallStarted()
    func apiCallProgressUpdated(progress: Float)
    
    func apiCallFinished(error: [APICommunicatorError])
}

public extension APIActivityIndicator {
    
    public func apiCallProgressUpdated(progress: Float) { }
}