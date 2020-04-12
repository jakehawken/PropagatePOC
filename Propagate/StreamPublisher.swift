//  StreamPublisher.swift
//  Propagate
//  Created by Jake Hawken on 4/5/20.
//  Copyright © 2020 Jake Hawken. All rights reserved.

import Foundation

public class StreamPublisher<DataModel, LEEOModel> {
    public typealias CancelBlock = ()->()
    
    public let subscriber: StreamSubscriber<DataModel, LEEOModel>
    
    public init() {
        subscriber = StreamSubscriber<DataModel, LEEOModel>()
    }
    
    public func publishNewState(_ state: StreamSubscriber<DataModel, LEEOModel>.State) {
        subscriber.emitNewState(state)
    }
    
    public func setCancelAction(cancelBlock: @escaping CancelBlock) {
        subscriber.setCancelBlock(cancelBlock: cancelBlock)
    }
}

// MARK: - Convenience methods

public extension StreamPublisher {
    
    func publishNewData(_ model: DataModel) {
        publishNewState(.newData(model))
    }
    
    func publishLEEO(_ model: LEEOModel) {
        publishNewState(.leeo(model))
    }
    
}
