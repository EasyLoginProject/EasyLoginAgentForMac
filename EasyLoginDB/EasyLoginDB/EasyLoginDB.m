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

@end

@implementation EasyLoginDB

#pragma mark - Object Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.recordsPerTypeAndUUID = [NSMutableDictionary new];
        self.indexesForRecordsPerTypeAttributeAndValue = [NSMutableDictionary new];
        [self reloadFromDisk];
    }
    return self;
}

#pragma mark - SPI

- (void)reloadFromDisk {
    NSMutableDictionary *loadedInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[self flatFilePath]];
    if ([loadedInfo count] > 0) {
#warning ygi: need to check if [NSMutableDictionary dictionaryWithContentsOfFile:] return mutable subnodes too (nested dict)
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
    NSLog(@"Records:\n%@", self.recordsPerTypeAndUUID);
    NSLog(@"Indexes:\n%@", self.indexesForRecordsPerTypeAttributeAndValue);
    
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
    NSDictionary *record = [self getRecordOfType:recordType withUUID:uuid];
    
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

- (NSDictionary*)getRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    return [[self.recordsPerTypeAndUUID objectForKey:recordType] objectForKey:uuid];
}

- (void)setRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid {
    NSMutableDictionary *recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    
    if (!recordsForRequestedTypePerUUID) {
        [self.recordsPerTypeAndUUID setObject:[NSMutableDictionary new] forKey:recordType];
        recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    }
    
    [recordsForRequestedTypePerUUID setObject:record forKey:uuid];
}

- (void)unsetRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    NSMutableDictionary *recordsForRequestedTypePerUUID = [self.recordsPerTypeAndUUID objectForKey:recordType];
    
    if (recordsForRequestedTypePerUUID) {
        [recordsForRequestedTypePerUUID removeObjectForKey:uuid];
    }
}

#pragma mark - API

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid {
    NSDictionary *existingRecordWithSameUUID = [self getRecordOfType:recordType withUUID:uuid];
    
    if (existingRecordWithSameUUID) {
        [self removeFromIndexRecordOfType:recordType withUUID:uuid];
    }
    
    [self setRecord:record ofType:recordType withUUID:uuid];
    
    [self addToIndexRecord:record ofType:recordType withUUID:uuid];
    
    [self saveToDisk];
}

- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid {
    [self removeFromIndexRecordOfType:recordType withUUID:uuid];
    [self unsetRecordOfType:recordType withUUID:uuid];
}

- (void)getAllRecordsOfType:(NSString*)recordType withAttributes:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    NSArray *recordsForRequestedType = [[self.recordsPerTypeAndUUID objectForKey:recordType] allObjects];
    NSMutableArray *requestedRecords = [NSMutableArray new];
    
    for (NSDictionary *record in recordsForRequestedType) {
        NSMutableDictionary *requestedRecord = [NSMutableDictionary new];
        for (NSString* key in attributes) {
            [requestedRecord setObject:[record objectForKey:key] forKey:key];
        }
        [requestedRecords addObject:requestedRecord];
    }
    
    completionHandler(requestedRecords, YES, nil);
}

- (void)getRecordsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
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
    completionHandler(validUUIDs, YES, nil);
}

- (void)getRecordsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler {
    NSMutableArray *validUUIDs = [NSMutableArray new];
    
    for (NSString *attribute in [attributesWithValues allKeys]) {
        NSString *value = [attributesWithValues objectForKey:attribute];
        NSArray *matchingUUIDs = [self indexedUUIDsForRecordOfType:recordType withAttribute:attribute setTo:value];
        
        [validUUIDs addObjectsFromArray:matchingUUIDs];
    }
    
    completionHandler(validUUIDs, YES, nil);
}

- (void)getRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler {
    NSDictionary *requestedRecord = [self getRecordOfType:recordType withUUID:uuid];
    completionHandler(requestedRecord, nil);
}

@end
