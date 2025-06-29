//
//  AppDelegate.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "AppDelegate.h"
#import "ClockView.h"

@interface AppDelegate ()

@property (strong) NSWindow *window;
@property (strong) ClockView *clockView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 800)
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    [self.window setTitle:@"Mondaine Clock (Objective-C)"];
    [self.window center];
    
    // create ClockView
    self.clockView = [[ClockView alloc] initWithFrame:self.window.contentView.bounds];
    self.clockView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // set ClockView as contentView
    self.window.contentView = self.clockView;
    
    // show window
    [self.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // saves
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

