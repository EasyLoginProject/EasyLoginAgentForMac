//
//  AppDelegate.swift
//  EasyLoginAgent
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var server: ELServer?
    var myRecord: ELDevice?
    var notificationObject: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        server = ELServer.sharedInstance()
        
        ELCachingDBProxy.sharedInstance().testXPCConnection { (error) in
            if let error = error {
                print("EasyLoginAgent - XPC test done with error: \(error)")
            } else {
                print("EasyLoginAgent - XPC test done with success")
            }
        }
        
        
        registerMyDevice { (myself) in
            self.myRecord = myself
            self.syncRegisteredUsers()
        }
        
        notificationObject = NotificationCenter.default.addObserver(forName:Notification.Name(kELServerUpdateNotification), object:nil, queue:nil, using: { (notification) in
            print("EasyLoginAgent - Server has changed, we start the sync")
            self.syncRegisteredUsers()
        })
    }
    
    func registerMyDevice(completionHandler: @escaping ((ELDevice?) -> ())) {
        print("EasyLoginAgent - Looking for existing device records")
        server?.getAllRecords(withEntityClass: ELDevice.recordClass(), completionBlock: { (records, error) in
            var maybeMyself: ELDevice?
            
            if let records = records {
                print("EasyLoginAgent - Found multiple records, looking for the one matching our serial number")
                for record in records  {
                    let device = record as! ELDevice
                    
                    if device.string(forProperty: kELDeviceSerialNumberKey) == ELToolbox.serialNumber() {
                        print("EasyLoginAgent - Record with our serial number found")
                        maybeMyself = device
                        break
                    }
                }
            }
            
            if let myself = maybeMyself {
                print("EasyLoginAgent - Device record found")
                completionHandler(myself)
            } else {
                print("EasyLoginAgent - Device record not found, listing our own invetory properties")
                let myProperties = ELRecordProperties(dictionary: ["deviceName" : Host.current().localizedName!,
                                                                   "serialNumber" : ELToolbox.serialNumber()],
                                                      mapping: nil)
                
                if let myProperties = myProperties {
                    print("EasyLoginAgent - Inventory properties ready, sending request to create our own record")
                    self.server?.createNewRecord(withEntityClass: ELDevice.recordClass(),
                                            properties: myProperties,
                                            completionBlock: { (record, error) in
                                                if let record = record {
                                                    print("EasyLoginAgent - Record created with success")
                                                    completionHandler(record as? ELDevice)
                                                } else {
                                                    print("EasyLoginAgent - Unable to create record, error \(String(describing: error))")
                                                    completionHandler(nil)
                                                }
                    })
                } else {
                    print("EasyLoginAgent - Error! Unable to list our own inventory properties")
                    completionHandler(nil)
                }
            }
        })

        
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func syncRegisteredUsers() {
        print("EasyLoginAgent - Fetch all assigned users for registration and update")
        
        if let myRecord = myRecord {
            server?.getUpdatedRecord(myRecord, completionBlock: { (updatedMyself, error) in
                if let updatedMyself = updatedMyself {
                    let myself = updatedMyself as! ELDevice
                    
                    print("EasyLoginAgent - Sync based on info \(myself)")
                } else {
                    print("EasyLoginAgent - Unable to fetch our own record, no sync possible")
                }
            })

        } else {
            print("EasyLoginAgent - Unable to fetch our own record, no sync possible")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.syncRegisteredUsers()
            })
        }
        
        server?.getAllRecords(withEntityClass:ELUser.recordClass(), completionBlock: { (records, error) in
            
            if let records = records {
                
                var wantedUUIDs = Set<String>()
                
                for record in records {
                    self.server?.getUpdatedRecord(record, completionBlock: { (updatedRecord, error) in
                        print("EasyLoginAgent - Register record \(String(describing: updatedRecord))")
                        ELCachingDBProxy.sharedInstance().registerRecord(updatedRecord?.dictionaryRepresentation(), ofType:updatedRecord?.recordEntity(), withUUID:updatedRecord?.identifier())
                    })
                    
                    wantedUUIDs.insert(record.identifier())
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
        })
    }
}

