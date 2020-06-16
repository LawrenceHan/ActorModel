//
//  订阅者.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/20.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ActorModel/ActionHandler.h>

@protocol 订阅者 <NSObject>

@required

@property (nonatomic, strong, readonly) ActionHandler *handler;

@optional

- (void)收到操作请求:(NSString *)操作 options:(NSDictionary *)options;
- (void)actor请求完成:(NSString *)地址 状态码:(int)状态码 结果:(id)结果;
- (void)收到该地址进度:(NSString *)地址 进度:(CGFloat)进度;
- (void)收到该地址资源:(NSString *)地址 资源:(id)资源 options:(NSDictionary *)options;
- (void)收到该地址消息:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型;

@end
