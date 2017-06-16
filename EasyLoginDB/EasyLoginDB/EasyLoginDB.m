//
//  EasyLoginDB.m
//  EasyLoginDB
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import "EasyLoginDB.h"

#import "Constants.h"

@interface EasyLoginDB ()

@property NSMutableDictionary *recordsPerTypeAndUUID;
@property NSMutableDictionary *indexesForRecordsPerTypeAttributeAndValue;
@property NSLock *recordsLock;
@end

@implementation EasyLoginDB

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
        self.recordsPerTypeAndUUID = [NSMutableDictionary new];
        self.indexesForRecordsPerTypeAttributeAndValue = [NSMutableDictionary new];
        self.recordsLock = [NSLock new];
        [self reloadFromDisk];
    }
    return self;
}

#pragma mark - SPI

- (void)reloadFromDisk {
    NSLog(@"Loading DB from disk");
    NSMutableDictionary *loadedInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[self flatFilePath]];
    if ([loadedInfo count] > 0) {
        self.recordsPerTypeAndUUID = loadedInfo;
    }
    
    for (NSString *recordType in self.recordsPerTypeAndUUID) {
        NSMutableDictionary *recordsForSpecificType = [self.recordsPerTypeAndUUID objectForKey:recordType];
        for (NSString *uuid in recordsForSpecificType) {
            [self addToIndexRecord:[recordsForSpecificType objectForKey:uuid] ofType:recordType withUUID:uuid];
        }
    }
}

- (void)saveToDisk {
    NSLog(@"Saving DB to disk");
    [self.recordsPerTypeAndUUID writeToFile:[self flatFilePath] atomically:YES];
}

- (NSString*)flatFilePath {
    return [NSString stringWithFormat:@"%@/flatfile.plist", [self dbPath]];
}

- (NSString*)dbPath {
    return kEasyLoginDBBasePath;
}

- (NSString*)dbPathForRecordsOfType:(NSString*)recordType {
    return [NSString stringWithFormat:@"%@/%@", [self dbPath], recordType];
}

- (void)addToIndexRecord:(NSDictionary *)record ofType:(NSString*)recordType withUUID:(NSString *)uuid {
    NSLog(@"Indexing record with UUID %@", uuid);
    
    NSMutableDictionary *indexesForRecordsPerAttributeAndValue = [self.indexesForRecordsPerTypeAttributeAndValue objectForKey:recordType];
    
    if (!indexesForRecordsPerAttributeAndValue) {
        [self.indexesForRecordsPerTypeAttributeAndValue setObject:[NSMutableDictionary new] forKey:recordType];
        indexesForRecordsPerAttributeAndValue = [self.indexesForRecordsPerTypeAttributeAndValue objectForKey:recordType];
    }

    NSArray *recordAttributes = [record allKeys];
    for (NSString *recordAttribute in recordAttributes) {
        NSString *indexedValue = [record objectForKey:recordAttribute];
        NSMutableDictionary * indexPerValue = [indexesForRecordsPerAttributeAndValue objectForKey:recordAttribute];
        
        if (!indexPerValue) {
            [indexesForRecordsPerAttributeAndValue setObject:[NSMutableDictionary new] forKey:recordAttribute];
            indexPerValue = [indexesForRecordsPerAttributeAndValue objectForKey:recordAttribute];
        }

        NSMutableArray *requestedIndex = [indexPerValue objectForKey:indexedValue];
        
        if (!requestedIndex) {
            [indexPerValue setObject:[NSMutableArray new] forKey:indexedValue];
            requestedIndex = [indexPerValue objectForKey:indexedValue];
        }
        
        [requestedIndex addObject:uuid];
    }
}

- (void)removeFromIndexRecordOfType:(NSString*)recordType withUUID:(NSString *)uuid {
    NSLog(@"Unindexing record with UUID %@", uuid);
    
    NSDictionary *record = [self getRegisteredRecordOfType:recordType withUUID:uuid];
    
    NSMutableDictionary *indexesForRecordsPerAttributeAndValue = [self.indexesForRecordsPerTypeAttributeAndValue objectForKey:recordType];
    
    if (indexesForRecordsPerAttributeAndValue && record) {
        
        NSArray *recordAttributes = [record allKeys];
        for (NSString *recordAttribute in recordAttributes) {
            NSString *indexedValue = [record objectForKey:recordAttribute];
            NSMutableDictionary * indexPerValue = [indexesForRecordsPerAttributeAndValue objectForKey:recordAttribute];
            
            if (indexPerValue) {
                NSMutableArray *requestedIndex = [indexPerValue objectForKey:indexedValue];
                
                if (requestedIndex) {
                    [requestedIndex removeObject:uuid];
                }
            }
        }
    }
}

- (NSArray*)indexedUUIDsForRecordOfType:(NSString*)recordType withAttribute:(NSString *)attribute setTo:(NSString*)value {
    return [[[self.indexesForRecordsPerTypeAttributeAndValue objectForKey:recordType] objectForKey:attribute] objectForKey:value];
}

