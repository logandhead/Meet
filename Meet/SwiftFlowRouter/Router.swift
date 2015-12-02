//
//  Router.swift
//  Meet
//
//  Created by Benjamin Encz on 11/11/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import UIKit
import SwiftFlow

// TODO: Ensure this protocol requires UIViewControlelrs
public protocol RoutableViewController {

    func pushRouteSegment(viewControllerIdentifier: ViewControllerIdentifier) -> RoutableViewController
    func popRouteSegment(viewControllerIdentifier: ViewControllerIdentifier)
    func changeRouteSegment(fromViewControllerIdentifier: ViewControllerIdentifier,
        toViewControllerIdentifier: ViewControllerIdentifier) -> RoutableViewController

}

public class Router: StoreSubscriber {

    public typealias RootViewControllerProvider = () -> RoutableViewController

    var store: MainStore
    var lastNavigationState = NavigationState()
    var rootViewControllerProvider: RootViewControllerProvider
    // maps route segements to UIViewController instances
    var viewControllerForSubroute: [RoutableViewController] = []

    public init(store: MainStore, rootViewControllerProvider: RootViewControllerProvider) {
        self.store = store
        self.rootViewControllerProvider = rootViewControllerProvider

        self.store.subscribe(self)
    }

    public func newState(state: HasNavigationState) {
        // find last common subroute
        var lastCommonSubroute = -1

        if lastNavigationState.route.count > 0 && state.navigationState.route.count > 0 {
            while lastCommonSubroute + 1 < state.navigationState.route.count &&
                lastCommonSubroute + 1 < state.navigationState.route.count &&
                state.navigationState.route[lastCommonSubroute + 1] == lastNavigationState
                .route[lastCommonSubroute + 1] {
                    lastCommonSubroute++
            }
        }

        // remove all view controllers that are in old state, beyond common subroute but aren't
        // in new state
        var oldRouteIndex = lastNavigationState.route.count - 1

        while oldRouteIndex > lastCommonSubroute + 1 && oldRouteIndex >= 0 {
            let routeSegmentToPop = lastNavigationState.route[oldRouteIndex]
            viewControllerForSubroute[oldRouteIndex - 1].popRouteSegment(routeSegmentToPop)
            viewControllerForSubroute.removeAtIndex(oldRouteIndex)

            oldRouteIndex--
        }

        if oldRouteIndex == lastCommonSubroute + 1 && oldRouteIndex >= 0 {
            let routeSegmentToPush = state.navigationState.route[oldRouteIndex]

            viewControllerForSubroute[oldRouteIndex] =
                viewControllerForSubroute[oldRouteIndex - 1]
                    .changeRouteSegment(lastNavigationState.route[oldRouteIndex],
                        toViewControllerIdentifier: routeSegmentToPush)
        }

        if (oldRouteIndex == -1) {
            // no common subroute, need to ask for root view controller
            viewControllerForSubroute.append(rootViewControllerProvider())
            oldRouteIndex++
        }

        // push remainder of new route
        let newRouteIndex = state.navigationState.route.count - 1

        while oldRouteIndex < newRouteIndex {
            let routeSegmentToPush = state.navigationState.route[oldRouteIndex + 1]

            viewControllerForSubroute[oldRouteIndex + 1] =
                viewControllerForSubroute[oldRouteIndex].pushRouteSegment(routeSegmentToPush)

            oldRouteIndex++
        }

        lastNavigationState = state.navigationState
    }

}

public enum RouteTransition {
  case Push
  case Pop
  case TabBarSelect
  case Modal
  case Dismiss
  case None
}
