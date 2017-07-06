//
//  ELAgent.m
//  EasyLoginAgent
//
//  Created by Yoann Gini on 02/07/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import "ELAgent.h"

@interface ELAgent ()

@property ELServer *server;
@property ELDevice *myRecord;
@property id<NSObject> notificationObject;

@end

@implementation ELAgent

- (void)start {
    self.server = [ELServer sharedInstance];
    
    [[ELCachingDBProxy sharedInstance] testXPCConnection:^(NSError *error) {
        if (error) {
            NSLog(@"EasyLoginAgent - XPC test done with error: %@", error);
        } else {
            NSLog(@"EasyLoginAgent - XPC test done with success");
        }
    }];
    
    self.notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:kELServerUpdateNotification
                                                                                object:self.server
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification * _Nonnull note) {
                                                                                NSLog(@"EasyLoginAgent - Server has changed, we start the sync");
                                                                                [self syncRegisteredUsers];
                                                                            }];
    
    [self getMyDeviceRecord:^(ELDevice *myRecord) {
        self.myRecord = myRecord;
        [self syncRegisteredUsers];
    }];
    
}


- (void)stop {
    if (self.notificationObject) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.notificationObject];
        self.notificationObject = nil;
    }
}

#pragma mark - Sync managemnt

- (void)getMyDeviceRecord:(void(^)(ELDevice *myRecord))completionHandler {
    NSLog(@"EasyLoginAgent - Looking for existing device records");
    
    [self.server getAllRecordsWithEntityClass:[ELDevice recordClass]
                              completionBlock:^(NSArray<__kindof ELRecord *> * _Nullable records, NSError * _Nullable error) {
                                  ELDevice *myself = nil;
                                  
                                  NSLog(@"EasyLoginAgent - Found %lu records, looking for the one matching our serial number", [records count]);
                                  for (ELDevice *record in records) {
                                      if ([[record stringForProperty:kELDeviceSerialNumberKey] isEqualToString:[ELToolbox serialNumber]]) {
                                          NSLog(@"EasyLoginAgent - Record with our serial number found");
                                          myself = record;
                                          break;
                                      }
                                  }
                                  
                                  if (myself) {
                                      NSLog(@"EasyLoginAgent - Device record found");
                                      completionHandler(myself);
                                  } else {
                                      NSLog(@"EasyLoginAgent - Device record not found, listing our own invetory properties");
                                      ELRecordProperties *myProperties = [ELRecordProperties recordPropertiesWithDictionary:@{
                                                                                                                              @"deviceName": [[NSHost currentHost] localizedName],
                                                                                                                              @"serialNumber": [ELToolbox serialNumber],
                                                                                                                              }
                                                                                                                    mapping:nil];
                                      
                                      if (myProperties) {
                                          NSLog(@"EasyLoginAgent - Inventory properties ready, sending request to create our own record");
                                          
                                          [self.server createNewRecordWithEntityClass:[ELDevice recordClass]
                                                                           properties:myProperties
                                                                      completionBlock:^(__kindof ELRecord * _Nullable newRecord, NSError * _Nullable error) {
                                                                          if (newRecord) {
                                                                              NSLog(@"EasyLoginAgent - Record created with success");
                                                                              completionHandler(newRecord);
                                                                          } else {
                                                                              NSLog(@"EasyLoginAgent - Unable to create record, error: %@", error);
                                                                              completionHandler(nil);
                                                                          }
 
                                                                      }];
                                      } else {
                                          NSLog(@"EasyLoginAgent - Error! Unable to list our own inventory properties");
                                          completionHandler(nil);
                                      }
                                  }
                              }];
}

- (void)syncRegisteredUsers {
    NSLog(@"EasyLoginAgent - Fetch all assigned users for registration and update");

    // Will be used to support SyncSet
//    [self.server getUpdatedRecord:self.myRecord
//                  completionBlock:^(ELDevice* _Nullable updatedRecord, NSError * _Nullable error) {
//                      if (updatedRecord) {
//                          NSLog(@"EasyLoginAgent - Sync based on updated record")'
//                      } else {
//                          NSLog(@"EasyLoginAgent - Unable to fetch our own record, no sync possible");
//                      }
//                  }];
    
    
    // Temporary implementation where all users are synced
    [self.server getAllRecordsWithEntityClass:[ELUser recordClass]
                              completionBlock:^(NSArray<__kindof ELRecord *> * _Nullable records, NSError * _Nullable error) {
                                  if (!error && records) {
                                      NSMutableSet *wantedUUIDs = [NSMutableSet new];
                                      for (ELUser *partialUserToSync in records) {
                                          [self.server getUpdatedRecord:partialUserToSync
                                                        completionBlock:^(__kindof ELRecord * _Nullable updatedRecord, NSError * _Nullable error) {
                                                            
                                                            if (updatedRecord) {
                                                                NSLog(@"EasyLoginAgent - Register record: %@", updatedRecord);
                                                                [[ELCachingDBProxy sharedInstance] registerRecord:updatedRecord.dictionaryRepresentation
                                                                                                           ofType:updatedRecord.recordEntity
                                                                                                         withUUID:updatedRecord.identifier];
                                                            } else {
                                                                NSLog(@"EasyLoginAgent - Unable to find updated info for record of type %@ with identifier %@", partialUserToSync.recordEntity, partialUserToSync.identifier);
                                                            }
                                                        }];
                                          
                                          [wantedUUIDs addObject:partialUserToSync.identifier];
                                      }
                                      
                                      NSLog(@"EasyLoginAgent - Fetch all registered users for cleanup");
                                      [[ELCachingDBProxy sharedInstance] getAllRegisteredUUIDsOfType:[ELUser recordEntity]
                                                                                andCompletionHandler:^(NSArray<NSString *> *results, NSError *error) {
                                                                                    if ([results count] > 0) {
                                                                                        NSMutableSet *unwantedUUIDs = [NSMutableSet setWithArray:results];
                                                                                        [unwantedUUIDs minusSet:wantedUUIDs];
                                                                                        
                                                                                        for (NSString *unwantedUUID in unwantedUUIDs) {
                                                                                            NSLog(@"EasyLoginAgent - Unregister user with UUID %@", unwantedUUID);
                                                                                            [[ELCachingDBProxy sharedInstance] unregisterRecordOfType:[ELUser recordEntity]
                                                                                                                                             withUUID:unwantedUUID];
                                                                                        }
                                                                                        
                                                                                    } else {
                                                                                        NSLog(@"EasyLoginAgent - No registered UUIDs found during the cleanup step.");
                                                                                    }
                                                                                    
                                                                                    NSLog(@"EasyLoginAgent - Cleanup done");
                                                                                }];

                                  } else {
                                      NSLog(@"EasyLoginAgent - Unable to list assigned records: %@", error);
                                  }
                                  
                              }];
}

@end
