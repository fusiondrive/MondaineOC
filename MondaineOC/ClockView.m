//
//  ClockView.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "ClockView.h"
#import "AppState.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

@interface ClockView () <CLLocationManagerDelegate>

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

// Text layer for location label shown only in wide-window mode
@property (nonatomic, strong) CATextLayer *locationTextLayer;
@property (nonatomic, strong) CATextLayer *weatherTextLayer;

// CoreLocation stack for real city name
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder        *geocoder;
// Resolved city; defaults to "Local" until geocoding succeeds
@property (nonatomic, copy)   NSString          *cityName;
@property (nonatomic, copy)   NSString          *weatherTemperatureText;
// Last computed layout scale, kept so appearance-only rebuilds can reuse it
@property (nonatomic, assign) CGFloat            layoutScale;

@property (nonatomic, assign) BOOL hasPerformedInitialLayout;

// Timer for clock updates
@property (nonatomic, strong) NSTimer *clockTimer;
@property (nonatomic, strong) NSTimer *refreshTimer;

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
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
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
    [self setupLocationManager];
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

    // --- Location text layer: visible only in wide-window mode ---
    // Content (NSAttributedString) is built by updateLocationTextLayerAppearance.
    self.locationTextLayer = [CATextLayer layer];
    self.locationTextLayer.alignmentMode = kCAAlignmentCenter;
    self.locationTextLayer.wrapped = YES;
    self.locationTextLayer.truncationMode = kCATruncationEnd;
    self.locationTextLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
    self.locationTextLayer.allowsFontSubpixelQuantization = YES;
    self.locationTextLayer.hidden = YES;

    self.weatherTextLayer = [CATextLayer layer];
    self.weatherTextLayer.alignmentMode = kCAAlignmentRight;
    self.weatherTextLayer.wrapped = NO;
    self.weatherTextLayer.truncationMode = kCATruncationEnd;
    self.weatherTextLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
    self.weatherTextLayer.allowsFontSubpixelQuantization = YES;
    self.weatherTextLayer.hidden = YES;

    // --- 按正确的视觉顺序将所有图层添加到主图层 ---
    [self.layer addSublayer:self.backgroundLayer];
    // Location label sits above background but beneath all clock layers
    [self.layer addSublayer:self.locationTextLayer];
    [self.layer addSublayer:self.weatherTextLayer];
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

    // Rasterize at current scale and refresh appearance-sensitive colors
    [self updateLayerImages];
    [self updateLocationTextLayerAppearance];

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

    // --- Location text label: three-state layout for landscape / portrait / square ---
    CGFloat width = NSWidth(self.bounds);
    CGFloat height = NSHeight(self.bounds);
    CGFloat clockFaceDiameter = MIN(width, height);
    CGFloat cityFontSize = MAX(14.0, 32.0 * scale);
    CGFloat dateFontSize = MAX(10.0, 16.0 * scale);
    CGFloat lineGap = MAX(4.0, 8.0 * scale);
    CGFloat textHeight = cityFontSize * 1.2 + lineGap + dateFontSize * 1.4;
    CGFloat backingScale = self.window.backingScaleFactor > 0
        ? self.window.backingScaleFactor
        : [[NSScreen mainScreen] backingScaleFactor];

    if (width > height * 1.2) {
        self.locationTextLayer.hidden = NO;
        self.weatherTextLayer.hidden = NO;

        // Store scale so appearance-only rebuilds (appearance change, geocoder callback)
        // can reuse the same font sizes without needing to recompute layout.
        self.layoutScale = scale;

        CGFloat leftSpaceWidth = (width - clockFaceDiameter) / 2.0;
        CGFloat rightSpaceWidth = (width - clockFaceDiameter) / 2.0;
        CGFloat yPos = (height - textHeight) / 2.0;
        self.locationTextLayer.frame = CGRectMake(0, yPos, leftSpaceWidth, textHeight);
        self.locationTextLayer.contentsScale = backingScale;
        self.weatherTextLayer.alignmentMode = kCAAlignmentCenter;
        self.weatherTextLayer.frame = CGRectMake(width - rightSpaceWidth,
                                                 yPos,
                                                 rightSpaceWidth,
                                                 textHeight);
        self.weatherTextLayer.contentsScale = backingScale;
        [self updateLocationTextLayerAppearance];
    } else if (height > width * 1.2) {
        self.locationTextLayer.hidden = NO;
        self.weatherTextLayer.hidden = NO;
        self.layoutScale = scale;

        CGFloat topSpaceHeight = (height - clockFaceDiameter) / 2.0;
        CGFloat yPos = height - (topSpaceHeight / 2.0) - (textHeight / 2.0);
        CGFloat weatherWidth = MIN(width * 0.4, MAX(120.0, 170.0 * scale));

        self.locationTextLayer.frame = CGRectMake(0, yPos, width, textHeight);
        self.locationTextLayer.contentsScale = backingScale;
        self.weatherTextLayer.alignmentMode = kCAAlignmentRight;
        self.weatherTextLayer.frame = CGRectMake(width - weatherWidth - (25.0 * scale),
                                                 yPos,
                                                 weatherWidth,
                                                 textHeight);
        self.weatherTextLayer.contentsScale = backingScale;
        [self updateLocationTextLayerAppearance];
    } else {
        self.locationTextLayer.hidden = YES;
        self.weatherTextLayer.hidden = YES;
    }
}


- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];

    [self updateLayerImages];
    [self updateLocationTextLayerAppearance];
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

/**
 * Rebuilds the NSAttributedString content and engraved shadow of locationTextLayer
 * to match the current effective appearance. Safe to call from any context that
 * detects an appearance change (layout, viewDidChangeEffectiveAppearance, geocoder).
 */
- (void)updateLocationTextLayerAppearance {
    NSAppearanceName bestMatch = [self.effectiveAppearance
        bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    BOOL isDark = [bestMatch isEqualToString:NSAppearanceNameDarkAqua];
    CGFloat effectiveScale = self.layoutScale > 0.0 ? self.layoutScale : (MIN(NSWidth(self.bounds), NSHeight(self.bounds)) / 800.0);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
        self.locationTextLayer.string = [self buildLocationAttributedStringWithScale:effectiveScale
                                                                              isDark:isDark];

        NSMutableParagraphStyle *weatherParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        BOOL landscapeWeather = !self.weatherTextLayer.hidden
            && self.weatherTextLayer.alignmentMode != nil
            && [self.weatherTextLayer.alignmentMode isEqualToString:kCAAlignmentCenter];
        weatherParagraphStyle.alignment = landscapeWeather ? NSTextAlignmentCenter : NSTextAlignmentRight;
        CGFloat weatherFontSize = landscapeWeather
            ? MAX(38.0, 46.0 * effectiveScale)
            : MAX(28.0, 54.0 * effectiveScale);
        NSFont *weatherFont = [NSFont systemFontOfSize:weatherFontSize weight:NSFontWeightLight];
        NSColor *primaryTextColor = isDark
            ? [NSColor colorWithWhite:0.9 alpha:1.0]
            : [NSColor colorWithWhite:0.25 alpha:1.0];
        NSString *weatherText = self.weatherTemperatureText.length > 0 ? self.weatherTemperatureText : @"";
        self.weatherTextLayer.string = [[NSAttributedString alloc] initWithString:weatherText
                                                                       attributes:@{
            NSFontAttributeName: weatherFont,
            NSForegroundColorAttributeName: primaryTextColor,
            NSParagraphStyleAttributeName: weatherParagraphStyle
        }];

        if (isDark) {
            self.locationTextLayer.shadowColor  = [NSColor blackColor].CGColor;
            self.locationTextLayer.shadowOffset = CGSizeMake(0, -1);
            self.locationTextLayer.shadowOpacity = 0.8f;
            self.locationTextLayer.shadowRadius  = 0.0;
            self.weatherTextLayer.shadowColor  = [NSColor blackColor].CGColor;
            self.weatherTextLayer.shadowOffset = CGSizeMake(0, -1);
            self.weatherTextLayer.shadowOpacity = 1.0f;
            self.weatherTextLayer.shadowRadius  = 0.0;
        } else {
            self.locationTextLayer.shadowColor  = [NSColor whiteColor].CGColor;
            self.locationTextLayer.shadowOffset = CGSizeMake(0, -1);
            self.locationTextLayer.shadowOpacity = 1.0f;
            self.locationTextLayer.shadowRadius  = 0.0;
            self.weatherTextLayer.shadowColor  = [NSColor whiteColor].CGColor;
            self.weatherTextLayer.shadowOffset = CGSizeMake(0, -1);
            self.weatherTextLayer.shadowOpacity = 1.0f;
            self.weatherTextLayer.shadowRadius  = 0.0;
        }
    }];

    [self.locationTextLayer setNeedsDisplay];
    [self.weatherTextLayer setNeedsDisplay];
    [CATransaction commit];
}

/**
 * Builds the two-line NSAttributedString: city name (black weight, large) over
 * date (light weight, small). Colors are chosen per appearance to achieve the
 * engraved letterpress illusion together with the shadow set in
 * updateLocationTextLayerAppearance.
 */
