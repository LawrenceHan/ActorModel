//
//  HttpClient.h
//  example
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "获取用户名Actor.h"

@interface CancelObject : NSObject <可取消协议>

@end

@interface HttpClient : NSObject <订阅者>

+ (HttpClient *)instance;

+ (CancelObject *)requestWith:(NSString *)url actor:(Actor *)actor;
+ (CancelObject *)requestWith:(NSString *)url completion:(void (^)(void))completion;

@end
