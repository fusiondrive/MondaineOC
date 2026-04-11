//
//  ClockView.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "ClockView.h"
#import "AppState.h"
#import <QuartzCore/QuartzCore.h>

@interface ClockView ()

// Layer for clock animation
@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) CALayer *clockFaceLayer;
@property (nonatomic, strong) CALayer *indicatorLayer;

@property (nonatomic, strong) CALayer *hourHandLayer;
@property (nonatomic, strong) CALayer *hourHandContainerLayer;
@property (nonatomic, strong) CALayer *minuteHandLayer;
@property (nonatomic, strong) CALayer *minuteHandContainerLayer;
@property (nonatomic, strong) CALayer *secondHandLayer;
@property (nonatomic, strong) CALayer *secondHandContainerLayer;

@property (nonatomic, assign) BOOL hasPerformedInitialLayout;

// Timer for clock updates
@property (nonatomic, strong) NSTimer *clockTimer;

@end

@implementation ClockView

#pragma mark - initialize

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)dealloc {
    // prevent memory leaks
    [self.clockTimer invalidate];
    self.clockTimer = nil;
}

#pragma mark - View Settings

/**
 * Set up the view and layers.
 * Configure this view as a layer-hosting view,  create and configure all sublayers.
 */
- (void)setupView {
    // setup layer support
    self.wantsLayer = YES;
    
    [self setupLayers];
    
    [self startClock];
}

/**
 * 创建并配置时钟的所有 CALayer 组件。
 */
- (void)setupLayers {
    // --- 创建基础图层 ---
    self.backgroundLayer = [self createLayerWithImageNamed:@"BG"];
    self.backgroundLayer.contentsGravity = kCAGravityResizeAspectFill;

    // --- 创建表盘和刻度，并为它们应用“原始风格”的微妙阴影 ---
    self.clockFaceLayer = [self createLayerWithImageNamed:@"ClockFace"];
    self.clockFaceLayer.shadowColor = [NSColor blackColor].CGColor;
    self.clockFaceLayer.shadowOpacity = 0.5;
    self.clockFaceLayer.shadowOffset = CGSizeMake(0, -2);
    self.clockFaceLayer.shadowRadius = 5.0;

    self.indicatorLayer = [self createLayerWithImageNamed:@"ClockIndicator"];
    self.indicatorLayer.shadowColor = [NSColor blackColor].CGColor;
    self.indicatorLayer.shadowOpacity = 0.5;
    self.indicatorLayer.shadowOffset = CGSizeMake(0, -2);
    self.indicatorLayer.shadowRadius = 5.0;

    // --- 创建指针图层，并为它们应用“增强的晕影” ---
    // 时针
    self.hourHandLayer = [self createLayerWithImageNamed:@"HOURBAR"];
    self.hourHandLayer.anchorPoint = CGPointMake(0.5, 0.5);
    self.hourHandLayer.shadowColor = [NSColor blackColor].CGColor;
    self.hourHandLayer.shadowRadius = 15.0; // 更大的模糊，实现“晕感”
    self.hourHandLayer.shadowOpacity = 0.6; // 更深的不透明度
    self.hourHandLayer.shadowOffset = CGSizeMake(0, 5);  // 光从上往下打的效果

    // 分针
    self.minuteHandLayer = [self createLayerWithImageNamed:@"MINBAR"];
    self.minuteHandLayer.anchorPoint = CGPointMake(0.5, 0.5);
    self.minuteHandLayer.shadowColor = [NSColor blackColor].CGColor;
    self.minuteHandLayer.shadowRadius = 15.0;
    self.minuteHandLayer.shadowOpacity = 0.6;
    self.minuteHandLayer.shadowOffset = CGSizeMake(0, 5);

    // 秒针
    self.secondHandLayer = [self createLayerWithImageNamed:@"REDINDICATOR"];
    self.secondHandLayer.anchorPoint = CGPointMake(0.5, 0.5);
    self.secondHandLayer.shadowColor = [NSColor blackColor].CGColor;
    self.secondHandLayer.shadowRadius = 10.0; // 秒针阴影可以稍轻一些
    self.secondHandLayer.shadowOpacity = 0.5;
    self.secondHandLayer.shadowOffset = CGSizeMake(0, 3);

    // --- 按正确的视觉顺序将所有图层添加到主图层 ---
    [self.layer addSublayer:self.backgroundLayer];
    [self.layer addSublayer:self.clockFaceLayer];
    [self.layer addSublayer:self.indicatorLayer];
    [self.layer addSublayer:self.hourHandLayer];
    [self.layer addSublayer:self.minuteHandLayer];
    [self.layer addSublayer:self.secondHandLayer];
}

/**
 * Create a CALayer based on the provided image name
 * @param imageName name in the resource directory
 * @return CALayer instance configured with image content
 */
