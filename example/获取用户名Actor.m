//
//  TestActor.m
//  example
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "获取用户名Actor.h"
#import "HttpClient.h"

@implementation 获取用户名Actor {
    NSString *_用户名;
}

+ (void)load {
    [Actor 注册Actor:self];
}

+ (NSString *)泛型地址 {
    return @"首页/用户名";
}

- (void)准备:(NSDictionary *)options {
    NSLog(@"actor 准备执行，可以在这个阶段为正式执行准备一些参数。此时线程已经切换到ActorQueue");
    _用户名 = @"韩光";
}

- (void)执行:(NSDictionary *)options {
    NSLog(@"actor 开始执行");
    
    // now running on http client queue
    NSString *用户名 = options[@"用户名"];
    if (用户名.length) {
        _用户名 = 用户名;
    }
    self.取消Token = [HttpClient requestWith:@"test/getusername" actor:self];
}

- (void)httpRequestSuccess:(NSString *)url response:(NSData *)response {
    NSLog(@"网络请求成功后回到actor queue");
    
    [Actor消息中心() 派发资源到该地址:self.地址 资源:_用户名];
    [Actor消息中心() actor请求完成:self.地址 结果:nil];
}

- (void)httpRequestFailed:(NSString *)url {
    [Actor消息中心() actor请求失败:self.地址 原因:Actor请求结果失败];
}

- (void)dealloc {
    NSLog(@"获取用户名Actor: dealloc");
}

@end
