//
//  APIRequestOperation.swift
//
//  Created by Vojta Stavik on 02/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData


public enum HTTPMethod : CustomStringConvertible {
    
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case NONE
    
    public var description: String {
        
        switch self {
            
        case .GET:      return "GET"
        case .POST:     return "POST"
        case .PUT:      return "PUT"
        case .PATCH:    return "PATCH"
        case .DELETE:   return "DELETE"
        case .NONE:     return "NONE"
            
        }
    }
}

//: TODO add more encodings
public enum ParamEncoding: CustomStringConvertible
{
    case JSON
    case URL
    
    public var description: String
    {
    
        switch self
        {
        case .JSON:
            return "GET"
        case .URL:
            return "POST"
        }
    }

}


public typealias APIRequestCompletionClosure = (responseObject: JSON?, error: APICommunicatorError?) -> Void
public typealias APIRequestDataHandlerClosure = (responseObject: JSON?, error: APICommunicatorError?, context: NSManagedObjectContext?) -> Void
public typealias APIRequestOperationIdentifier = String

public class APIRequestOperation : NSOperation {
    
    /**
    If nil, dataHandler is automatically called when request is finished. If you implement this, don't forget to call dataHandler manually. Defaul is nil.
    */
    public var requestCompletionClosure : APIRequestCompletionClosure? = nil
    public var dataHandler : APIRequestDataHandlerClosure? = nil
    
    public var didFinishiWithErrorClosure : ((APICommunicatorError?) -> Void)? = nil
    
    public var parameters : [String: AnyObject]? = nil
    public var headers : [String: String]? = nil
    
    public var futureParameters : [String: Future]? = nil
    public var futureHeaders : [String: ([APIRequestOperationIdentifier : JSON]) -> String]? = nil
    
    public var paramEncoding : ParamEncoding
    
    public var activityIndicator: APIActivityIndicator? = nil
        {
            didSet
            {
                copyOperationReference?.activityIndicator = activityIndicator
            }
        }
    
    
    public var context : NSManagedObjectContext? = nil
    
    public var copyNumber = 0
    
    public var sharedUserInfo = UserInfoDictionary()
    public var communicatorError: APICommunicatorError? = nil
    
    lazy public var identifier : APIRequestOperationIdentifier =
        {
            return self.randomStringWithLength(15)
        }()
    
    
    let communicator : APICommunicator
    let method : HTTPMethod
    let path : String
    
    
    //for custom calls
    var communicatorExecClosure : APICommunicatorCustomCallClosure?
    
    public init(communicator: APICommunicator, path: String, method: HTTPMethod, paramEncoding : ParamEncoding? = ParamEncoding.JSON) {
        
        self.communicator = communicator
        self.method = method
        self.path = path
        self.paramEncoding = paramEncoding ?? .JSON
        self.communicatorExecClosure = nil
        super.init()
    }
    
    public init(communicator: APICommunicator, communicatorExecClosure : APICommunicatorCustomCallClosure)
    {
        self.communicator = communicator
        self.method = .NONE
        self.path = ""
        self.paramEncoding = .JSON
        self.communicatorExecClosure = communicatorExecClosure
    }
    
    var currentApiCommunicatorOperation : NSOperation? = nil
    
