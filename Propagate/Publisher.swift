//  StreamPublisher.swift
//  Propagate
//  Created by Jake Hawken on 4/5/20.
//  Copyright © 2020 Jake Hawken. All rights reserved.

import Foundation

public class Publisher<T, E: Error> {
    
    public typealias State = StreamState<T, E>
    
    private let lockQueue = DispatchQueue(label: "PublisherLockQueue-\(UUID().uuidString)")
    private var subscribers = WeakBag<Subscriber<T, E>>()
    private(set) public var isCancelled = false
    
    public init() {}
    
    internal func publishNewState(_ state: State) {
        lockQueue.async { [weak self] in
            guard let self = self, !self.isCancelled else {
                return
            }
            self.subscribers.forEach { $0.receive(state) }
        }
    }
    
    deinit {
        safePrint("Releasing \(self) from memory.")
        cancelAll()
    }
    
}

// MARK: debugging

extension Publisher: CustomStringConvertible {
    
    public var description: String {
        return "Publisher(\(memoryAddressStringFor(self)))"
    }
    
}

// MARK: - Main interface

public extension Publisher {
    
    func subscriber() -> Subscriber<T, E> {
        let canceller = Canceller<T,E> { [weak self] subscriber in
            self?.subscribers.pruneIf { $0 === subscriber }
        }
        let newSub = Subscriber(canceller: canceller)
        lockQueue.async { [weak self] in
            self?.subscribers.insert(newSub)
        }
        safePrint("Generating new subscriber: \(newSub) on publisher \(self)")
        return newSub
    }
    
    func publish(_ model: T) {
        publishNewState(.data(model))
    }
    
    func publish(_ error: E) {
        publishNewState(.error(error))
    }
    
    func cancelAll() {
        isCancelled = true
        let removedSubscribers = subscribers.removeAll()
        safePrint("Removing subscribers: \(removedSubscribers)")
        lockQueue.async {
            removedSubscribers.forEach {
                $0.receive(.cancelled)
            }
        }
    }
    
}

// MARK: - Supporting Types

internal class Canceller<T, E: Error> {
    
    private var cancelAction: ((Subscriber<T,E>) -> Void)?
    
    fileprivate init(cancelAction: @escaping (Subscriber<T,E>) -> Void) {
        self.cancelAction = cancelAction
    }
    
    internal func cancel(for subscriber: Subscriber<T,E>) {
        guard let action = cancelAction else {
            return
        }
        cancelAction = nil
        action(subscriber)
        subscriber.receive(.cancelled)
    }
    
}
