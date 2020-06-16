//
//  HttpClient.m
//  example
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "HttpClient.h"

@implementation CancelObject

- (void)取消 {
    NSLog(@"I'm cancelled");
}

@end


@interface HttpClient ()

@property (nonatomic, strong) ActionHandler *handler;

@end

@implementation HttpClient

+ (CancelObject *)requestWith:(NSString *)url actor:(Actor *)actor {
    NSLog(@"execute on HttpClient queue");
    DispatchAfter(1, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        if ([actor isKindOfClass:[获取用户名Actor class]]) {
            [(获取用户名Actor *)actor httpRequestSuccess:url response:nil];
        }
    });
    return [CancelObject new];
}

+ (CancelObject *)requestWith:(NSString *)url completion:(void (^)(void))completion {
    DispatchAfter(1, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), completion);
    return [CancelObject new];
}

+ (HttpClient *)instance {
    static HttpClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HttpClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _handler = [[ActionHandler alloc] initWithSubscriber:self];
    }
    return self;
}

@end
