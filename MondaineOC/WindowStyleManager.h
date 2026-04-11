//
//  WindowStyleManager.h
//  MondaineOC
//
//  负责动态控制 NSWindow 的双形态样式切换。
//  等价于 SwiftUI 中通过 WindowModifier 修改 NSWindow 属性的桥接层。
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class WindowStyleManager
 * @brief NSWindow 双形态样式控制器（纯静态工具类）
 *
 * 封装了普通窗口模式和桌面小组件模式之间的所有 NSWindow 属性差异：
 *
 *   普通窗口模式（isWidgetMode = NO）：
 *     - styleMask:  .titled | .closable | .resizable | .miniaturizable
 *     - background: NSColor.windowBackgroundColor（不透明）
 *     - level:      NSNormalWindowLevel
 *
 *   桌面小组件模式（isWidgetMode = YES）：
 *     - styleMask:  .borderless（无标题栏、无控制按钮）
 *     - background: NSColor.clearColor（完全透明）
 *     - level:      NSFloatingWindowLevel（悬浮置顶）
 *
 * 典型用法（在 AppDelegate 中）：
 *   [WindowStyleManager applyWidgetMode:YES toWindow:self.window animated:YES];
 */
@interface WindowStyleManager : NSObject

/**
 * 切换窗口到指定模式。
 *
 * @param widgetMode  YES = 小组件模式，NO = 普通窗口模式
 * @param window      目标 NSWindow 实例
 * @param animated    是否使用淡入淡出过渡动画
 */
+ (void)applyWidgetMode:(BOOL)widgetMode
               toWindow:(NSWindow *)window
               animated:(BOOL)animated;

/**
 * 便捷方法：根据 AppState.sharedState.isWidgetMode 自动判断并应用对应模式。
 *
 * @param window    目标 NSWindow 实例
 * @param animated  是否使用淡入淡出过渡动画
 */
+ (void)syncWithAppStateForWindow:(NSWindow *)window animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
