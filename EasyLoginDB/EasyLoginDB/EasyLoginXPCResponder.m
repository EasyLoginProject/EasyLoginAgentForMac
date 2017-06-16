//
//  EasyLoginXPCResponder.m
//  EasyLoginDB
//
//  Created by Yoann Gini on 16/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import "EasyLoginXPCResponder.h"

#import "EasyLoginDB.h"

@interface EasyLoginXPCResponder ()
@property EasyLoginDB *centralDB;
@end

@implementation EasyLoginXPCResponder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.centralDB = [EasyLoginDB sharedInstance];
    }
    return self;
}

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid;
{
    [self.centralDB registerRecord:record ofType:recordType withUUID:uuid];
}

- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid;
{
    [self.centralDB unregisterRecordOfType:recordType withUUID:uuid];
}

- (void)getAllRegisteredRecordsOfType:(NSString*)recordType withAttributesToReturn:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
{
    [self.centralDB getAllRegisteredRecordsOfType:recordType withAttributesToReturn:attributes andCompletionHandler:completionHandler];
}

- (void)getAllRegisteredUUIDsOfType:(NSString*)recordType andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler;
{
    [self.centralDB getAllRegisteredUUIDsOfType:recordType andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
{
    [self.centralDB getRegisteredRecordUUIDsOfType:recordType matchingAllAttributes:attributesWithValues andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
{
    [self.centralDB getRegisteredRecordUUIDsOfType:recordType matchingAnyAttributes:attributesWithValues andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler;
{
    [self.centralDB getRegisteredRecordOfType:recordType withUUID:uuid andCompletionHandler:completionHandler];
}

- (void)ping;
{
    [self.centralDB ping];
}
- (void)testXPCConnection:(EasyLoginDBErrorHandler_t)completionHandler
{
    [self.centralDB testXPCConnection:completionHandler];
}

@end
