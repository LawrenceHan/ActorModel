//
//  ActionHandler.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/20.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol 订阅者;

@interface ActionHandler : NSObject

@property (nonatomic, weak) id<订阅者> 订阅者;
@property (nonatomic) bool 是否在主线程释放;

- (instancetype)initWithSubscriber:(id<订阅者>)订阅者;
- (instancetype)initWithSubscriber:(id<订阅者>)订阅者 是否在主线程释放:(bool)是否在主线程释放;

- (void)重置;
- (bool)是否有订阅者;

- (void)通知操作请求:(NSString *)操作 options:(NSDictionary *)options;
- (void)通知该地址收到消息:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型;
- (void)通知该地址收到资源:(NSString *)地址 资源:(id)资源 options:(NSDictionary *)options;

@end
