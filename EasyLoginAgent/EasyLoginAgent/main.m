//
//  main.m
//  EasyLoginAgent
//
//  Created by Yoann Gini on 02/07/2017.
//  Copyright © 2017 EasyLogin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
int main(int argc, const char * argv[]) {
    NSApplication * application = [NSApplication sharedApplication];
    
    AppDelegate * appDelegate = [AppDelegate new];
    
    [application setDelegate:appDelegate];
    [application run];

    return EXIT_SUCCESS;
}
