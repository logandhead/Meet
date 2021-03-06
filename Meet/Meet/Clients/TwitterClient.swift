//
//  TwitterClient.swift
//  TwitterLivestreamSwift
//
//  Created by Benjamin Encz on 1/25/15.
//  Copyright (c) 2015 Benjamin Encz. All rights reserved.
//

import Foundation
import Accounts
import SwifteriOS
import UIKit
import SSKeychain
import ReactiveCocoa
import Unbox
import SwiftFlow

// TODO: Overhaul this

enum TwitterAPIError: String, ErrorType {
    case NotAuthenticated
    case NoInternetConnection
    case UnknownError
}

extension TwitterAPIError: Coding {

    init(dictionary: [String : AnyObject]) {
        let type = dictionary["type"] as! String
        self = TwitterAPIError(rawValue: type)!
    }

    func dictionaryRepresentation() -> [String : AnyObject] {
        return ["type": self.rawValue]
    }

}

struct TwitterClient {

    static var cachedSwifter: Swifter?

    static func login() -> SignalProducer<Swifter, TwitterAPIError> {
        let accountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(
            ACAccountTypeIdentifierTwitter)
        let accountStore = ACAccountStore()

        return SignalProducer<Swifter, TwitterAPIError> { observer, _ in

            if let cachedSwifter = self.cachedSwifter {
                observer.sendNext(cachedSwifter)
                observer.sendCompleted()
            }

            accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
                (t: Bool, e: NSError!) -> Void in

                let (consumerKey, consumerSecret) = Authentication.retrieveApplicationAuthPair()
                let accounts = ACAccountStore().accountsWithAccountType(accountType)

                var nativeAccount: ACAccount? = nil

                if let accounts = accounts where accounts.count > 0 {
                    nativeAccount = accounts.last as? ACAccount
                }

                if let nativeAccount = nativeAccount {
                    let swifter = Swifter(account: nativeAccount)
                    observer.sendNext(swifter)
                } else if let (cachedKey, cachedSecret) = Authentication.retrieveOAuthAccessPair() {
                    let swifter = Swifter(consumerKey: consumerKey,
                        consumerSecret: consumerSecret,
                        oauthToken: cachedKey,
                        oauthTokenSecret: cachedSecret)

                    self.cachedSwifter = swifter
                    observer.sendNext(swifter)
                } else {
                    let swifter = Swifter(consumerKey: consumerKey, consumerSecret: consumerSecret)

                    swifter.authorizeWithCallbackURL(NSURL(string: "swifter://success")!, success: {
                        (accessToken, response) -> Void in

                        self.cachedSwifter = swifter
                        Authentication.saveOAuthAccessPair(
                            OAuthAccessPair(key: accessToken!.key, secret: accessToken!.secret))

                         observer.sendNext(swifter)
                    }, failure: { (error) -> Void in
                        print(error)
                        observer.sendFailed(.NotAuthenticated)
                    }, openQueryURL: nil)
                }
            }
        }
    }

    static func findUsers(searchString: String) -> SignalProducer<[TwitterUser], TwitterAPIError> {
        return SignalProducer { observer, disposables in
            login().startWithNext { swifter in
                swifter.getUsersSearchWithQuery(searchString, page: 0, count: 5,
                    includeEntities: false, success: { (users) -> Void in
                        if let users = users {
                            let twitterUsers = users.map { TwitterUser(json: $0) }
                            observer.sendNext(twitterUsers)
                        }
                }, failure: { (error) -> Void in
                        if error.code == NSURLErrorNotConnectedToInternet {
                            observer.sendFailed(.NoInternetConnection)
                        } else {
                            observer.sendFailed(.UnknownError)
                        }
                })
            }
        }
    }

}
