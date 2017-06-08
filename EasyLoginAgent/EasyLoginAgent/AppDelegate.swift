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
        
        syncRegisteredUsers()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func syncRegisteredUsers() {
        fetchAssignedUsers { (assignedUUIDs) in
            for uuid in assignedUUIDs {
                
                print("EasyLoginAgent - Fetch info for user with UUID \(uuid)")
                
                if let operation = self.webServiceConnector?.getUserPropertiesOperation(forUserUniqueId: uuid, completionBlock: { (userInfo, operation) in
                    
                    print("EasyLoginAgent - Register user with UUID \(uuid)")
                    EasyLoginDBProxy.sharedInstance().registerRecord(userInfo, ofType: "user", withUUID: uuid)
                }) {
                    self.webServiceConnector?.enqueue(operation)
                }
            }
            
            print("EasyLoginAgent - Fetch all registered users for cleanup")
            EasyLoginDBProxy.sharedInstance().getAllRegisteredRecords(ofType: "users", withAttributesToReturn: ["uuid"], andCompletionHandler: { (registeredUsersInfo, error) in
                
                if let registeredUsersInfo = registeredUsersInfo {
                    let registeredUUIDs = registeredUsersInfo.map({$0["uuid"]! as! String})
                    
                    let existingUUIDs = Set(registeredUUIDs)
                    let wantedUUIDs = Set(assignedUUIDs)
                    let unwantedUUIDs = existingUUIDs.symmetricDifference(wantedUUIDs)
                    
                    for unwantedUUID in unwantedUUIDs {
                        
                        print("EasyLoginAgent - Unregister user with UUID \(unwantedUUID)")
                        EasyLoginDBProxy.sharedInstance().unregisterRecord(ofType: "user", withUUID: unwantedUUID)
                    }
                }
            })
        }
    }
    
    func fetchAssignedUsers(completionHandler:@escaping ([String]) ->()) {
        print("EasyLoginAgent - Fetch assigned users")
        if let operation = self.webServiceConnector?.getAllUsersOperation(completionBlock: { (users, operation) in
            if let users = users {
                var UUIDs = [String]()
                for user in users {
                    let userInfo = user.dictionaryRepresentation()
                    if let uuidObject = userInfo["uuid"] {
                        let uuid = uuidObject as! String
                        print("EasyLoginAgent - User found with UUID \(uuid)")
                        UUIDs.append(uuid)
                    }
                }
                
                completionHandler(UUIDs)
            }
            
        }) {
            self.webServiceConnector?.enqueue(operation)
        }
    }
}

