//
//  APICommunicator+Alamofire.swift
//  Flip
//
//  Created by Jozef Matus on 17/09/15.
//  Copyright © 2015 strv. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import APICommunicator

enum Router: URLRequestConvertible
{
    static var OAuthToken: String?
    /**
    This is redudant just in our case, it might happen that download
    **/
    case SendRequest(method: Alamofire.Method, path: NSURL, parameters: [String : AnyObject]?, paramEncoding: ParameterEncoding, headers: [String: String]?)
    case Download(method: Alamofire.Method, path: NSURL, headers: [String: String]?)
    case Upload(method: Alamofire.Method, path: NSURL, headers: [String: String]?)
    
    var method : Alamofire.Method
        {
            switch self
            {
            case .SendRequest(method: let tmpMethod, path:_, parameters:_, paramEncoding:_, headers:_):
                return tmpMethod
            case .Download(method: let tmpMethod, path:_, headers:_):
                return tmpMethod
            case .Upload(method: let tmpMethod, path:_, headers:_):
                return tmpMethod
            }
    }
    var path : NSURL
        {
            switch self
            {
            case .SendRequest(method:_, path: let tmpPath, parameters:_, paramEncoding:_, headers:_):
                return tmpPath
            case .Download(method:_, path: let tmpPath, headers:_):
                return tmpPath
            case .Upload(method:_, path: let tmpPath, headers:_):
                return tmpPath
            }
    }
    
    var parameters : [String : AnyObject]?
        {
            switch self
            {
            case .SendRequest(method:_, path:_, parameters: let tmpParams, paramEncoding:_, headers:_):
                return tmpParams
            case .Download(method:_, path:_, headers:_):
                return nil
            case .Upload(method:_, path:_, headers:_):
                return nil
            }
    }
    
    var headers : [String : String]?
        {
            switch self
            {
            case .SendRequest(method:_, path:_, parameters:_, paramEncoding:_, headers: let tmpHeaders):
                return tmpHeaders
            case .Download(method:_, path:_, headers: let tmpHeaders):
                return tmpHeaders
            case .Upload(method:_, path:_, headers: let tmpHeaders):
                return tmpHeaders
            }
    }
    
    //    var encoding
    
    // MARK: URLRequestConvertible
    
    var URLRequest: NSMutableURLRequest
        {
            let mutableURLRequest = NSMutableURLRequest(URL: path)
            mutableURLRequest.HTTPMethod = method.rawValue
            
            if let headers = self.headers
            {
                for (key, value) in headers
                {
                    mutableURLRequest.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            
            
            
            switch self
            {
            case .SendRequest(_, _, _, let encoding, _):
                switch encoding
                {
                case .JSON:
                    return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
                case .URL:
                    return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
                default:
                    return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
                }
            case .Download(_, _, _):
                return mutableURLRequest//coz no parameters are passed
            case .Upload(_, _, _):
                return mutableURLRequest//coz no parameters are passed
                
            }
    }
    
}

public class AlamofireAPIFactory
{
    public required init(baseURL: NSURL!)
    {
        self.baseURL = baseURL
    }
    
    enum ErrorCode: Int
    {
        case Offline = -1009
        case Canceled = -999
    }
    
    
    let baseURL: NSURL
    
    // MARK: - Alamofire
    
    func sendAlamofireRequest(method: Alamofire.Method, path: String, parameters: [String : AnyObject]?, encoding: ParameterEncoding, options: NSJSONReadingOptions = .AllowFragments, headers: [String : String]?,completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<AnyObject>) -> Void)
    {
        let url = NSURL(string: baseURL.absoluteString + path)!
        Alamofire.request(Router.SendRequest(method: method,path: url, parameters: parameters, paramEncoding: encoding, headers: headers)).responseJSON(completionHandler:completionHandler)
        
    }
    
    
    
}

extension AlamofireAPIFactory : APICommunicator {
    
    public func get(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        sendAlamofireRequest(.GET, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: AlamofireAPIFactory.completionHandler(completion))
        return nil
    }
    
    public func post(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        
        sendAlamofireRequest(.POST, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: AlamofireAPIFactory.completionHandler(completion))
        return nil
    }
    
    public func put(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        
        sendAlamofireRequest(.PUT, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: AlamofireAPIFactory.completionHandler(completion))
        return nil
    }
    
    public func patch(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        
        sendAlamofireRequest(.PATCH, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: AlamofireAPIFactory.completionHandler(completion))
        return nil
    }
    
    public func delete(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        
        sendAlamofireRequest(.DELETE, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: AlamofireAPIFactory.completionHandler(completion))
        return nil
    }
    
    public func performCustomCall(callClosure: APICommunicatorCustomCallClosure, completion: APICommunicatorCompletionClosure?) -> NSOperation?
    {
        callClosure(completion)
        return nil
    }
    
    public func getAlamofireParamEncoding(ourEnconding: ParamEncoding) -> Alamofire.ParameterEncoding
    {
        switch (ourEnconding)
        {
        case ParamEncoding.URL:
            return Alamofire.ParameterEncoding.URL
        case ParamEncoding.JSON:
            return Alamofire.ParameterEncoding.JSON
        }
    }
}


extension AlamofireAPIFactory
{
    public static func completionHandler(innerHandler: APICommunicatorCompletionClosure?) -> (NSURLRequest?, NSHTTPURLResponse?, Result<AnyObject>) -> Void
    {
        return
            {
                (request, response, result) -> Void in
                switch result
                {   //TODO : parse always returns success
                case .Success(let value):
                    let jsonData = JSON(value)
                    guard (jsonData["error"].string == nil)
                        else
                    {
                        let errorCode = jsonData["code"].int ?? 666
                        let error : APICommunicatorError = APICommunicatorError.GeneralError(statusCode: errorCode, message: jsonData["error"].string!)
                        innerHandler?(responseObject: nil, error: error)
                        return
                    }
                    innerHandler?(responseObject: JSON(value), error: nil)
                    break
                case .Failure(_, let errorType):
                    let error : APICommunicatorError =
                    {
                        let nsError = errorType as NSError
                        if(nsError.code == ErrorCode.Offline.rawValue)
                        {
                            return APICommunicatorError.NoInternetConnection
                        }
                        return APICommunicatorError.GeneralError(statusCode: nsError.code, message: nsError.description)
                        }()
                    innerHandler?(responseObject: nil, error: error)
                    break
                }
        }
    }
}
