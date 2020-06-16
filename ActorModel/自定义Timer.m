//
//  CustomTimer.m
//  ActorModel
//
//  Created by Lawrence on 2020/5/21.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "自定义Timer.h"

@implementation 自定义Timer {
    dispatch_source_t _timer;
    NSTimeInterval _timeout;
    NSTimeInterval _timeoutDate;
    bool _repeat;
    dispatch_block_t _completion;
    dispatch_queue_t _queue;
}

- (instancetype)initWith超时时长:(NSTimeInterval)超时时长 重复执行:(bool)重复执行 completion:(dispatch_block_t)completion queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self != nil) {
        _timeoutDate = INT_MAX;
        _timeout = 超时时长;
        _repeat = 重复执行;
        _completion = [completion copy];
        _queue = queue;
    }
    return self;
}

- (void)dealloc {
    if (_timer != nil) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)开始 {
    _timeoutDate = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970 + _timeout;
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_timeout * NSEC_PER_SEC)), _repeat ? (int64_t)(_timeout * NSEC_PER_SEC) : DISPATCH_TIME_FOREVER, 0);
    
    dispatch_source_set_event_handler(_timer, ^{
        if (self->_completion) {
            self->_completion();
        }
        if (!self->_repeat) {
            [self 取消];
        }
    });
    dispatch_resume(_timer);
}

- (void)开始并取消 {
    if (_completion) {
        _completion();
    }
    [self 取消];
}

- (void)取消 {
    _timeoutDate = 0;
    
    if (_timer != nil) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

@end
