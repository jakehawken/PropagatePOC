//  StreamState.swift
//  Propagate
//  Created by Jacob Hawken on 2/17/22.
//  Copyright © 2022 Jake Hawken. All rights reserved.

import Foundation

public enum StreamState<T, E: Error>: CustomStringConvertible {
    case data(T)
    case error(E)
    case cancelled
    
    public var description: String {
        switch self {
        case .data(let data): return "<.data(\(data))>"
        case .error(let error): return "<.error(\(error))>"
        case .cancelled: return "<.cancelled>"
        }
    }
}

extension StreamState: Equatable where T: Equatable, E: Equatable {
    
}
