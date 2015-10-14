//
//  APIActivityIndicator.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation


public protocol APIActivityIndicator {
    
    func apiCallStarted()
    func apiCallFinished(error: [APICommunicatorError])
}