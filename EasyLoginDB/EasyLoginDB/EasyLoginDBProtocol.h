//
//  EasyLoginDBProtocol.h
//  EasyLoginDB
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Foundation/Foundation.h>


// results type depends on the query resultType value. Results can be paginated if too big.
// Generally supported by OD. Must return YES if next page is needed.
typedef void (^EasyLoginDBQueryResult_t)(NSArray<NSDictionary*> *results, NSError *error);
typedef void (^EasyLoginDBRecordInfo_t)(NSDictionary* record, NSError *error);

@protocol EasyLoginDBProtocol

@required

- (void)registerRecord:(NSDictionary*)record ofType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)unregisterRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid;
- (void)getAllRegisteredRecordsOfType:(NSString*)recordType withAttributesToReturn:(NSArray<NSString*> *)attributes andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRegisteredRecordsOfType:(NSString*)recordType matchingAllAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRegisteredRecordsOfType:(NSString*)recordType matchingAnyAttributes:(NSDictionary<NSString*,NSString*>*)attributesWithValues andCompletionHandler:(EasyLoginDBQueryResult_t)completionHandler;
- (void)getRegisteredRecordOfType:(NSString*)recordType withUUID:(NSString*)uuid andCompletionHandler:(EasyLoginDBRecordInfo_t)completionHandler;
    
@end

