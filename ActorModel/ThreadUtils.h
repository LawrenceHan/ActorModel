//
//  ThreadUtils.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void DispatchOnMainQueue(dispatch_block_t block);
void DispatchAfter(double delay, dispatch_queue_t queue, dispatch_block_t block);

#ifdef __cplusplus
}
#endif
