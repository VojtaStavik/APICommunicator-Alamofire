//
//  Future.swift
//
//  Created by Vojta Stavik on 04/11/15.
//
//

import Foundation

public struct Future<T> {

    public init(futureClosure: () -> T?) {
        
        self.futureClosure = futureClosure
    }
    
    public var value : T? { return futureClosure() }
    
    private let futureClosure : () -> T?
}



public protocol FutureEvaluatable {
    
    var evaluate : Any? { get }
}


extension Future : FutureEvaluatable {
    
    public var evaluate : Any? {
        
        return self.value
    }
}


public func + <T> (left: Future<Array<T>>, right: Future<Array<T>>) -> Future<Array<T>> {
    
    return Future {
        
        guard let
            leftValue = left.value,
            rightValue = right.value
            else { return nil }
        
        return leftValue + rightValue
    }
}



public extension APIRequestOperation {
    
    public func future<T>(closure: (ResponseDataType -> T?)) -> Future<T> {
        
        return Future { [weak self] () -> T? in
            
            if let
                aSelf = self,
                data = self?.sharedUserInfo[aSelf.identifier] as? ResponseDataType
            {
                return closure(data)
                
            } else {
                
                return nil
            }
        }
    }
}

