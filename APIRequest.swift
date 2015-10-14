//
//  APIRequest.swift
//
//  Created by Vojta Stavik on 24/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import CoreData

public typealias APIRequest = Array<NSOperation>

public extension Array where Element : NSOperation
{
    public func addToAPIQueue() -> APIRequest
    {
        if let last = last
        {
            _ = chainOperation(last) // chain all operations
        }
        
        for operation in self
        {
            if let queue = MainAPIQueue.queue {
             
                queue.addOperation(operation)

            } else {
                
                print("APICommunicator: WARNING! MainAPIQueue.queue is nil.")
            }
        }
        
        return self
    }
    
    
    mutating public func activityIndicator(indicator: APIActivityIndicator) -> APIRequest
    {
        let activityStartedOperation = NSBlockOperation()
                                            {
                                                dispatch_async(dispatch_get_main_queue())
                                                    {
                                                        indicator.apiCallStarted()
                                                    }

                                            } as! Element
        
        
        let activityFinishedOperation  = NSBlockOperation()
                                            {
                                                var errors = [APICommunicatorError]()
                                                
                                                for operation in self
                                                {
                                                    if let error = (operation as? APIRequestOperation)?.communicatorError
                                                    {
                                                        errors.append(error)
                                                    }
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue())
                                                    {
                                                         indicator.apiCallFinished(errors)
                                                    }
                                                
                                            } as! Element

        for operation in self
        {
            // I need to save the indicator reference somewhere
            // for renewing token request.
            // I would either create subbclass of Array (stupid) or
            // solve it this way. I'm not happy about this but I can't
            // find any other solution now
            (operation as? APIRequestOperation)?.activityIndicator = indicator
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
                (operation as? APIRequestOperation)?.context = context
            }
        }

        get
        {
            return (self.first as? APIRequestOperation)?.context
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
                            if let error = (operation as? APIRequestOperation)?.communicatorError
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
    
//    
//    private func last() -> Generator.Element?
//    {
//        if self.isEmpty
//        {
//            return nil
//        }
//        
//        return self[count - 1]
//    }
}


