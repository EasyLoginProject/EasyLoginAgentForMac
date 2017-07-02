//
//  main.m
//  EasyLoginAgent
//
//  Created by Yoann Gini on 02/07/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ELAgent.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ELAgent * agent = [ELAgent new];
        [agent start];   
            do {
                @autoreleasepool {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    [[NSRunLoop currentRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate distantFuture]];
                }
            } while (YES);
    }
    return EXIT_SUCCESS;
}