- (CALayer *)createLayerWithImageNamed:(NSString *)imageName {
    NSImage *image = [NSImage imageNamed:imageName];
    if (!image) {
        NSLog(@"警告: 无法加载图片 '%@'", imageName);
        return [CALayer layer];
    }
    
    CALayer *layer = [CALayer layer];
    layer.contentsGravity = kCAGravityResizeAspect;
    
    
    return layer;
}



#pragma mark - layout & drawing

- (void)layout {
    [super layout];
    [self layoutLayers];

    // bounds 每次变化都重新光栅化，确保缩放后图片清晰
    [self updateLayerImages];

    if (!self.hasPerformedInitialLayout) {
        [self updateClockHands:nil];
        self.hasPerformedInitialLayout = YES;
    }
}

- (void)layoutLayers {
    // 以最短边为基准，计算相对于原始 800pt 设计画布的缩放比
    CGFloat size = MIN(NSWidth(self.bounds), NSHeight(self.bounds));
    CGFloat scale = size / 800.0;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    // 背景始终铺满整个视图
    self.backgroundLayer.frame = self.bounds;

    // --- ClockFace: 原始 785×785, position offset (0, +6) ---
    self.clockFaceLayer.bounds = CGRectMake(0, 0, 785 * scale, 785 * scale);
    self.clockFaceLayer.position = CGPointMake(center.x, center.y + 6 * scale);

    // --- ClockIndicator: 原始 725×725, position offset (0, -2) ---
    self.indicatorLayer.bounds = CGRectMake(0, 0, 725 * scale, 725 * scale);
    self.indicatorLayer.position = CGPointMake(center.x, center.y - 2 * scale);

    // --- HOURBAR: 原始 37×454, 居中 ---
    self.hourHandLayer.bounds = CGRectMake(0, 0, 37 * scale, 454 * scale);
    self.hourHandLayer.position = center;

    // --- MINBAR: 原始 37×645, 居中 ---
    self.minuteHandLayer.bounds = CGRectMake(0, 0, 37 * scale, 645 * scale);
    self.minuteHandLayer.position = center;

    // --- REDINDICATOR: 原始 66×567, 居中 ---
    self.secondHandLayer.bounds = CGRectMake(0, 0, 66 * scale, 567 * scale);
    self.secondHandLayer.position = center;
}


- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    
    [self updateLayerImages];
}


- (void)updateLayerImages {
    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        CGImageRef (^cgImageForLayer)(NSString *, CALayer *) = ^CGImageRef(NSString *imageName, CALayer *layer) {
            NSImage *image = [NSImage imageNamed:imageName];
            if (!image) return NULL;
            CGRect imageRect = layer.bounds;
            return [image CGImageForProposedRect:&imageRect context:nil hints:nil];
        };
        
        self.backgroundLayer.contents = (__bridge id)cgImageForLayer(@"BG", self.backgroundLayer);
        self.clockFaceLayer.contents = (__bridge id)cgImageForLayer(@"ClockFace", self.clockFaceLayer);
        self.indicatorLayer.contents = (__bridge id)cgImageForLayer(@"ClockIndicator", self.indicatorLayer);
        self.hourHandLayer.contents = (__bridge id)cgImageForLayer(@"HOURBAR", self.hourHandLayer);
        self.minuteHandLayer.contents = (__bridge id)cgImageForLayer(@"MINBAR", self.minuteHandLayer);
        self.secondHandLayer.contents = (__bridge id)cgImageForLayer(@"REDINDICATOR", self.secondHandLayer);
    }];
}

#pragma mark - Clock logic and animation

/**
 * Start clock timer
 */
- (void)startClock {
    self.clockTimer = [NSTimer timerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(updateClockHands:)
                                            userInfo:nil
                                             repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:self.clockTimer forMode:NSRunLoopCommonModes];
}

/**
 * update all pointers
 */
- (void)updateClockHands:(NSTimer *)timer {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:now];
    
    NSInteger hour = components.hour;
    NSInteger minute = components.minute;
    NSInteger second = components.second;
    
    // hour / minute animations
    CGFloat hoursAngle = (hour % 12 + minute / 60.0) / 12.0 * 360.0;
    CGFloat minutesAngle = minute / 60.0 * 360.0;
    
    // Update hour and minute (no animation)
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    // z: 1 -> -1
    self.hourHandLayer.transform = CATransform3DMakeRotation(-(hoursAngle * M_PI / 180.0), 0, 0, 1);
    self.minuteHandLayer.transform = CATransform3DMakeRotation(-(minutesAngle * M_PI / 180.0), 0, 0, 1);

    [CATransaction commit];
    
    // process "stop2go" for second
    [self updateSecondHandAnimationForSecond:second minute:minute];
}

/**
 * Manages "stop2go" animation of the second
 */
