//
//  EasyLoginDBProtocol.h
//  EasyLoginDB
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 Yoann Gini. All rights reserved.
//

#import <Foundation/Foundation.h>

// results type depends on the query resultType value. Results can be paginated if too big.
// Generally supported by OD. Must return YES if next page is needed.
typedef BOOL (^EasyLoginDBQueryResult_t)(NSArray<NSDictionary*> *results, BOOL lastResults, NSError *error);
typedef void (^EasyLoginDBRecordInfo_t)(NSDictionary* record, NSError *error);


@protocol EasyLoginDBProtocol

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)getAllRecordsOfType:(NSString*)recordType withAttributes:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRecordsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRecordsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler;
    
@end
