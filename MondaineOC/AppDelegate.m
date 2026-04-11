//
//  AppDelegate.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "AppDelegate.h"
#import "ClockView.h"
#import "AppState.h"
#import "WindowStyleManager.h"

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

    // Lock to 1:1 aspect ratio so the clock face is never distorted.
    self.window.contentAspectRatio = NSMakeSize(1.0, 1.0);
    self.window.minSize = NSMakeSize(150.0, 150.0);

    self.clockView = [[ClockView alloc] initWithFrame:self.window.contentView.bounds];
    self.clockView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.window.contentView = self.clockView;

    [self.window makeKeyAndOrderFront:nil];

    // Apply the persisted mode synchronously before the window becomes visible.
    [WindowStyleManager syncWithAppStateForWindow:self.window animated:NO];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(widgetModeDidChange:)
               name:AppStateWidgetModeDidChangeNotification
             object:nil];
}

- (void)widgetModeDidChange:(NSNotification *)notification {
    [WindowStyleManager syncWithAppStateForWindow:self.window animated:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

