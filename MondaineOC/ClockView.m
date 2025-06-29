//
//  ClockView.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "ClockView.h"
#import <QuartzCore/QuartzCore.h>

@interface ClockView ()

// Layer for clock animation
@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) CALayer *clockFaceLayer;
@property (nonatomic, strong) CALayer *indicatorLayer;
@property (nonatomic, strong) CALayer *hourHandLayer;
@property (nonatomic, strong) CALayer *minuteHandLayer;
@property (nonatomic, strong) CALayer *secondHandLayer;
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
    // setup backgroundLayer
    self.backgroundLayer = [self createLayerWithImageNamed:@"BG"];
    self.backgroundLayer.contentsGravity = kCAGravityResizeAspectFill;

    // clockFaceLayer
    self.clockFaceLayer = [self createLayerWithImageNamed:@"ClockFace"];
    
    // indicatorLayer
    self.indicatorLayer = [self createLayerWithImageNamed:@"ClockIndicator"];
    
    // hourHandLayer
    self.hourHandLayer = [self createLayerWithImageNamed:@"HOURBAR"];
    self.hourHandLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
    // minuteHandLayer
    self.minuteHandLayer = [self createLayerWithImageNamed:@"MINBAR"];
    self.minuteHandLayer.anchorPoint = CGPointMake(0.5, 0.5);

    // secondHandLayer
    self.secondHandLayer = [self createLayerWithImageNamed:@"REDINDICATOR"];
    self.secondHandLayer.anchorPoint = CGPointMake(0.5, 0.5);

    // Add all layers to main layer
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
    //layer.contents = image;
    layer.contentsGravity = kCAGravityResizeAspect;
    
    // SwiftUI's .shadow
    layer.shadowColor = [NSColor blackColor].CGColor;
    layer.shadowOpacity = 0.5;
    layer.shadowOffset = CGSizeMake(0, -2); // revert coordinate
    layer.shadowRadius = 5.0;
    
    return layer;
}



#pragma mark - layout & drawing

- (void)layout {
    [super layout];
    [self layoutLayers];
    
    if (!self.hasPerformedInitialLayout) {
        [self updateLayerImages];
        [self updateClockHands:nil];

        self.hasPerformedInitialLayout = YES;
    }
}

- (void)layoutLayers {
    // fill bg
    self.backgroundLayer.frame = self.bounds;
    
    // get centerPoint
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    // --- ClockFace ---
    // SwiftUI: .frame(width: 785, height: 785)
    self.clockFaceLayer.bounds = CGRectMake(0, 0, 785, 785);
    self.clockFaceLayer.position = centerPoint;

    // --- ClockIndicator ---
    // SwiftUI: .frame(width: 730, height: 730), .offset(y: 4)
    self.indicatorLayer.bounds = CGRectMake(0, 0, 730, 730);
    // 注意：CALayer 的坐标系 y 轴向上，SwiftUI 的 offset y 轴向下，所以这里用减法
    self.indicatorLayer.position = CGPointMake(centerPoint.x, centerPoint.y - 4);

    // --- HOURBAR ---
    // SwiftUI: .frame(width: 50, height: 433.87)
    self.hourHandLayer.bounds = CGRectMake(0, 0, 50, 433.87);
    self.hourHandLayer.position = centerPoint; // 同样居中

    // --- MINBAR ---
    // SwiftUI: .frame(width: 50, height: 685.73)
    self.minuteHandLayer.bounds = CGRectMake(0, 0, 50, 685.73);
    self.minuteHandLayer.position = centerPoint;

    // --- REDINDICATOR ---
    // SwiftUI: .frame(width: 383, height: 579), .offset(y: -1)
    self.secondHandLayer.bounds = CGRectMake(0, 0, 383, 579);
    // 这里 SwiftUI 是 y: -1，对应 CALayer 就是 y 轴正向移动
    self.secondHandLayer.position = CGPointMake(centerPoint.x, centerPoint.y + 1);
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
    // When a minute starts (second == 0)
    if (second == 0) {
        // JumpForMinute
        [self animateMinuteHandJumpForMinute:minute];
        
        // 58.5s
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = @(0);
        animation.toValue = @(-2 * M_PI);
        animation.duration = 58.5;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        
        [self.secondHandLayer addAnimation:animation forKey:@"secondHandAnimation"];

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

@end

