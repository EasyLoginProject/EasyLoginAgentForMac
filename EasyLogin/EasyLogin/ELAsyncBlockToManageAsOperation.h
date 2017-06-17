//
//  ELAsyncBlockToManageAsOperation.h
//  EasyLogin
//
//  Created by Yoann Gini on 17/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ELAsyncBlockToManageAsOperation;

typedef void(^ELAsyncBlockToManageOperation)(ELAsyncBlockToManageAsOperation* currentOperation);

@interface ELAsyncBlockToManageAsOperation : NSOperation

@property (strong) NSDictionary *userInfo;

@property ELAsyncBlockToManageOperation blockBasedAsyncOperation;
@property ELAsyncBlockToManageOperation handleCancelationRequest;

- (void)considerThisOperationAsDone;


+ (instancetype)operationWithAsyncTask:(ELAsyncBlockToManageOperation)asyncTask withCancelationHandler:(ELAsyncBlockToManageOperation)cancelationHandler andUserInfo:(NSDictionary*)userInfo;
+ (instancetype)runOnSharedQueueOperationWithAsyncTask:(ELAsyncBlockToManageOperation)asyncTask withCancelationHandler:(ELAsyncBlockToManageOperation)cancelationHandler andUserInfo:(NSDictionary*)userInfo;

@end
