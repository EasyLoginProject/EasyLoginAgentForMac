//
//  ELAgent.h
//  EasyLoginAgent
//
//  Created by Yoann Gini on 02/07/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EasyLogin/EasyLogin.h>

@interface ELAgent : NSObject

- (void)start;
- (void)stop;
- (void)getMyDeviceRecord:(void(^)(ELDevice *myRecord))completionHandler;
- (void)syncRegisteredUsers;

@end

