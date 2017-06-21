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
    var server: ELServer?
    var myRecord: ELDevice?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        server = ELServer(baseURL: URL(string:"http://demo.eu.easylogin.cloud/")!)
        
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
    }
    
    func registerMyDevice(completionHandler: @escaping ((ELDevice?) -> ())) {
        
        server?.getAllRecords(withEntityClass: ELDevice.recordClass(), completionBlock: { (records, error) in
            var maybeMyself: ELDevice?
            
            if let records = records {
                for record in records  {
                    let device = record as! ELDevice
                    
                    if device.serialNumber == ELToolbox.serialNumber() {
                        maybeMyself = device
                        break
                    }
                }
            }
            
            if let myself = maybeMyself {
                completionHandler(myself)
            } else {
                let myProperties = ELRecordProperties(dictionary: ["deviceName" : Host.current().localizedName!,
                                                                   "serialNumber" : ELToolbox.serialNumber(),
                                                                   "cdsSelectionMode": "auto"],
                                                      mapping: nil)
                
                if let myProperties = myProperties {
                    self.server?.createNewRecord(withEntityClass: ELDevice.recordClass(),
                                            properties: myProperties,
                                            completionBlock: { (record, error) in
                                                if let record = record {
                                                    completionHandler(record as? ELDevice)
                                                } else {
                                                    completionHandler(nil)
                                                }
                    })
                } else {
                    completionHandler(nil)
                }
            }
        })

        
        
    }
    
    func listAllComputerRecord() {
        print("EasyLoginAgent - Fetch all devices")
        server?.getAllRecords(withEntityClass: ELDevice.recordClass(), completionBlock: { (records, error) in
            if let records = records {
                for record in records  {
                    let device = record as! ELDevice
                    
                    print("EasyLoginAgent - Devices: \(device.deviceName ?? "NO NAME") \(device.serialNumber ?? "NO SERIAL NUMBER")")
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
                    
                    print("Sync based on info \(myself)")
                } else {
                    print("EasyLoginAgent - Unable to fetch our own record, no sync possible")
                }
            })

        } else {
            print("EasyLoginAgent - Unable to fetch our own record, no sync possible")
        }
        
        server?.getAllRecords(withEntity: ELUser.recordEntity(), completionBlock: { (records, error) in
            
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

