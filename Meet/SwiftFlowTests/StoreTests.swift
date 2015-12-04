//
//  SwiftFlowTests.swift
//  SwiftFlowTests
//
//  Created by Benjamin Encz on 11/27/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import XCTest
@testable import SwiftFlow

struct TestAppState: StateType {
    var testValue: Int?

    init() {
        testValue = nil
    }
}

struct SetValueAction: ActionConvertible {

    let value: Int
    static let type = "SetValueAction"
    
    init (_ value: Int) {
        self.value = value
    }

    init(_ action: Action) {
        self.value = action.payload!["value"] as! Int
    }

    func toAction() -> Action {
        return Action(type: SetValueAction.type, payload: ["value": value])
    }

}

struct TestReducer: Reducer {
    func handleAction(var state: TestAppState, action: Action) -> TestAppState {
        switch action.type {
        case SetValueAction.type:
            state.testValue = SetValueAction(action).value
            return state
        default:
            abort()
        }
    }
}

class TestStoreSubscriber: StoreSubscriber {
    var receivedStates: [TestAppState] = []

    func newState(state: TestAppState) {
        receivedStates.append(state)
    }
}

class StoreTests: XCTestCase {

    var store: Store!
    var reducer: TestReducer!

    override func setUp() {
        super.setUp()

        reducer = TestReducer()
        store = MainStore(reducer: reducer, appState: TestAppState())
    }

    func testDispatchesInitialValueUponSubscription() {
        let expectation = expectationWithDescription("Sends initial value")
        store = MainStore(reducer: reducer, appState: TestAppState())
        let subscriber = TestStoreSubscriber()

        store.dispatch(SetValueAction(3)) { newState in
            if (subscriber.receivedStates.last?.testValue == 3) {
                expectation.fulfill()
            }
        }

        store.subscribe(subscriber)

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }

//    func testDoesNotDispatchValuesWhenUnsubscribed() {
//        let expectation = expectationWithDescription("Sends subsequent values")
//        store = MainStore(reducer: reducer, appState: TestAppState())
//        let subscriber = TestStoreSubscriber()
//
//        store.dispatch(setValueAction(5))
//        store.subscribe(subscriber)
//        store.dispatch(setValueAction(10))
//
//        // Let Run Loop Run so that dispatched actions can be performed
//        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
//
//        store.unsubscribe(subscriber)
//        // Following value is missed due to not being subscribed:
//        store.dispatch(TestAction.SetValue(15))
//        store.dispatch(TestAction.SetValue(25))
//
//        // Let Run Loop Run so that dispatched actions can be performed
//        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
//
//        store.subscribe(subscriber)
//
//        store.dispatch(TestAction.SetValue(20)) { newState in
//            if (subscriber.receivedStates[subscriber.receivedStates.count - 1].testValue == 20
//                && subscriber.receivedStates[subscriber.receivedStates.count - 2].testValue == 25
//                 && subscriber.receivedStates[subscriber.receivedStates.count - 3].testValue == 10) {
//                    expectation.fulfill()
//            }
//        }
//
//        waitForExpectationsWithTimeout(2.0, handler: nil)
//    }

}
