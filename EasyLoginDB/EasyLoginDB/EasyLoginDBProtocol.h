//
//  EasyLoginDBProtocol.h
//  EasyLoginDB
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^EasyLoginDBQueryResult_t)(NSArray<NSDictionary*> *results, NSError *error);
typedef void (^EasyLoginDBUUIDsResult_t)(NSArray<NSString*> *results, NSError *error);
typedef void (^EasyLoginDBRecordInfo_t)(NSDictionary* record, NSError *error);
typedef void (^EasyLoginDBErrorHandler_t)(NSError *error);

@protocol EasyLoginDBProtocol

@required

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)getAllRegisteredRecordsOfType:(NSString*)recordType withAttributesToReturn:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getAllRegisteredUUIDsOfType:(NSString*)recordType andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler;
- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler;
- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler;
- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler;

- (void)ping;
- (void)testXPCConnection:(EasyLoginDBErrorHandler_t)completionHandler;

@end

