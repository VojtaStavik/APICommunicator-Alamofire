//
//  APICommunicator.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import SwiftyJSON

public typealias APICommunicatorCompletionClosure = (responseObject: JSON?, error: APICommunicatorError?) -> Void
public typealias APICommunicatorCustomCallClosure = (APICommunicatorCompletionClosure?) -> ()


public protocol APICommunicator : class{
    
    init(baseURL: NSURL!)
    
    func get(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func post(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func put(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func patch(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func delete(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func performCustomCall(callClosure: APICommunicatorCustomCallClosure, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    
}

public enum APICommunicatorError : ErrorType {
    
    case NoInternetConnection
    case GeneralError(statusCode: Int , message: String)
}