- (void)updateSecondHandAnimationForSecond:(NSInteger)second minute:(NSInteger)minute {
    
    if (second == 0) {
        // --- start on 00" ---
        
        [self.secondHandLayer removeAllAnimations];
        self.secondHandLayer.transform = CATransform3DIdentity;
        [self animateMinuteHandJumpForMinute:minute];

        // new round
        CABasicAnimation *sweepAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        sweepAnimation.fromValue = @(0);
        sweepAnimation.toValue = @(-2 * M_PI);
        sweepAnimation.duration = 58.5;
        sweepAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        sweepAnimation.removedOnCompletion = NO;
        sweepAnimation.fillMode = kCAFillModeForwards;

        [self.secondHandLayer addAnimation:sweepAnimation forKey:@"secondHandAnimation"];

    } else {
        // --- start in second 01"-59"---
        
        // 检查秒针当前是否已经有动画了，如果还没有...
        if ([self.secondHandLayer animationForKey:@"secondHandAnimation"] == nil) {
            
            // 创建一个标准的平滑动画
            CABasicAnimation *sweepAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            sweepAnimation.fromValue = @(0);
            sweepAnimation.toValue = @(-2 * M_PI);
            sweepAnimation.duration = 58.5;
            sweepAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            sweepAnimation.removedOnCompletion = NO;
            sweepAnimation.fillMode = kCAFillModeForwards;

            // --- 这是最关键的最终修正 ---
            // 告诉动画，它的开始时间是在 N 秒之前
            // CACurrentMediaTime() 是当前的绝对时间
            sweepAnimation.beginTime = [self.secondHandLayer convertTime:CACurrentMediaTime() fromLayer:nil] - second;
            
            [self.secondHandLayer addAnimation:sweepAnimation forKey:@"secondHandAnimation"];
        }
    }
}

/**
 * animation for the minute to jump forward at the start of each minute
 */
- (void)animateMinuteHandJumpForMinute:(NSInteger)minute {
    // remove previous animations
    [self.minuteHandLayer removeAllAnimations];
    
    // Calculate the angle
    CGFloat previousMinute = (minute == 0) ? 59 : minute - 1;
    CGFloat fromAngle = (previousMinute / 60.0) * 360.0 * M_PI / 180.0;
    CGFloat toAngle = (minute / 60.0) * 360.0 * M_PI / 180.0;

    CABasicAnimation *jumpAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];

    // Invert angles animation
    jumpAnimation.fromValue = @(-(fromAngle));
    jumpAnimation.toValue = @(-(toAngle));

    jumpAnimation.duration = 0.25;
    jumpAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    // 将最终设置的角度也取反，并将 z 轴改回 1
    self.minuteHandLayer.transform = CATransform3DMakeRotation(-(toAngle), 0, 0, 1);
    [self.minuteHandLayer addAnimation:jumpAnimation forKey:@"minuteHandJump"];
}

#pragma mark - Right-click Menu

- (NSMenu *)menuForEvent:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    BOOL isWidgetMode = [AppState sharedState].isWidgetMode;
    NSString *toggleTitle = isWidgetMode ? @"退出悬浮小组件模式" : @"切换悬浮小组件模式";
    NSMenuItem *toggleItem = [[NSMenuItem alloc]
        initWithTitle:toggleTitle
               action:@selector(toggleWidgetMode:)
        keyEquivalent:@""];
    toggleItem.target = self;
    [menu addItem:toggleItem];

    // Size presets are only meaningful in borderless widget mode.
    if (isWidgetMode) {
        NSMenuItem *sizeParentItem = [[NSMenuItem alloc]
            initWithTitle:@"小组件尺寸"
                   action:nil
            keyEquivalent:@""];

        NSMenu *sizeSubmenu = [[NSMenu alloc] initWithTitle:@"小组件尺寸"];

        struct { NSString *title; NSInteger size; } presets[] = {
            { @"小 (160×160)", 160 },
            { @"中 (240×240)", 240 },
            { @"大 (320×320)", 320 },
        };
        for (int i = 0; i < 3; i++) {
            NSMenuItem *item = [[NSMenuItem alloc]
                initWithTitle:presets[i].title
                       action:@selector(resizeWidgetToPreset:)
                keyEquivalent:@""];
            item.target = self;
            item.tag = presets[i].size;
            [sizeSubmenu addItem:item];
        }

        sizeParentItem.submenu = sizeSubmenu;
        [menu addItem:sizeParentItem];
    }

    NSMenuItem *quitItem = [[NSMenuItem alloc]
        initWithTitle:@"退出应用"
               action:@selector(terminate:)
        keyEquivalent:@""];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

- (void)toggleWidgetMode:(id)sender {
    [AppState sharedState].isWidgetMode = ![AppState sharedState].isWidgetMode;
}

- (void)resizeWidgetToPreset:(NSMenuItem *)sender {
    NSWindow *window = self.window;
    if (!window) return;

    CGFloat newSize = (CGFloat)sender.tag;

    // Expand/contract symmetrically around the current window center.
    NSRect oldFrame = window.frame;
    NSRect newFrame = NSMakeRect(NSMidX(oldFrame) - newSize / 2.0,
                                 NSMidY(oldFrame) - newSize / 2.0,
                                 newSize,
                                 newSize);
    [window setFrame:newFrame display:YES animate:YES];
}

@end

