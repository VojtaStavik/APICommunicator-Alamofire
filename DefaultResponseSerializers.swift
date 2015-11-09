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
            
        return JSON(data: data)
    }
}



extension Array : APIResponseSerializer {
    
    public static func serializeResponse(responseData: NSData?) -> Array? {
        
        guard let data = responseData else { return nil }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Array<Element>
    }
}