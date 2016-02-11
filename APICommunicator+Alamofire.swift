//
//  APICommunicator+Alamofire.swift
//
//  Created by Jozef Matus on 17/09/15.
//  Copyright © 2015 strv. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

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

public class AlamofireAPIFactory {
    public required init(baseURL: NSURL!) {
        self.baseURL = baseURL
    }
    
    let baseURL: NSURL
    
    // MARK: - Alamofire
    func sendAlamofireRequest(method: Alamofire.Method, path: String, parameters: [String : AnyObject]?, encoding: ParameterEncoding, options: NSJSONReadingOptions = .AllowFragments, headers: [String : String]?,completionHandler: APICommunicatorCompletionClosure?)
    {
        guard let url = NSURL(string: baseURL.absoluteString + path) else {
            completionHandler?(responseObject: nil, error: APICommunicatorError.GeneralError(statusCode: 0, message: "Invalid URL"))
            return
        }
        
        Alamofire
            .request(Router.SendRequest(method: method,path: url, parameters: parameters, paramEncoding: encoding, headers: headers))
            .responseData { response -> Void in
                guard let statusCode = response.response?.statusCode else {
                    completionHandler?(responseObject: nil, error: APICommunicatorError.NoInternetConnection)
                    return
                }
                
                switch (statusCode, response.result) {
                case (200...399, let result) where result.value != nil:
                    completionHandler?(responseObject: result.value!, error: nil)
                    
                case (400...599, let result):
                    completionHandler?(responseObject: nil, error: (APICommunicatorError.APIError(statusCode: statusCode, responseData: result.value)))
                    
                default:
                    completionHandler?(responseObject: nil, error: (APICommunicatorError.GeneralError(statusCode: statusCode, message: "Unknown error")))
                }
        }
    }
}


extension AlamofireAPIFactory : APICommunicator {
    public func get(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        sendAlamofireRequest(.GET, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: completion)
        return nil
    }
    
    public func post(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        sendAlamofireRequest(.POST, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: completion)
        return nil
    }
    
    public func put(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        sendAlamofireRequest(.PUT, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: completion)
        return nil
    }
    
    public func patch(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        sendAlamofireRequest(.PATCH, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: completion)
        return nil
    }
    
    public func delete(path: String, parameters: [String: AnyObject]?, headers: [String: String]?, paramEncoding: ParamEncoding, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        sendAlamofireRequest(.DELETE, path: path, parameters: parameters, encoding: getAlamofireParamEncoding(paramEncoding), headers: headers, completionHandler: completion)
        return nil
    }
    
    public func performCustomCall(callClosure: APICommunicatorCustomCallClosure, progress: ProgressUpdateClosure?, completion: APICommunicatorCompletionClosure?) -> NSOperation? {
        callClosure(progress: progress, completion: completion)
        return nil
    }
    
    public func getAlamofireParamEncoding(ourEnconding: ParamEncoding) -> Alamofire.ParameterEncoding {
        switch ourEnconding {
        case ParamEncoding.URL:
            return Alamofire.ParameterEncoding.URL
        case ParamEncoding.JSON:
            return Alamofire.ParameterEncoding.JSON
        }
    }
}
