//
//  APIAdapter.swift
//
//  Created by Vojta Stavik on 29/09/15.
//  Copyright © 2015 STRV. All rights reserved.
//

import Foundation

public protocol APIAdapter
{
    static var communicator : APICallsFactory { get }
}
