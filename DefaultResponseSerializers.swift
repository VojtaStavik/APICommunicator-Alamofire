//
//  DefaultResponseSerializers.swift
//  Ripple
//
//  Created by Vojta Stavik on 27/10/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON : APIResponseSerializer {
    
    public static func serializeResponse(responseData: NSData?) -> JSON? {
        
        guard let data = responseData else { return nil }
        
        var error : NSError?
        let json = JSON(data: data, options: .AllowFragments, error: &error)
        if let error = error {
            
            print("EROR while JSON parsing: \(error.localizedDescription)")
        }
        
        return json
    }
}



extension Array : APIResponseSerializer {
    
    public static func serializeResponse(responseData: NSData?) -> Array? {
        
        guard let data = responseData else { return nil }
        
        // TODO: Needs proper testing
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Array<Element>
    }
}



extension String : APIResponseSerializer {
    
    public static func serializeResponse(responseData: NSData?) -> String? {
        
        guard let data = responseData else { return nil }
        
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
}