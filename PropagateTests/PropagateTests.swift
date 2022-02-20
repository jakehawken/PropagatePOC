//
//  PropagateTests.swift
//  PropagateTests
//
//  Created by Jake Hawken on 4/5/20.
//  Copyright © 2020 Jake Hawken. All rights reserved.
//

import XCTest
import Propagate

class PropagateTests: XCTestCase {
    
    var subject: Publisher<Int, TestError>!
    var subscriber1: Subscriber<Int, TestError>!
    var subscriber2: Subscriber<Int, TestError>!
    var subscriber3: Subscriber<Int, TestError>!

    override func setUp() {
        subject = Publisher()
    }

    override func tearDown() {
        subscriber1 = nil
        subscriber2 = nil
        subscriber3 = nil
        subject = nil
    }

    func testPublisherGeneratesCorrectlyConnectedSubscriber() {
        let expectation1 = expectation(description: "All values published.")
        var subscriptionValues = [Int]()
        let valuesToEmit = [4, 2, 7, 1, 8]
        
        subscriber1 = subject.subscriber()
            .onNewData(onQueue: .main) { value in
                subscriptionValues.append(value)
                if valuesToEmit.last == value {
                    expectation1.fulfill()
                }
            }
        
        
        valuesToEmit.forEach {
            subject.publish($0)
        }
        
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(subscriptionValues, valuesToEmit)
        
        var errors = [TestError]()
        
        let expectation2 = expectation(description: "Error received.")
        subscriber1.onError { error in
            errors.append(error)
            if TestError.allCases.last == error {
                expectation2.fulfill()
            }
        }
        
        TestError.allCases.forEach {
            subject.publish($0)
        }
        
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(errors, TestError.allCases)
        
        let cancelExpectation = expectation(description: "Should receive cancel signal.")
        subscriber1.onCancelled {
            cancelExpectation.fulfill()
        }
        
        subject.cancelAll()
        subject.publish(249)
        subject.publish(.case1)
        waitForExpectations(timeout: 0.01, handler: nil)
        // Verify that no attempted emissions succeed after cancellation
        XCTAssertEqual(subscriptionValues, valuesToEmit)
        XCTAssertEqual(errors, TestError.allCases)
    }
    
    func testMultipleSubscribersGetUpdates() {
        let statesToSend: [StreamState<Int, TestError>] = [
            .data(0), .error(.case1), .data(2), .error(.case2),
            .data(4), .error(.case3), .cancelled, .data(1)
        ]
        let expectedStates: [StreamState<Int, TestError>] = [
            .data(0), .error(.case1), .data(2), .error(.case2),
            .data(4), .error(.case3), .cancelled
        ]
        
        var subscriber1ReceivedStates = [StreamState<Int, TestError>]()
        subscriber1 = subject.subscriber().subscribe {
            subscriber1ReceivedStates.append($0)
        }
        
        var subscriber2ReceivedStates = [StreamState<Int, TestError>]()
        subscriber2 = subject.subscriber().subscribe {
            subscriber2ReceivedStates.append($0)
        }
        
        var subscriber3ReceivedStates = [StreamState<Int, TestError>]()
        subscriber3 = subject.subscriber().subscribe {
            subscriber3ReceivedStates.append($0)
        }
        
        statesToSend.forEach { state in
            switch state {
            case let .data(data):
                subject.publish(data)
            case let .error(error):
                subject.publish(error)
            case .cancelled:
                subject.cancelAll()
            }
        }
        
        sleep(1)
        XCTAssertEqual(subscriber1ReceivedStates, expectedStates)
        XCTAssertEqual(subscriber2ReceivedStates, expectedStates)
        XCTAssertEqual(subscriber3ReceivedStates, expectedStates)
    }
    
    func testPublishserBeingReleasedFromMemoryTriggersCancellation() {
        let expectations = (1...3).map { expectation(description: "Should cancel for subscriber\($0).") }
        subscriber1 = subject.subscriber().onCancelled {
            expectations[0].fulfill()
        }
        subscriber2 = subject.subscriber().onCancelled {
            expectations[1].fulfill()
        }
        subscriber3 = subject.subscriber().onCancelled {
            expectations[2].fulfill()
        }
        subject = nil
        wait(for: expectations, timeout: 1)
    }

}

enum TestError: Error, Equatable, CaseIterable {
    case case1
    case case2
    case case3
}
