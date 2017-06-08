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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        EasyLoginDBProxy.sharedInstance().getAllRegisteredRecords(ofType: "user", withAttributesToReturn: ["shortname"]) { (records, error) in
            
            print(records as Any)
            
            EasyLoginDBProxy.sharedInstance().registerRecord(["shortname": "test", "displayname": "Test 1"], ofType: "user", withUUID: UUID.init().uuidString)
            
            EasyLoginDBProxy.sharedInstance().getAllRegisteredRecords(ofType: "user", withAttributesToReturn: ["shortname"]) { (records, error) in
                
                print(records as Any)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

