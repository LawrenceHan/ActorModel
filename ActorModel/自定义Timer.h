//
//  CustomTimer.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/21.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface 自定义Timer : NSObject

- (instancetype)initWith超时时长:(NSTimeInterval)timeout 重复执行:(bool)重复执行 completion:(dispatch_block_t)completion queue:(dispatch_queue_t)queue;

- (void)开始;
- (void)取消;
- (void)开始并取消;

@end
