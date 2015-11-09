//
//  APIRequestOperation.swift
//
//  Created by Vojta Stavik on 02/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData


public enum HTTPMethod : String {
    
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case NONE
}


//: TODO add more encodings
public enum ParamEncoding: String {
    
    case JSON
    case URL
}


public protocol APIResponseSerializer {
    
    static func serializeResponse(responseData: NSData?) -> Self?
}


public typealias APIRequestOperationIdentifier = String

public class APIRequestOperation<T: APIResponseSerializer> : NSOperation {

    public typealias ResponseDataType = T
    
    public typealias CompletionClosure = (responseObject: ResponseDataType?, error: APICommunicatorError?) -> Void
    public typealias DataHandlerClosure = (responseObject: ResponseDataType?, error: APICommunicatorError?, context: NSManagedObjectContext?) -> Void
    
    /**
    If nil, dataHandler is automatically called when request is finished. If you implement this, don't forget to call dataHandler manually. Defaul is nil.
    */
    public var requestCompletionClosure : CompletionClosure? = nil
    public var dataHandler : DataHandlerClosure? = nil
    
    public var didFinishiWithErrorClosure : ((APICommunicatorError?) -> Void)? = nil
    
    public var parameters : [String: AnyObject]? = nil
    public var headers : [String: String]? = nil
    
    public var futureParameters : [String: FutureEvaluatable]? = nil
    public var futureHeaders : [String: ([APIRequestOperationIdentifier : APIResponseSerializer]) -> String]? = nil
    
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
    
    public var currentProgress : Float = 0 {
        
        didSet {
            
            updateProgressClosure?(currentProgress: currentProgress)
        }
    }
    
    public var sharedUserInfo = UserInfoDictionary()
    public var communicatorError: APICommunicatorError? = nil
    
    public var updateProgressClosure : ((currentProgress: Float) -> ())?
    
    lazy public var identifier : APIRequestOperationIdentifier =
        {
            return self.randomStringWithLength(15)
        }()
    
    
    let communicator : APICommunicator
    let method : HTTPMethod
    let path : String
    let customCallClosure : APICommunicatorCustomCallClosure?
    
    
    public init(communicator: APICommunicator, path: String, method: HTTPMethod, paramEncoding : ParamEncoding? = ParamEncoding.JSON) {
        
        self.communicator = communicator
        self.method = method
        self.path = path
        self.paramEncoding = paramEncoding ?? .JSON
        self.customCallClosure = nil
        super.init()
    }
    
    public init(communicator: APICommunicator, customCallClosure : APICommunicatorCustomCallClosure)
    {
        self.communicator = communicator
        self.method = .NONE
        self.path = ""
        self.paramEncoding = .JSON
        self.customCallClosure = customCallClosure
    }
    
    var currentApiCommunicatorOperation : NSOperation? = nil
    
    public override func start()
    {

        executing = true
        currentProgress = 0
        
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
            parameters = parameters ?? [String:AnyObject]()
            
            for (key, value) in futureParameters
            {
                if let object = value.evaluate as? AnyObject {
                    
                    parameters![key] = object
                }
            }
        }
        
        

        // progress closure
        let updateProgress : ProgressUpdateClosure = { [weak self] progress in
        
            self?.currentProgress = progress
        }
        
        
        if let customCallClosure = customCallClosure {
        
            // Execute custom call closure if any
            self.currentApiCommunicatorOperation = communicator.performCustomCall(customCallClosure, progress: updateProgress, completion: innerCompletion)
        }
            
        else {
            
            switch method {
                
            case .GET:
                currentApiCommunicatorOperation = communicator.get(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, progress: updateProgress, completion: innerCompletion)
                
            case .POST:
                currentApiCommunicatorOperation = communicator.post(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, progress: updateProgress, completion: innerCompletion)
                
            case .PUT:
                currentApiCommunicatorOperation = communicator.put(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, progress: updateProgress, completion: innerCompletion)
                
            case .PATCH:
                currentApiCommunicatorOperation = communicator.patch(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, progress: updateProgress, completion: innerCompletion)
                
            case .DELETE:
                currentApiCommunicatorOperation = communicator.delete(path, parameters: parameters, headers: headers, paramEncoding: paramEncoding, progress: updateProgress, completion: innerCompletion)
            case .NONE:
                break
            }
        }


    }
    
    
    lazy var innerCompletion : APICommunicatorCompletionClosure = { [weak self] responseObject , error -> Void in
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
                if let
                    serializedData = T.serializeResponse(responseObject),
                    aSelf = self
                {
                    aSelf.sharedUserInfo[aSelf.identifier] = serializedData
                }
                
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
                    
                    requestCompletionClosure(responseObject: T.serializeResponse(responseObject), error: nil)
                    
                } else {
                    
                    aSelf.dataHandler?(responseObject:  T.serializeResponse(responseObject), error: nil, context: aSelf.context)
                }
                
                aSelf.finish()
                aSelf.communicatorError = error

            }
    }
    
    
    func finish() {
        
        currentProgress = 1
        
        executing = false
        finished = true
        
        releaseReferences()
    }
    
    
    func releaseReferences() {
        
        futureParameters = nil
        futureHeaders = nil
    }
    
    
    public override func cancel() {
        
        super.cancel()
        currentApiCommunicatorOperation?.cancel()

        currentProgress = 1
        
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


// TODO: How to implement NSCopying for generic class?
extension APIRequestOperation {
    
    public func copyOperation() -> APIRequestOperation<ResponseDataType> {
        
        let copy : APIRequestOperation<ResponseDataType>
        
        if let customCallClosure = customCallClosure {
            
            copy = APIRequestOperation<ResponseDataType>(communicator: communicator, customCallClosure: customCallClosure)
            
        } else {
            
            copy = APIRequestOperation<ResponseDataType>(communicator: communicator, path: path, method: method)
        }
        
        copy.requestCompletionClosure = requestCompletionClosure
        copy.dataHandler = dataHandler
        
        copy.activityIndicator = activityIndicator
        
        copy.didFinishiWithErrorClosure = didFinishiWithErrorClosure
        
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
    
    public subscript(key: APIRequestOperationIdentifier) -> APIResponseSerializer?
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
    
    var data = [APIRequestOperationIdentifier : APIResponseSerializer]()
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





// A protocol defining APIRequestOperation public interface
// it's used for accessing non-generic values 

public protocol APIRequestOperationProtocol {
    
    var activityIndicator: APIActivityIndicator?     { set get }
    var context : NSManagedObjectContext?            { set get }
    var communicatorError: APICommunicatorError?     { set get }
    var copyNumber: Int                                  { get }
    var updateProgressClosure : ((currentProgress: Float) -> ())? { set get }
}

extension APIRequestOperation : APIRequestOperationProtocol { }