- (NSAttributedString *)buildLocationAttributedStringWithScale:(CGFloat)scale isDark:(BOOL)isDark {
    // Font sizes mirror the height calculation in layoutLayers
    CGFloat cityFontSize = MAX(14.0, floor(32.0 * scale));
    CGFloat dateFontSize = MAX(9.0,  floor(16.0 * scale));
    CGFloat lineGap = MAX(4.0, 8.0 * scale);

    NSFont *cityFont = [NSFont systemFontOfSize:cityFontSize weight:NSFontWeightMedium];
    NSFont *dateFont = [NSFont systemFontOfSize:dateFontSize weight:NSFontWeightRegular];

    // Light mode: deep charcoal city / medium gray date
    // Dark mode:  near-black city / dim gray date (glyphs must be darker than BG to carve in)
    NSColor *cityColor = isDark
        ? [NSColor colorWithWhite:0.9 alpha:1.0]
        : [NSColor colorWithWhite:0.25 alpha:1.0];
    NSColor *dateColor = isDark
        ? [NSColor colorWithWhite:0.65 alpha:1.0]
        : [NSColor colorWithWhite:0.55 alpha:1.0];

    NSMutableParagraphStyle *centered = [[NSMutableParagraphStyle alloc] init];
    centered.alignment = NSTextAlignmentCenter;
    centered.lineSpacing = lineGap;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEEE, MMMM d";
    NSString *dateString = [formatter stringFromDate:[NSDate date]];

    NSString *city = self.cityName.length > 0 ? self.cityName : @"Local";

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    // City line (with trailing newline so the date starts on the next line)
    [result appendAttributedString:[[NSAttributedString alloc]
        initWithString:[city stringByAppendingString:@"\n"]
            attributes:@{ NSFontAttributeName: cityFont,
                          NSForegroundColorAttributeName: cityColor,
                          NSParagraphStyleAttributeName: centered }]];

    // Date line
    [result appendAttributedString:[[NSAttributedString alloc]
        initWithString:dateString
            attributes:@{ NSFontAttributeName: dateFont,
                          NSForegroundColorAttributeName: dateColor,
                          NSParagraphStyleAttributeName: centered }]];

    [result addAttribute:NSParagraphStyleAttributeName
                   value:centered
                   range:NSMakeRange(0, result.length)];

    return result;
}

#pragma mark - Location

/**
 * Initializes CLLocationManager, requests when-in-use authorization, then
 * fires a single one-shot location request. The result is reverse-geocoded
 * to a city name; on success cityName is updated and the label redrawn.
 */
- (void)setupLocationManager {
    self.cityName = @"Local";    // fallback until geocoding succeeds
    self.weatherTemperatureText = @"";
    self.layoutScale = 0.0;

    self.geocoder = [[CLGeocoder alloc] init];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestLocation];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1800.0
                                                         target:self
                                                       selector:@selector(triggerDataRefresh)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)triggerDataRefresh {
    [self.locationManager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    if (!location) return;

    [self fetchWeatherForCoordinate:location.coordinate];

    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
        if (error || placemarks.count == 0) {
            NSLog(@"Geocoder failed: %@", error.localizedDescription);
            return;
        }
        CLPlacemark *placemark = placemarks.firstObject;
        // Prefer locality (city); fall back to sub-administrative area
        NSString *city = placemark.locality
                      ?: placemark.subAdministrativeArea
                      ?: @"Local";
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cityName = city;
            // Redraw the label with the real city name; frame is already set
            [self updateLocationTextLayerAppearance];
        });
    }];
}

- (void)fetchWeatherForCoordinate:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:
        @"https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f&current_weather=true&temperature_unit=fahrenheit",
        coordinate.latitude,
        coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || data.length == 0) {
            NSLog(@"Weather request failed: %@", error.localizedDescription);
            return;
        }

        NSError *jsonError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Weather JSON parse failed: %@", jsonError.localizedDescription);
            return;
        }

        NSDictionary *jsonDictionary = (NSDictionary *)jsonObject;
        NSDictionary *currentWeather = jsonDictionary[@"current_weather"];
        NSNumber *temperature = [currentWeather isKindOfClass:[NSDictionary class]]
            ? currentWeather[@"temperature"]
            : nil;
        if (![temperature isKindOfClass:[NSNumber class]]) {
            return;
        }

        NSString *temperatureText = [NSString stringWithFormat:@"%ld°", lround(temperature.doubleValue)];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.weatherTemperatureText = temperatureText;
            self.weatherTextLayer.string = temperatureText;
            [self updateLocationTextLayerAppearance];
        });
    }];

    [task resume];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    // Log full error object so Xcode console shows domain, code, and description
    NSLog(@"Location Error: %@", error);
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
    [self.minuteHandLayer removeAllAnimations];

    CGFloat previousMinute = (minute == 0) ? 59 : minute - 1;
    CGFloat fromAngle = (previousMinute / 60.0) * 2.0 * M_PI;
    CGFloat toAngle   = (minute       / 60.0) * 2.0 * M_PI;

    CABasicAnimation *jumpAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    jumpAnimation.fromValue      = @(-fromAngle);
    jumpAnimation.duration       = 0.25;
    jumpAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    if (minute == 0) {
        // 59->0 wraparound: target -2π instead of 0 so CA interpolates clockwise
        // by ~6° rather than counterclockwise by ~354°.
        jumpAnimation.toValue = @(-M_PI * 2.0);
        self.minuteHandLayer.transform = CATransform3DMakeRotation(-M_PI * 2.0, 0, 0, 1);

        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            // Normalize silently: -2π and 0 are visually identical,
            // but keeping -2π would accumulate across subsequent wraps.
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.minuteHandLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
            [CATransaction commit];
        }];
        [self.minuteHandLayer addAnimation:jumpAnimation forKey:@"minuteHandJump"];
        [CATransaction commit];
    } else {
        jumpAnimation.toValue = @(-toAngle);
        self.minuteHandLayer.transform = CATransform3DMakeRotation(-toAngle, 0, 0, 1);
        [self.minuteHandLayer addAnimation:jumpAnimation forKey:@"minuteHandJump"];
    }
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
