//
//  UpdateUserName.m
//  example
//
//  Created by Lawrence on 2020/5/25.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "更新用户名Actor.h"
#import "HttpClient.h"

@implementation 更新用户名Actor

+ (void)load {
    [Actor 注册Actor:self];
}

+ (NSString *)泛型地址 {
    return @"用户/更新用户名";
}

- (void)准备:(NSDictionary *)options {
}

- (void)执行:(NSDictionary *)options {
    NSString *url = options[@"url"];
    NSString *username = options[@"用户名"];
    
    if (url.length) {
        self.取消Token = [HttpClient requestWith:url completion:^{
            [Actor消息中心() actor请求完成:self.地址 结果:nil];
            [Actor消息中心() 请求Actor:@"首页/用户名" options:@{@"用户名": username} 订阅者:[HttpClient instance]];
        }];
    } else {
        [Actor消息中心() actor请求失败:self.地址 原因:Actor请求结果失败];
    }
}

- (void)dealloc {
    NSLog(@"更新用户名Actor: dealloc");
}

@end
