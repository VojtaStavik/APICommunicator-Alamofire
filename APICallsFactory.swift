//
//  APICallsFactory.swift
//
//  Created by Vojta Stavik on 03/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation

public protocol APICallsFactory : APICommunicator {
    
    var predefinedParameters :  [String: AnyObject]?    { get }
    var predefinedHeaders :     [String: String]?       { get }
}


public extension APICallsFactory {
    
    public func newOperation<T: APIResponseSerializer>(path: String, method: HTTPMethod, paramEncoding: ParamEncoding? = nil) -> APIRequestOperation<T>
    {
        let operation = APIRequestOperation<T>(communicator: self, path: path, method: method, paramEncoding: paramEncoding ?? .JSON) // FIXME: Proper encoding
        
        addPredefinedHeaders(operation)
        addPredefinedParameters(operation)
        
        return operation
    }
    
    
    public func newOperation<T: APIResponseSerializer>(customExecClosure : APICommunicatorCustomCallClosure) -> APIRequestOperation<T>
    {
        let operation = APIRequestOperation<T>(communicator: self, customCallClosure: customExecClosure)
        
        addPredefinedHeaders(operation)
        addPredefinedParameters(operation)
        
        return operation
    }

    
    
    public func addPredefinedHeaders<T: APIResponseSerializer>(operation: APIRequestOperation<T>) -> APIRequestOperation<T> {
        
        if let predefinedHeaders = predefinedHeaders {
            
            var headers = operation.headers ?? [String:String]()
            
            for (key, value) in predefinedHeaders {
                headers[key] = value
            }
            
            operation.headers = headers
        }
        
        return operation
    }
    
    
    public func addPredefinedParameters<T: APIResponseSerializer>(operation: APIRequestOperation<T>) -> APIRequestOperation<T> {
        
        if let predefinedParameters = predefinedParameters {
            
            var parameters = operation.parameters ?? [String:AnyObject]()
            
            for (key, value) in predefinedParameters {
                parameters[key] = value
            }
            
            operation.parameters = parameters
        }
        
        return operation
    }
}


public extension APIRequestOperation
{
    
    public func with(parameters parameters: [String: AnyObject]) -> APIRequestOperation {
        
        self.parameters = self.parameters ?? [String:AnyObject]()
        
        for (key,value) in parameters {
            
            self.parameters![key] = value
        }
        
        return self
    }
    
    
    public func with(headers headers: [String: String]) -> APIRequestOperation {
        
        self.headers = self.headers ?? [String:String]()
        
        for (key,value) in headers {
            
            self.headers![key] = value
        }
        
        return self
    }
}
