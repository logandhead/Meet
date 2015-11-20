//
//  DataMutationActionCreator.swift
//  Meet
//
//  Created by Benjamin Encz on 11/19/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation

struct DataMutationActionCreator {

    func createNewContact(email: String) -> ActionCreator {
        return { _ in
            return .CreateContactFromEmail(email)
        }
    }
    
}