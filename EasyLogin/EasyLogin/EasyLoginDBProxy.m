//
//  EasyLoginDBProxy.m
//  EasyLogin
//
//  Created by Yoann Gini on 08/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import "EasyLoginDBProxy.h"
#import <objc/runtime.h>


@interface EasyLoginDBProxy ()

@property NSXPCConnection *xpcService;
@property NSArray *forwardableSelectors;

@end

@implementation EasyLoginDBProxy

#pragma mark - Object Lifecycle

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.xpcService = [[NSXPCConnection alloc] initWithMachServiceName:@"io.easylogin.EasyLoginDB" options:NSXPCConnectionPrivileged];
        self.xpcService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(EasyLoginDBProtocol)];
        [self.xpcService resume];
    }
    return self;
}

#pragma mark - Forwarding API

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid {
    [self.xpcService.remoteObjectProxy registerRecord:record ofType:recordType withUUID:uuid];
}

- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    [self.xpcService.remoteObjectProxy unregisterRecordOfType:recordType withUUID:uuid];
}

- (void)getAllRegisteredRecordsOfType:(NSString*)recordType withAttributesToReturn:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    [self.xpcService.remoteObjectProxy getAllRegisteredRecordsOfType:recordType withAttributesToReturn:attributes andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    [self.xpcService.remoteObjectProxy getRegisteredRecordsOfType:recordType matchingAllAttributes:attributesWithValues andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    [self.xpcService.remoteObjectProxy getRegisteredRecordsOfType:recordType matchingAnyAttributes:attributesWithValues andCompletionHandler:completionHandler];
}

- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler {
    [self.xpcService.remoteObjectProxy getRegisteredRecordOfType:recordType withUUID:uuid andCompletionHandler:completionHandler];
}

@end
