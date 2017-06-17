//
//  ELAsyncBlockToManageAsOperation.m
//  EasyLogin
//
//  Created by Yoann Gini on 17/06/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import "ELAsyncBlockToManageAsOperation.h"

@interface ELAsyncBlockToManageAsOperation ()
@property (getter=isExecuting) BOOL executing;
@property (getter=isFinished) BOOL finished;

@end

@implementation ELAsyncBlockToManageAsOperation

@synthesize executing;
@synthesize finished;

+ (instancetype)operationWithAsyncTask:(ELAsyncBlockToManageOperation)asyncTask withCancelationHandler:(ELAsyncBlockToManageOperation)cancelationHandler andUserInfo:(NSDictionary*)userInfo {
    ELAsyncBlockToManageAsOperation *asyncOperation = [self new];
    asyncOperation.blockBasedAsyncOperation = asyncTask;
    asyncOperation.handleCancelationRequest = cancelationHandler;
    asyncOperation.userInfo = userInfo;
    return asyncOperation;
}

+ (instancetype)runOnSharedQueueOperationWithAsyncTask:(ELAsyncBlockToManageOperation)asyncTask withCancelationHandler:(ELAsyncBlockToManageOperation)cancelationHandler andUserInfo:(NSDictionary*)userInfo {
    static NSOperationQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [NSOperationQueue new];
    });
    
    ELAsyncBlockToManageAsOperation *operation = [self operationWithAsyncTask:asyncTask withCancelationHandler:cancelationHandler andUserInfo:userInfo];
    [sharedQueue addOperation:operation];
    return operation;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)considerThisOperationAsDone {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    self.finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if (self.blockBasedAsyncOperation) {
        self.blockBasedAsyncOperation(self);
    } else {
        [self considerThisOperationAsDone];
    }
    
}

- (void)cancel {
    if (self.handleCancelationRequest) {
        self.handleCancelationRequest(self);
    }
}

@end
