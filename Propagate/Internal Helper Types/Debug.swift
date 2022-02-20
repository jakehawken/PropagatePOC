//  Debug.swift
//  Propagate
//  Created by Jacob Hawken on 2/19/22.
//  Copyright © 2022 Jake Hawken. All rights reserved.

import Foundation

internal var debugLoggingEnabled = false

func safePrint(_ message: String) {
    guard debugLoggingEnabled else {
        return
    }
    print("<>DEBUG: " + message)
}

internal func memoryAddressStringFor(_ obj: AnyObject) -> String {
    return "\(Unmanaged.passUnretained(obj).toOpaque())"
}
