//
//  AppState.h
//  MondaineOC
//
//  全局应用状态管理器，等价于 SwiftUI 的 @Published + @AppStorage 组合。
//  使用 NSNotificationCenter 广播状态变化，使各组件无需强引用即可响应。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 当 isWidgetMode 发生变化时广播此通知。
/// object 为 AppState 实例，userInfo 中无附加信息。
extern NSString * const AppStateWidgetModeDidChangeNotification;

/**
 * @class AppState
 * @brief 应用全局状态单例。
 *
 * 负责持久化并广播 isWidgetMode 状态：
 *   - 读取时从 NSUserDefaults 恢复上次的选择
 *   - 写入时自动同步到 NSUserDefaults 并发出通知
 *
 * 使用方式:
 *   [AppState sharedState].isWidgetMode = YES;
 *
 * 监听变化:
 *   [[NSNotificationCenter defaultCenter]
 *       addObserver:self
 *          selector:@selector(widgetModeDidChange:)
 *              name:AppStateWidgetModeDidChangeNotification
 *            object:nil];
 */
@interface AppState : NSObject

/// 是否处于桌面小组件模式。
/// 赋值时自动持久化并发出 AppStateWidgetModeDidChangeNotification。
@property (nonatomic, assign) BOOL isWidgetMode;

/// 返回全局单例
+ (instancetype)sharedState;

/// 禁止直接 init（请使用 +sharedState）
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
