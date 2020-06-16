//
//  TestActor.h
//  example
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ActorModel/ActorModel.h>

@interface 获取用户名Actor : Actor

- (void)httpRequestSuccess:(NSString *)__unused url response:(NSData *)response;
- (void)httpRequestFailed:(NSString *)__unused url;

@end
