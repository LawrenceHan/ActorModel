//
//  ThreadUtils.m
//  ActorModel
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "ThreadUtils.h"

void DispatchOnMainQueue(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void DispatchAfter(double delay, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((delay) * NSEC_PER_SEC)), queue, block);
}
