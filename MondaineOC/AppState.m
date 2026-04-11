//
//  AppState.m
//  MondaineOC
//

#import "AppState.h"

static NSString * const kWidgetModeUserDefaultsKey = @"MondaineOC.isWidgetMode";

NSString * const AppStateWidgetModeDidChangeNotification = @"AppStateWidgetModeDidChangeNotification";

@implementation AppState

#pragma mark - Singleton

+ (instancetype)sharedState {
    static AppState *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] initPrivate];
    });
    return _sharedInstance;
}

/// Designated private initializer. Restores the last persisted mode from NSUserDefaults.
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _isWidgetMode = [[NSUserDefaults standardUserDefaults] boolForKey:kWidgetModeUserDefaultsKey];
    }
    return self;
}

#pragma mark - Property Override

- (void)setIsWidgetMode:(BOOL)isWidgetMode {
    if (_isWidgetMode == isWidgetMode) return;

    _isWidgetMode = isWidgetMode;

    [[NSUserDefaults standardUserDefaults] setBool:isWidgetMode forKey:kWidgetModeUserDefaultsKey];

    // Post on the main queue so observers can safely drive UI updates directly.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:AppStateWidgetModeDidChangeNotification
                          object:self];
    });
}

@end