    public override func start()
    {

        executing = true
        
        // evaluate future headers and parameters
        if let futureHeaders = futureHeaders
        {
            headers = headers ?? [String:String]()
            
            for (key, value) in futureHeaders
            {
                headers![key] = value(sharedUserInfo.data)
            }
        }
        
        if let futureParameters = futureParameters
        {
            parameters = parameters ?? [String:String]()
            
            for (key, value) in futureParameters
            {
                parameters![key] = value()
            }
        }
        
        
        //custom exectuion cloasure
        if(self.communicatorExecClosure != nil)
        {
            self.currentApiCommunicatorOperation = communicator.performCustomCall(self.communicatorExecClosure!, completion: innerCompletion)
        }
        else
        {
            switch method
            {
                
            case .GET:
                currentApiCommunicatorOperation = communicator.get(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, completion: innerCompletion)
                
            case .POST:
                currentApiCommunicatorOperation = communicator.post(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, completion: innerCompletion)
                
            case .PUT:
                currentApiCommunicatorOperation = communicator.put(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, completion: innerCompletion)
                
            case .PATCH:
                currentApiCommunicatorOperation = communicator.patch(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, completion: innerCompletion)
                
            case .DELETE:
                currentApiCommunicatorOperation = communicator.delete(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, completion: innerCompletion)
            case .NONE:
                break
            }
        }


    }
    
    
    lazy var innerCompletion : APICommunicatorCompletionClosure = { [weak self] responseObject , error -> Void in
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
                guard let responseObject = responseObject else {
                    
                    if let requestCompletionClosure = self?.requestCompletionClosure {
                        
                        requestCompletionClosure(responseObject: nil, error: error)
                        
                    } else {
                        
                        self?.dataHandler?(responseObject: nil, error: error, context: self?.context)
                    }
                    
                    self?.didFinishiWithErrorClosure?(error)
                    
                    self?.communicatorError = error
                    self?.finish()
                    
                    return
                }
                
                guard let aSelf = self else { return }
                
                if let requestCompletionClosure = aSelf.requestCompletionClosure {
                    
                    requestCompletionClosure(responseObject: responseObject, error: nil)
                    
                } else {
                    
                    aSelf.dataHandler?(responseObject: responseObject, error: nil, context: aSelf.context)
                }
                
                aSelf.sharedUserInfo[aSelf.identifier] = responseObject
                
                aSelf.finish()
                aSelf.communicatorError = error

            }
    }
    
    
    func finish() {
        
        executing = false
        finished = true
        
        releaseReferences()
    }
    
    
    func releaseReferences()
    {
        futureParameters = nil
        futureHeaders = nil
        communicatorExecClosure = nil
    }
    
    public override func cancel() {
        
        super.cancel()
        currentApiCommunicatorOperation?.cancel()
        
        releaseReferences()
    }

    
    // MARK: - NSOperation
    
    override public var concurrent : Bool  {
        return true
    }
    
    
    public override func addDependency(op: NSOperation) {
        
        super.addDependency(op)
        
        if let previousRequestOperation = op as? APIRequestOperation
        {
            sharedUserInfo = previousRequestOperation.sharedUserInfo
        }
    }

    
    override public var executing : Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    
    private var _executing : Bool = false
    
    
    public override var finished : Bool {
        
        get { return _finished }
        
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    private var _finished : Bool = false
    
    // we want to pass some data to our copy even after we create it -> activity indicator
    private weak var copyOperationReference : APIRequestOperation? = nil
}


extension APIRequestOperation : NSCopying {
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        
        let copy = APIRequestOperation(communicator: communicator, path: path, method: method)
        
        copy.requestCompletionClosure = requestCompletionClosure
        copy.dataHandler = dataHandler
        
        copy.activityIndicator = activityIndicator
        
        copy.didFinishiWithErrorClosure = didFinishiWithErrorClosure
        copy.communicatorExecClosure = communicatorExecClosure
        
        copy.parameters = parameters
        copy.headers = headers
        
        copy.context = context
        copy.sharedUserInfo = sharedUserInfo
        
        copy.copyNumber = copyNumber + 1
        self.copyOperationReference = copy
        
        return copy
    }
}


// we need a class for this because we want to share
// this object between api operations
public class UserInfoDictionary  {
    
    public subscript(key: APIRequestOperationIdentifier) -> JSON?
        {
            get
            {
                return data[key]
            }
        
            set (newValue)
            {
                data[key] = newValue
            }
        }
    
    var data = [APIRequestOperationIdentifier : JSON]()
}


extension APIRequestOperation
{
    func randomStringWithLength(len : Int) -> String {
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString = ""
        
        for _ in 0...len {
            
            let rand = Int(arc4random_uniform(UInt32(letters.characters.count)))
            randomString.append(letters[rand])
        }
        
        return randomString
    }
}


extension String
{
    subscript (i: Int) -> Character
        {
            return self[self.startIndex.advancedBy(i) ]
    }
    
    subscript (i: Int) -> String
        {
            return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String
        {
            return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}



public extension APIRequestOperation {
    
    public typealias Future = () -> AnyObject?
    
    public func future(closure: (JSON -> AnyObject?)) -> Future {
        
        return { [weak self] () -> AnyObject? in
            
            if let
                aSelf = self,
                data = self?.sharedUserInfo[aSelf.identifier]
            {
                return closure(data)
                
            } else {
                
                return nil
            }
        }
    }
}

