//
//  ClockView.h
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ClockView
 * @brief A custom view that animates a Swiss National Railway clock with a "stop-to-go" feature.
 *
 * This view uses CALayer to render the clock's parts (face, hands),
 * and uses NSTimer and Core Animation to drive the movement of the hands.
 */
@interface ClockView : NSView

@end

NS_ASSUME_NONNULL_END
