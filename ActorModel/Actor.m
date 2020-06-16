//
//  GHActor.m
//  ActorModel
//
//  Created by Lawrence on 2020/5/21.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "Actor.h"
#import "可取消协议.h"

static NSMutableDictionary *registeredActorClasses() {
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

@implementation Actor

+ (void)注册Actor:(Class)actorClass {
    NSString *genericPath = [actorClass 泛型地址];
    if (genericPath == nil || genericPath.length == 0) {
        NSLog(@"[ActorModel] Error: GHActor::registerActor genericPath is nil");
        return;
    }
    
    registeredActorClasses()[genericPath] = actorClass;
}

+ (Actor *)泛型地址对应的Actor类:(NSString *)genericPath 地址:(NSString *)path {
    Class actorClass = registeredActorClasses()[genericPath];
    if (actorClass != nil) {
        Actor *instance = [[actorClass alloc] initWith地址:path];
        return instance;
    }
    return nil;
}

+ (NSString *)泛型地址 {
    @throw [NSException exceptionWithName:@"[ActorModel]" reason:@"Error: GHActor::genericPath: subclass needs to implement" userInfo:nil];
    return nil;
}

- (instancetype)initWith地址:(NSString *)地址 {
    self = [super init];
    if (self) {
        _超时时长 = 0;
        _地址 = 地址;
    }
    return self;
}

- (void)准备:(NSDictionary *)options {}

- (void)执行:(NSDictionary *)options {
    @throw [NSException exceptionWithName:@"[ActorModel]" reason:@"Error: GHActor::execute: subclass needs to implement" userInfo:nil];
}

- (void)取消 {
    if (_取消Token != nil) {
        [_取消Token 取消];
        _取消Token = nil;
    }
    
    if (_取消Token数组.count) {
        for (id<可取消协议> token in _取消Token数组) {
            [token 取消];
        }
        _取消Token数组 = nil;
    }
    
    _已取消 = true;
}

- (void)添加取消Token:(id<可取消协议>)token {
    if (_取消Token数组 == nil) {
        _取消Token数组 = [NSMutableArray new];
    }
    [_取消Token数组 addObject:token];
}

- (void)新订阅者加入:(ActionHandler *)actionHandler options:(NSDictionary *)options 已在当前队列中:(bool)waitingInActorQueue {}

@end
