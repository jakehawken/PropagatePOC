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

}

enum TestError: Error, Equatable, CaseIterable {
    case case1
    case case2
    case case3
}
