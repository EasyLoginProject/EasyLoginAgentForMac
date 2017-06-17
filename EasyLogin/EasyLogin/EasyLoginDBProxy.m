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
@property NSOperationQueue *operationQueue;

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
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(nil, error);
        });
    }] getAllRegisteredRecordsOfType:recordType withAttributesToReturn:attributes andCompletionHandler:^(NSArray<NSDictionary *> *results, NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(results, error);
        });
    }];
}

- (void)getAllRegisteredUUIDsOfType:(NSString*)recordType andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler {
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(nil, error);
        });
    }] getAllRegisteredUUIDsOfType:recordType andCompletionHandler:^(NSArray<NSString *> *results, NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(results, error);
        });
    }];
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler {
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(nil, error);
        });
    }] getRegisteredRecordUUIDsOfType:recordType matchingAllAttributes:attributesWithValues andCompletionHandler:^(NSArray<NSString *> *results, NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(results, error);
        });
    }];
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler {
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(nil, error);
        });
    }] getRegisteredRecordUUIDsOfType:recordType matchingAnyAttributes:attributesWithValues andCompletionHandler:^(NSArray<NSString *> *results, NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(results, error);
        });
    }];
}

- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler {
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(nil, error);
        });
    }] getRegisteredRecordOfType:recordType withUUID:uuid andCompletionHandler:^(NSDictionary *record, NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(record, error);
        });
    }];
}

-(void)ping {
    [self.xpcService.remoteObjectProxy ping];
}

- (void)testXPCConnection:(EasyLoginDBErrorHandler_t)completionHandler {
    [[self.xpcService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(error);
        });;
    }] testXPCConnection:^(NSError *error) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            completionHandler(error);
        });
    }];
}

@end
