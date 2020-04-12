//  StreamSubscriber.swift
//  Propagate
//  Created by Jake Hawken on 4/5/20.
//  Copyright © 2020 Jake Hawken. All rights reserved.

import Foundation

public class StreamSubscriber<DataModel, LEEOModel> { //LEEO stands for "loading, empty, error, & offline"
    public typealias Callback = (State) -> ()
    public typealias CancelBlock = ()->()
    
    public enum State {
        case newData(DataModel)
        case leeo(LEEOModel)
        case cancelled
    }
    
    private let callbackList: SinglyLinkedList<Callback>
    private let lockQueue = DispatchQueue(label: "StreamSubscriberLockQueue-\(UUID().uuidString)")
    internal var callbackQueue: DispatchQueue?
    
    private var cancelAction: CancelBlock?
    private(set) var lastState: State?
    
    internal init() {
        self.callbackList = SinglyLinkedList(firstValue:{(_) in})
    }
    
    var shouldForceCallbacksToMainThread = false
    
    func onNext(_ callback: @escaping Callback) {
        lockQueue.sync {
            if let last = lastState {
                callback(last)
            }
            callbackList.append(callback)
        }
    }
    
    func removeAllCallbacks() {
        lockQueue.sync {
            callbackList.trimToRoot()
        }
    }
    
    func cancelStream() {
        lockQueue.sync {
            emitState(.cancelled)
            cancelAction?()
            callbackList.trimToRoot()
        }
    }
    
    internal func setCancelBlock(cancelBlock: @escaping CancelBlock) {
        cancelAction = cancelBlock
    }
    
    private func emitState(_ newState: State) {
        callbackList.forEach { (callback) in
            if let callbackQueue = callbackQueue {
                callbackQueue.sync {
                    callback(newState)
                }
            }
            else {
                callback(newState)
            }
        }
        lastState = newState
    }
    
    internal func emitNewState(_ newState: State) {
        lockQueue.sync {
            emitState(newState)
        }
    }
    
}

// MARK: - Mapping extensions

extension StreamSubscriber.State {
    
    func mapDataModel<T>(mapBlock: (DataModel)->T) -> StreamSubscriber<T, LEEOModel>.State {
        switch self {
        case .newData(let dataModel):
            let mappedModel = mapBlock(dataModel)
            return .newData(mappedModel)
        case .leeo(let leeoModel):
            return .leeo(leeoModel)
        case .cancelled:
            return .cancelled
        }
    }
    
    func mapLEEOModel<E>(mapBlock: (LEEOModel)->E) -> StreamSubscriber<DataModel, E>.State {
        switch self {
        case .newData(let dataModel):
            return .newData(dataModel)
        case .leeo(let leeoModel):
            let mappedLeeo = mapBlock(leeoModel)
            return .leeo(mappedLeeo)
        case .cancelled:
            return .cancelled
        }
    }
    
}

//MARK: - transformation methods

public extension StreamSubscriber {
    
    func map<T, E>(mapBlock: @escaping (StreamSubscriber.State)->StreamSubscriber<T,E>.State) -> StreamSubscriber<T,E> {
        let subscriber = StreamSubscriber<T,E>()
        onNext { (state) in
            let newState = mapBlock(state)
            subscriber.emitNewState(newState)
        }
        return subscriber
    }
    
    func flatMap<T, E>(mapBlock: @escaping (StreamSubscriber.State)->StreamSubscriber<T,E>.State?) -> StreamSubscriber<T,E> {
        let subscriber = StreamSubscriber<T,E>()
        onNext { (state) in
            if let newState = mapBlock(state) {
                subscriber.emitNewState(newState)
            }
        }
        return subscriber
    }
    
    func mapData<T>(mapBlock: @escaping (DataModel)->T) -> StreamSubscriber<T, LEEOModel> {
        let subscriber = StreamSubscriber<T, LEEOModel>()
        onNext { (state) in
            let mappedState = state.mapDataModel(mapBlock: mapBlock)
            subscriber.emitNewState(mappedState)
        }
        return subscriber
    }
    
    func mapLEEO<E>(mapBlock: @escaping (LEEOModel)->E) -> StreamSubscriber<DataModel, E> {
        let subscriber = StreamSubscriber<DataModel, E>()
        onNext { (state) in
            let mappedState = state.mapLEEOModel(mapBlock: mapBlock)
            subscriber.emitNewState(mappedState)
        }
        return subscriber
    }
    
}
