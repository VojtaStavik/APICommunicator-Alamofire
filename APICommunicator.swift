//
//  APICommunicator.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation

public typealias ProgressUpdateClosure = Float -> Void
public typealias APICommunicatorCompletionClosure = (responseObject: NSData?, error: APICommunicatorError?) -> Void
public typealias APICommunicatorCustomCallClosure = (progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> ()


public protocol APICommunicator : class {
    
    init(baseURL: NSURL!)
    
    func get(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func post(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?,  completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func put(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func patch(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func delete(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    func performCustomCall(callClosure: APICommunicatorCustomCallClosure, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    
}


public enum APICommunicatorError : ErrorType {
    
    case NoInternetConnection
    case APIError(statusCode: Int, responseData: NSData?)
    case GeneralError(statusCode: Int , message: String)
}


extension APICommunicatorError: Equatable { }

public func == (left: APICommunicatorError, right: APICommunicatorError) -> Bool {
    switch (left, right) {
    case (.NoInternetConnection, .NoInternetConnection):
        return true
    case (.APIError(let leftCode, let leftData), .APIError(let rightCode, let rightData)):
        return leftCode == rightCode && leftData == rightData
    case (.GeneralError(let leftStatusCode, let leftMessage), .GeneralError(let rightStatusCode, let rightMessage)):
        return leftStatusCode == rightStatusCode && leftMessage == rightMessage
    default:
        return false
    }
}
