//
//  WindowStyleManager.m
//  MondaineOC
//

#import "WindowStyleManager.h"
#import "AppState.h"

static const NSWindowStyleMask kNormalStyleMask =
    NSWindowStyleMaskTitled         |
    NSWindowStyleMaskClosable       |
    NSWindowStyleMaskResizable      |
    NSWindowStyleMaskMiniaturizable;

static const NSTimeInterval kTransitionDuration = 0.25;

@implementation WindowStyleManager

#pragma mark - Public API

+ (void)applyWidgetMode:(BOOL)widgetMode
               toWindow:(NSWindow *)window
               animated:(BOOL)animated {
    if (!window) return;

    if (animated) {
        [self performTransitionOnWindow:window block:^{
            if (widgetMode) {
                [self _applyWidgetModeToWindow:window];
            } else {
                [self _applyNormalModeToWindow:window];
            }
        }];
    } else {
        if (widgetMode) {
            [self _applyWidgetModeToWindow:window];
        } else {
            [self _applyNormalModeToWindow:window];
        }
    }
}

+ (void)syncWithAppStateForWindow:(NSWindow *)window animated:(BOOL)animated {
    BOOL widgetMode = [AppState sharedState].isWidgetMode;
    [self applyWidgetMode:widgetMode toWindow:window animated:animated];
}

#pragma mark - Private: Apply Widget Mode

/// Configures the window as a floating, borderless, transparent widget.
+ (void)_applyWidgetModeToWindow:(NSWindow *)window {
    window.styleMask = NSWindowStyleMaskBorderless;

    window.backgroundColor = NSColor.clearColor;
    window.opaque = NO;
    window.hasShadow = YES;

    // NSFloatingWindowLevel sits above normal windows but below panels and menus.
    window.level = NSFloatingWindowLevel;

    window.collectionBehavior =
        NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorStationary       |
        NSWindowCollectionBehaviorIgnoresCycle;

    // Allow drag-to-move since there is no title bar.
    window.movableByWindowBackground = YES;

    NSView *contentView = window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.cornerRadius = 32.0;
    contentView.layer.cornerCurve = kCACornerCurveContinuous;
    contentView.layer.masksToBounds = YES;

    [window makeKeyAndOrderFront:nil];

    // Force AppKit to recompute the shadow shape from the masked, rounded content view.
    [window invalidateShadow];
}

#pragma mark - Private: Apply Normal Mode

/// Restores the window to its standard titled, opaque, normal-level state.
+ (void)_applyNormalModeToWindow:(NSWindow *)window {
    window.styleMask = kNormalStyleMask;

    window.backgroundColor = NSColor.windowBackgroundColor;
    window.opaque = YES;
    window.hasShadow = YES;

    window.level = NSNormalWindowLevel;
    window.collectionBehavior = NSWindowCollectionBehaviorDefault;
    window.movableByWindowBackground = NO;

    NSView *contentView = window.contentView;
    contentView.layer.cornerRadius = 0.0;
    contentView.layer.masksToBounds = NO;

    [window makeKeyAndOrderFront:nil];
}

#pragma mark - Private: Transition Animation

/// Wraps a style-mutation block in a fade-out/in animation.
/// Mutating styleMask mid-animation causes visual artifacts; the fade hides them.
+ (void)performTransitionOnWindow:(NSWindow *)window block:(void (^)(void))styleBlock {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kTransitionDuration;
        window.animator.alphaValue = 0.0;
    } completionHandler:^{
        styleBlock();
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = kTransitionDuration;
            window.animator.alphaValue = 1.0;
        } completionHandler:nil];
    }];
}

@end
