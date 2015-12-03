//
//  SwiftFlowRouterUnitTests.swift
//  Meet
//
//  Created by Benjamin Encz on 12/2/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Quick
import Nimble

import SwiftFlow
@testable import SwiftFlowRouter

class SwiftFlowRouterUnitTests: QuickSpec {

    override func spec() {
        describe("routing calls") {

            let tabBarViewControllerIdentifier = "TabBarViewController"
            let counterViewControllerIdentifier = "CounterViewController"
            let statsViewControllerIdentifier = "StatsViewController"

            it("can derive steps from an empty route to a multi segment route") {
                let oldRoute: [RouteElementIdentifier] = []
                let newRoute = [tabBarViewControllerIdentifier, statsViewControllerIdentifier]

                let routingActions = Router.routingActionsForTransitionFrom(oldRoute,
                    newRoute: newRoute)

                var action1Correct: Bool?
                var action2Correct: Bool?

                if case let RoutingActions.Push(responsibleRoutableIndex, segmentToBePushed)
                    = routingActions[0] {

                        if responsibleRoutableIndex == 0
                            && segmentToBePushed == tabBarViewControllerIdentifier {
                                action1Correct = true
                        }
                }

                if case let RoutingActions.Push(responsibleRoutableIndex, segmentToBePushed)
                    = routingActions[1] {

                        if responsibleRoutableIndex == 1
                            && segmentToBePushed == statsViewControllerIdentifier {
                            action2Correct = true
                        }
                }

                expect(routingActions).to(haveCount(2))
                expect(action1Correct).to(beTrue())
                expect(action2Correct).to(beTrue())
            }

            it("generates a Change action on the last common subroute") {
                let oldRoute = [tabBarViewControllerIdentifier, counterViewControllerIdentifier]
                let newRoute = [tabBarViewControllerIdentifier, statsViewControllerIdentifier]

                let routingActions = Router.routingActionsForTransitionFrom(oldRoute,
                    newRoute: newRoute)

                var controllerIndex: Int?
                var toBeReplaced: RouteElementIdentifier?
                var new: RouteElementIdentifier?

                if case let RoutingActions.Change(responsibleControllerIndex,
                    controllerToBeReplaced,
                    newController) = routingActions.first! {
                        controllerIndex = responsibleControllerIndex
                        toBeReplaced = controllerToBeReplaced
                        new = newController
                }

                expect(routingActions).to(haveCount(1))
                expect(controllerIndex).to(equal(1))
                expect(toBeReplaced).to(equal(counterViewControllerIdentifier))
                expect(new).to(equal(statsViewControllerIdentifier))
            }

            it("generates a Change action on root when root element changes") {
                let oldRoute = [tabBarViewControllerIdentifier]
                let newRoute = [statsViewControllerIdentifier]

                let routingActions = Router.routingActionsForTransitionFrom(oldRoute,
                    newRoute: newRoute)

                var controllerIndex: Int?
                var toBeReplaced: RouteElementIdentifier?
                var new: RouteElementIdentifier?

                if case let RoutingActions.Change(responsibleControllerIndex,
                    controllerToBeReplaced,
                    newController) = routingActions.first! {
                        controllerIndex = responsibleControllerIndex
                        toBeReplaced = controllerToBeReplaced
                        new = newController
                }

                expect(routingActions).to(haveCount(1))
                expect(controllerIndex).to(equal(0))
                expect(toBeReplaced).to(equal(tabBarViewControllerIdentifier))
                expect(new).to(equal(statsViewControllerIdentifier))
            }

            it("transitions frome empty route to empty route") {
                let oldRoute: [RouteElementIdentifier] = []
                let newRoute: [RouteElementIdentifier] = []

                let routingActions = Router.routingActionsForTransitionFrom(oldRoute,
                    newRoute: newRoute)

                expect(routingActions).to(haveCount(0))
            }

            it("performs transition with multiple pops") {
                let oldRoute = [tabBarViewControllerIdentifier, statsViewControllerIdentifier,
                    counterViewControllerIdentifier]
                let newRoute = [tabBarViewControllerIdentifier]

                let routingActions = Router.routingActionsForTransitionFrom(oldRoute,
                    newRoute: newRoute)

                var action1Correct: Bool?
                var action2Correct: Bool?

                if case let RoutingActions.Pop(responsibleRoutableIndex, segmentToBePopped)
                    = routingActions[0] {

                        if responsibleRoutableIndex == 2
                            && segmentToBePopped == counterViewControllerIdentifier {
                                action1Correct = true
                            }
                }

                if case let RoutingActions.Pop(responsibleRoutableIndex, segmentToBePopped)
                    = routingActions[1] {

                        if responsibleRoutableIndex == 1
                            && segmentToBePopped == statsViewControllerIdentifier {
                                action2Correct = true
                        }
                }

                expect(action1Correct).to(beTrue())
                expect(action2Correct).to(beTrue())
                expect(routingActions).to(haveCount(2))
            }

        }
    }

}