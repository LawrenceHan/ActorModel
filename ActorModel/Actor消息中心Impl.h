//
//  GHActor.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/20.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ActorModel/订阅者.h>
#import <ActorModel/Actor.h>

#define 地址参数开始符号 '('
#define 地址参数结束符号 ')'
#define 地址参数符号 '@'

typedef enum {
    Actor请求结果失败 = 100,
    Actor请求结果成功 = 200,
} Actor请求结果;

#ifdef DEBUG
#define dispatchOnActorQueue dispatchOnActorQueueDebug:__FILE__ line:__LINE__ block
#endif

@class Actor消息中心Impl;

#ifdef __cplusplus
extern "C" {
#endif

Actor消息中心Impl *Actor消息中心(void);

#ifdef __cplusplus
}
#endif

@interface Actor消息中心Impl : NSObject

- (dispatch_queue_t)串行ActorDispatchQueue;
#ifdef DEBUG
- (void)dispatchOnActorQueueDebug:(const char *)function line:(int)line block:(dispatch_block_t)block;
#else
- (void)dispatchOnActorQueue:(dispatch_block_t)block;
#endif

- (bool)当前是ActorDispatchQueue;

// 常用方法

- (NSString *)给地址生成泛型地址:(NSString *)地址;
- (void)请求Actor:(NSString *)地址 options:(NSDictionary *)options 订阅者:(id<订阅者>)订阅者;
- (void)请求Actor:(NSString *)地址 options:(NSDictionary *)options 订阅者:(id<订阅者>)订阅者 flags:(int)flags;

- (void)订阅该地址:(NSString *)地址 订阅者:(id<订阅者>)订阅者;
- (void)订阅该组地址:(NSArray <NSString *> *)地址数组 订阅者:(id<订阅者>)订阅者;
- (void)订阅该地址的泛型地址:(NSString *)地址 订阅者:(id<订阅者>)订阅者;

- (void)根据Handler移除订阅者:(ActionHandler *)handler;
- (void)移除订阅者:(id<订阅者>)订阅者;
- (void)根据Handler移除订阅者:(ActionHandler *)handler 从该地址:(NSString *)path;
- (void)移除订阅者:(id<订阅者>)订阅者 从该地址:(NSString *)地址;
- (void)从该地址移除所有订阅者:(NSString *)地址;

- (void)派发资源到该地址:(NSString *)地址 资源:(id)资源;
- (void)派发资源到该地址:(NSString *)地址 资源:(id)资源 options:(NSDictionary *)options;
- (void)派发进度到该地址:(NSString *)地址 进度:(CGFloat)进度;
- (void)派发消息给正在执行中的Actors:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型;
- (void)派发消息给订阅该地址的订阅者:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型;

- (void)actor请求失败:(NSString *)地址 原因:(int)原因;
- (void)actor请求完成:(NSString *)地址 结果:(id)结果;

// 不常用方法

- (void)让该地址相关的超时Actor马上取消:(NSString *)地址;

- (NSArray *)马上使该泛型地址相关Actors重订阅:(NSString *)genericPath 地址前缀:(NSString *)prefix 订阅者:(id<订阅者>)订阅者;

- (bool)是否有该泛型地址的Actor在运行:(NSString *)泛型地址;
- (bool)是否有该前缀地址的Actor在运行:(NSString *)地址前缀;
- (bool)是否有该地址的Actor在运行:(NSString *)path;

- (NSArray <Actor *>*)该地址前缀正在运行的Actors:(NSString *)地址前缀;
- (Actor *)该地址正在运行的Actor:(NSString *)地址;

#ifdef DEBUG
- (void)当前Actor消息中心状态;
#endif

@end
