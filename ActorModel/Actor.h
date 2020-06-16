//
//  GHActor.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/21.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ActorModel/ActionHandler.h>

@protocol 可取消协议;

@interface Actor : NSObject

+ (void)注册Actor:(Class)actorClass;
+ (Actor *)泛型地址对应的Actor类:(NSString *)genericPath 地址:(NSString *)path;
+ (NSString *)泛型地址;

@property (nonatomic, strong) NSString *地址;
@property (nonatomic, strong) NSString *请求队列名称;
@property (nonatomic, strong) NSDictionary *已储存的Options;

@property (nonatomic) NSTimeInterval 超时时长;
@property (nonatomic, strong) id<可取消协议> 取消Token;
@property (nonatomic, strong) NSMutableArray <id<可取消协议>> *取消Token数组;
@property (nonatomic) bool 已取消;

- (instancetype)initWith地址:(NSString *)地址;
- (void)准备:(NSDictionary *)options;
- (void)执行:(NSDictionary *)options;
- (void)取消;

- (void)添加取消Token:(id<可取消协议>)token;

- (void)新订阅者加入:(ActionHandler *)actionHandler options:(NSDictionary *)options 已在当前队列中:(bool)waitingInActorQueue;

@end
