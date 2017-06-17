//
//  AppDelegate.swift
//  EasyLoginAgent
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

import Cocoa
import EasyLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var webServiceConnector: ELWebServiceConnector?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        webServiceConnector = ELWebServiceConnector(baseURL:URL(string:"http://develop.eu.easylogin.cloud/")!, headers: nil)
        
        ELCachingDBProxy.sharedInstance().testXPCConnection { (error) in
            if let error = error {
                print("EasyLoginAgent - XPC test done with error: \(error)")
            } else {
                print("EasyLoginAgent - XPC test done with success")
            }
        }
        
        syncRegisteredUsers()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func syncRegisteredUsers() {
        print("EasyLoginAgent - Fetch all assigned users for registration and update")
        if let operation = self.webServiceConnector?.getAllUsersOperation(completionBlock: { (users, operation) in
            if let users = users {
                var wantedUUIDs = Set<String>()
                
                for user in users {
                    print("EasyLoginAgent - Register user \(user)")
                    ELCachingDBProxy.sharedInstance().registerRecord(user.dictionaryRepresentation(), ofType:user.recordEntity(), withUUID:user.identifier())
                    wantedUUIDs.insert(user.identifier())
                }
                
                print("EasyLoginAgent - Fetch all registered users for cleanup")
                ELCachingDBProxy.sharedInstance().getAllRegisteredUUIDs(ofType:ELUser.recordEntity(), andCompletionHandler: { (registeredUUIDs, error) in
                    
                    if let registeredUUIDs = registeredUUIDs {
                        print("EasyLoginAgent - Registered UUIDs before cleanup: \(registeredUUIDs)")
                        let existingUUIDs = Set(registeredUUIDs)
                        let unwantedUUIDs = existingUUIDs.subtracting(wantedUUIDs)
                        
                        for unwantedUUID in unwantedUUIDs {
                            print("EasyLoginAgent - Unregister user with UUID \(unwantedUUID)")
                            ELCachingDBProxy.sharedInstance().unregisterRecord(ofType:ELUser.recordEntity(), withUUID: unwantedUUID)
                        }
                    } else {
                        print("EasyLoginAgent - No registered UUIDs found during the cleanup step.")
                    }
                    print("EasyLoginAgent - Cleanup done")
                })
                
                print("EasyLoginAgent - Sync done")
            }
        }) {
            self.webServiceConnector?.enqueue(operation)
        }
    }
}