- (NSDictionary*)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    return [[self.recordsPerTypeAndUUID objectForKey:recordType] objectForKey:uuid];
}

- (void)setRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid {
    NSLog(@"Set record with UUID %@", uuid);
    
    NSMutableDictionary *recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    
    if (!recordsForRequestedTypePerUUID) {
        [self.recordsPerTypeAndUUID setObject:[NSMutableDictionary new] forKey:recordType];
        recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    }
    
    [recordsForRequestedTypePerUUID setObject:record forKey:uuid];
}

- (void)unsetRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    NSLog(@"Unset record with UUID %@", uuid);
    
    NSMutableDictionary *recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    
    if (recordsForRequestedTypePerUUID) {
        [recordsForRequestedTypePerUUID removeObjectForKey:uuid];
    }
}

#pragma mark - API

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid {
    [self.recordsLock lock];
    NSLog(@"Register record with UUID %@", uuid);
    NSDictionary *existingRecordWithSameUUID = [self getRegisteredRecordOfType:recordType withUUID:uuid];
    
    if (existingRecordWithSameUUID) {
        [self removeFromIndexRecordOfType:recordType withUUID:uuid];
    }
    
    [self setRecord:record ofType:recordType withUUID:uuid];
    
    [self addToIndexRecord:record ofType:recordType withUUID:uuid];
    
    [self saveToDisk];
    [self.recordsLock unlock];
}

- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    [self.recordsLock lock];
    NSLog(@"Unregister record with UUID %@", uuid);
    [self removeFromIndexRecordOfType:recordType withUUID:uuid];
    [self unsetRecordOfType:recordType withUUID:uuid];
    [self saveToDisk];
    [self.recordsLock unlock];
}

- (void)getAllRegisteredRecordsOfType:(NSString*)recordType withAttributesToReturn:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    NSLog(@"Get all registered records");
    
    NSArray *recordsForRequestedType = [[self.recordsPerTypeAndUUID objectForKey:recordType] allObjects];
    NSMutableArray *requestedRecords = [NSMutableArray new];
    
    for (NSDictionary *record in recordsForRequestedType) {
        NSMutableDictionary *requestedRecord = [NSMutableDictionary new];
        for (NSString* key in attributes) {
            id requestedAttribute = [record objectForKey:key];
            if (requestedAttribute) {
                [requestedRecord setObject:requestedAttribute forKey:key];
            }
        }
        [requestedRecords addObject:requestedRecord];
    }
    
    completionHandler(requestedRecords, nil);
}

- (void)getAllRegisteredUUIDsOfType:(NSString*)recordType andCompletionHandler:(EasyLoginDBUUIDsResult_t)completionHandler {
    NSLog(@"Get all registered UUIDs");
    
    NSArray *uuidsForRequestedType = [[self.recordsPerTypeAndUUID objectForKey:recordType] allKeys];
    
    completionHandler(uuidsForRequestedType, nil);
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    NSLog(@"Get regsiterred records matching all attributes %@", attributesWithValues);
    
    NSMutableArray *validUUIDs = [NSMutableArray new];
    BOOL roundOne = YES;
    
    for (NSString *attribute in [attributesWithValues allKeys]) {
        NSString *value = [attributesWithValues objectForKey:attribute];
        NSArray *matchingUUIDs = [self indexedUUIDsForRecordOfType:recordType withAttribute:attribute setTo:value];
        
        if (roundOne) {
            [validUUIDs addObjectsFromArray:matchingUUIDs];
            roundOne = NO;
        } else {
            NSMutableSet *currentUUIDs = [NSMutableSet setWithArray:validUUIDs];
            NSSet *fetchedUUIDs = [NSSet setWithArray:matchingUUIDs];
            
            [currentUUIDs intersectSet:fetchedUUIDs];
            
            validUUIDs = [[currentUUIDs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"stringValue" ascending:YES]]] mutableCopy];
            
            if ([validUUIDs count] == 0) {
                break;
            }
        }
    }
    completionHandler(validUUIDs, nil);
}

- (void)getRegisteredRecordUUIDsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    NSLog(@"Get regsiterred records matching any attributes %@", attributesWithValues);
    
    NSMutableArray *validUUIDs = [NSMutableArray new];
    
    for (NSString *attribute in [attributesWithValues allKeys]) {
        NSString *value = [attributesWithValues objectForKey:attribute];
        NSArray *matchingUUIDs = [self indexedUUIDsForRecordOfType:recordType withAttribute:attribute setTo:value];
        
        [validUUIDs addObjectsFromArray:matchingUUIDs];
    }
    
    completionHandler(validUUIDs, nil);
}

- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler {
    NSLog(@"Get regsiterred record with UUID %@", uuid);
    
    NSDictionary *requestedRecord = [self getRegisteredRecordOfType:recordType withUUID:uuid];
    completionHandler(requestedRecord, nil);
}

- (void)ping {
    NSLog(@"pong");
}

- (void)testXPCConnection:(EasyLoginDBErrorHandler_t)completionHandler {
    NSLog(@"EasyLogin DB recieve test with success");
    completionHandler(nil);
}

@end
