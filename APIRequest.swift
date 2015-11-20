//
//  APIRequest.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import CoreData

public typealias APIRequest = Array<NSOperation>

public extension Array where Element : NSOperation {
    
    public func addToAPIQueue(queue: NSOperationQueue? = MainAPIQueue.queue, cancelOtherRequestsWithTheSameType: Bool = false) {
        
        if let last = last {
            
            _ = chainOperation(last) // chain all operations
        }
        
        
        guard let queue = queue
            else {
                
                print("APICommunicator: WARNING! MainAPIQueue.queue is nil.")
                return
        }
        
        
        if let requestIdentifier = self.requestIdentifier where cancelOtherRequestsWithTheSameType {
            
            queue.operations.flatMap { $0 as? APIRequestOperationProtocol }
                            .filter  { $0.requestIdentifier == requestIdentifier }
                            .forEach { $0.cancel() }
        }
        
        
        queue.addOperations(self, waitUntilFinished: false)
    }
    
    
    mutating public func activityIndicator(indicator: APIActivityIndicator?) -> APIRequest
    {
        let apiOperations = self.filter{ $0 is APIRequestOperationProtocol}
        
        let numberOfOperations = apiOperations.count
        let step : Float = 1/Float(numberOfOperations)
        
        for (index, operation) in apiOperations.enumerate() {
            
            let completedPart = Float(index) * step
            
            var mutableOperation = operation as? APIRequestOperationProtocol
        
            mutableOperation?.updateProgressClosure = { progress in
                
                indicator?.apiCallProgressUpdated(completedPart + progress * step)
            }
        }
        
        
        
        let activityStartedOperation = NSBlockOperation()
                                            {
                                                dispatch_async(dispatch_get_main_queue())
                                                    {
                                                        indicator?.apiCallStarted()
                                                    }

                                            } as! Element
        
        
        let activityFinishedOperation  = NSBlockOperation()
                                            {
                                                var errors = [APICommunicatorError]()
                                                
                                                for operation in self
                                                {
                                                    if let error = (operation as? APIRequestOperationProtocol)?.communicatorError
                                                    {
                                                        errors.append(error)
                                                    }
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue())
                                                    {
                                                         indicator?.apiCallFinished(errors)
                                                    }
                                                
                                            } as! Element

        for operation in self
        {
            // I need to save the indicator reference somewhere
            // for renewing token request.
            // I would either save it as an associate object (bleh) or
            // solve it this way. I'm not happy about this but I can't
            // find any other solution now
            var mutableOperation = operation as? APIRequestOperationProtocol
            mutableOperation?.activityIndicator = indicator
        }
        
        self = [activityStartedOperation] + self + [activityFinishedOperation]

        return self
    }

    
    public var context : NSManagedObjectContext?
    {
        set
        {
            for operation in self
            {
                var mutableOperation = operation as? APIRequestOperationProtocol
                mutableOperation?.context = context
            }
        }

        get
        {
            return (self.first as? APIRequestOperationProtocol)?.context
        }
    }


    public var requestIdentifier : String? {
        
        set {
            
            forEach {
                
                var mutableOperation = $0 as? APIRequestOperationProtocol
                mutableOperation?.requestIdentifier = newValue
            }
        }
        
        get {
            
            return self.flatMap{ $0 as? APIRequestOperationProtocol }.first?.requestIdentifier
        }
    }
    
    
    mutating public func addBlockOperation(operation: (() -> Void))
    {
        append(NSBlockOperation(block: operation) as! Element)
    }
    
    
    mutating public func completionOperation(block: (([APICommunicatorError] -> Void)))
    {
        append(NSBlockOperation()
                    {
                        
                        var errors = [APICommunicatorError]()
                        
                        for operation in self
                        {
                            if let error = (operation as? APIRequestOperationProtocol)?.communicatorError
                            {
                                errors.append(error)
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            block(errors)
                        }
                        
                        
                    } as! Element
        )
    }
    
    
    public func copy() -> APIRequest
    {
        var requestCopy = [NSOperation]()
        
        for operation in self
        {
            requestCopy.append(operation.copy() as! Element)
        }
        
        return requestCopy
    }
    
    
    public func cancel() {
        
        forEach { $0.cancel() }
    }
    
    
    // Private
    
    func chainOperation(operation: NSOperation) -> NSOperation
    {
        if let previous = previousOperation(operation)
        {
            operation.addDependency(chainOperation(previous))
        }
        
        return operation
    }
    
    
    func previousOperation(operation: NSOperation?) -> NSOperation?
    {
        guard let operation = operation else { return nil }
        
        let index = indexOf { $0 === operation }!
        
        if index == self.startIndex
        { return nil }
        else
        { return self[index.predecessor()] }
    }
}




