//
//  互斥锁.h
//  ActorModel
//
//  Created by Lawrence on 2020/5/21.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#ifndef 互斥锁_h
#define 互斥锁_h

#import <pthread.h>

#define 互斥锁_定义(lock) pthread_mutex_t 互斥锁##lock
#define 互斥锁_初始化(lock) pthread_mutex_init(&互斥锁##lock, NULL)
#define 互斥锁_加锁(lock) pthread_mutex_lock(&互斥锁##lock);
#define 互斥锁_解锁(lock) pthread_mutex_unlock(&互斥锁##lock);

#endif /* 互斥锁_h */
