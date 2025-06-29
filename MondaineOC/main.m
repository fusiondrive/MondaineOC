//
//  main.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // instance of custom application delegate
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        application.delegate = appDelegate;
        
        // Assign to shared NSApplication instance
        [application run];
    }
    return NSApplicationMain(argc, argv);
}
