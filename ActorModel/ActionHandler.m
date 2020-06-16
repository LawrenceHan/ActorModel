//
//  ActionHandler.m
//  ActorModel
//
//  Created by Lawrence on 2020/5/20.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "ActionHandler.h"
#import "互斥锁.h"
#import "订阅者.h"

@interface ActionHandler() {
    互斥锁_定义(_订阅者);
}
@end

@implementation ActionHandler

@synthesize 订阅者 = _订阅者;

- (instancetype)initWithSubscriber:(id<订阅者>)订阅者 {
    return [self initWithSubscriber:订阅者 是否在主线程释放:true];
}

- (instancetype)initWithSubscriber:(id<订阅者>)订阅者 是否在主线程释放:(bool)是否在主线程释放 {
    self = [super init];
    if (self != nil) {
        互斥锁_初始化(_订阅者);
        _订阅者 = 订阅者;
        _是否在主线程释放 = 是否在主线程释放;
    }
    return self;
}

- (void)重置 {
    互斥锁_加锁(_订阅者);
    _订阅者 = nil;
    互斥锁_解锁(_订阅者);
}

- (bool)是否有订阅者 {
    bool result = false;
    
    互斥锁_加锁(_订阅者);
    result = _订阅者 != nil;
    互斥锁_解锁(_订阅者);
    
    return result;
}

- (id<订阅者>)订阅者 {
    id<订阅者> result = nil;
    
    互斥锁_加锁(_订阅者);
    result = _订阅者;
    互斥锁_解锁(_订阅者);
    
    return result;
}

- (void)set订阅者:(id<订阅者>)订阅者 {
    互斥锁_加锁(_订阅者);
    _订阅者 = 订阅者;
    互斥锁_解锁(_订阅者);
}

- (void)通知操作请求:(NSString *)操作 options:(NSDictionary *)options {
    __strong id<订阅者> subscriber = self.订阅者;
    if (subscriber != nil && [subscriber respondsToSelector:@selector(收到操作请求:options:)]) {
        [subscriber 收到操作请求:操作 options:options];
    }
    
    if (_是否在主线程释放 && ![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [subscriber class];
        });
    }
}

- (void)通知该地址收到消息:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型 {
    __strong id<订阅者> subscriber = self.订阅者;
    if (subscriber != nil && [subscriber respondsToSelector:@selector(收到该地址消息:消息:消息类型:)]) {
        [subscriber 收到该地址消息:地址 消息:消息 消息类型:消息类型];
    }
    
    if (_是否在主线程释放 && ![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [subscriber class];
        });
    }
}

- (void)通知该地址收到资源:(NSString *)地址 资源:(id)资源 options:(NSDictionary *)options {
    __strong id<订阅者> subscriber = self.订阅者;
    if (subscriber != nil && [subscriber respondsToSelector:@selector(收到该地址资源:资源:options:)]) {
        [subscriber 收到该地址资源:地址 资源:资源 options:options];
    }
    
    if (_是否在主线程释放 && ![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [subscriber class];
        });
    }
}

@end
