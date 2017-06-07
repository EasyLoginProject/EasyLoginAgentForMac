//
//  EasyLoginDB.h
//  EasyLoginDB
//
//  Created by Yoann Gini on 07/06/2017.
//  Copyright © 2017 Yoann Gini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EasyLoginDBProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface EasyLoginDB : NSObject <EasyLoginDBProtocol>
@end
