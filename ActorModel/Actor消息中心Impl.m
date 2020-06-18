//
//  GHActor.m
//  ActorModel
//
//  Created by Lawrence on 2020/5/20.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "Actor消息中心Impl.h"
#import "os/lock.h"
#import "自定义Timer.h"

#define kTimer @"timer"
#define kRequestInfo @"requestInfo"
#define kRequestActor @"requestActor"
#define kSubscribers @"subscribers"
#define kPath @"path"

static const char *actorQueueSpecific = "com.actormodel.dispatchqueue";

static dispatch_queue_t mainActorQueue = nil;
static dispatch_queue_t globalActorQueue = nil;
static dispatch_queue_t highPriorityActorQueue = nil;

static os_unfair_lock removeSubscriberRequestsLock = OS_UNFAIR_LOCK_INIT;
static os_unfair_lock removeSubscriberFromPathRequestsLock = OS_UNFAIR_LOCK_INIT;

@interface RequestData : NSObject

@property (nonatomic, strong) ActionHandler *handler;
@property (nonatomic, strong) NSString *path;

@end

@implementation RequestData

@end

@interface Actor消息中心Impl ()

@property (nonatomic, strong) NSMutableArray <RequestData *> *removeSubscriberFromPathRequests;
@property (nonatomic, strong) NSMutableArray <ActionHandler *> *removeSubscriberRequests;
@property (nonatomic, strong) NSMutableDictionary *requestQueues;
@property (nonatomic, strong) NSMutableDictionary *activeRequests;
@property (nonatomic, strong) NSMutableDictionary *cancelRequestTimers;
@property (nonatomic, strong) NSMutableDictionary *liveSubscribers;

@end

Actor消息中心Impl *Actor消息中心(void) {
    static Actor消息中心Impl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Actor消息中心Impl alloc] init];
    });
    return instance;
}

@implementation Actor消息中心Impl

- (instancetype)init{
    self = [super init];
    if (self != nil) {
        _requestQueues = [[NSMutableDictionary alloc] init];
        _activeRequests = [[NSMutableDictionary alloc] init];
        _cancelRequestTimers = [[NSMutableDictionary alloc] init];
        _liveSubscribers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (dispatch_queue_t)串行ActorDispatchQueue {
    if (mainActorQueue == NULL) {
        mainActorQueue = dispatch_queue_create("com.actormodel.dispatchqueue", 0);
        globalActorQueue = dispatch_queue_create("com.actormodel.dispatchqueue-global", 0);
        dispatch_set_target_queue(globalActorQueue, mainActorQueue);
        highPriorityActorQueue = dispatch_queue_create("com.actormodel.dispatchqueue-high", 0);
        dispatch_set_target_queue(highPriorityActorQueue, mainActorQueue);
        dispatch_queue_set_specific(mainActorQueue, actorQueueSpecific, (void *)actorQueueSpecific, NULL);
        dispatch_queue_set_specific(globalActorQueue, actorQueueSpecific, (void *)actorQueueSpecific, NULL);
        dispatch_queue_set_specific(highPriorityActorQueue, actorQueueSpecific, (void *)actorQueueSpecific, NULL);
    }
    return globalActorQueue;
}

- (bool)当前是ActorDispatchQueue {
    return dispatch_get_specific(actorQueueSpecific) != NULL;
}

#ifdef DEBUG
- (void)dispatchOnActorQueueDebug:(const char *)function line:(int)line block:(dispatch_block_t)block
#else
- (void)dispatchOnActorQueue:(dispatch_block_t)block
#endif
{
    bool isActorQueue = [self 当前是ActorDispatchQueue];
    
    if (isActorQueue) {
#ifdef DEBUG
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
#endif
        block();
#ifdef DEBUG
        CFAbsoluteTime executionTime = (CFAbsoluteTimeGetCurrent() - startTime);
        if (executionTime > 0.1) {
            NSLog(@"[ActorModel] $$$ Dispatch from %s:%d took %f s", function, line, executionTime);
        }
#endif
    } else {
#ifdef DEBUG
        dispatch_async([self 串行ActorDispatchQueue], ^{
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            
            block();
            
            CFAbsoluteTime executionTime = (CFAbsoluteTimeGetCurrent() - startTime);
            if (executionTime > 0.1) {
                NSLog(@"[ActorModel] $$$ Dispatch from %s:%d took %f s", function, line, executionTime);
            }
        });
#else
        dispatch_async([self 串行ActorDispatchQueue], block);
#endif
    }
}

- (void)dispatchOnHighPriorityQueue:(dispatch_block_t)block {
    if ([self 当前是ActorDispatchQueue]) {
        block();
    } else {
        if (highPriorityActorQueue == NULL) {
            [self 串行ActorDispatchQueue];
        }
        dispatch_async(highPriorityActorQueue, block);
    }
}

- (void)当前Actor消息中心状态 {
    [self dispatchOnActorQueue:^{
        NSLog(@"===== Actor消息中心状态 =====");
        NSLog(@"当前有%ld个订阅者", self.liveSubscribers.count);
        [self.liveSubscribers enumerateKeysAndObjectsUsingBlock:^(NSString *地址, NSArray *subscribers, __unused BOOL *stop) {
            NSLog(@"    %@", 地址);
            for (ActionHandler *handler in subscribers) {
                id<订阅者> 订阅者 = handler.订阅者;
                if (订阅者 != nil) {
                    NSLog(@"        %@", [订阅者 description]);
                }
            }
        }];
        NSLog(@"%ld个正在运行的Actors", self.activeRequests.count);
        [self.activeRequests enumerateKeysAndObjectsUsingBlock:^(NSString *地址, __unused id obj, __unused BOOL *stop) {
            NSLog(@"        %@", 地址);
        }];
        NSLog(@"========================");
    }];
}

- (NSString *)给地址生成泛型地址:(NSString *)地址 {
    if (地址.length == 0) {
        return @"";
    }
    
    int length = (int)地址.length;
    unichar 新地址[地址.length];
    
    bool skip = false;
    bool skippedCharacters = false;
    int index = 0;
    
    for (int i = 0; i < length; i++) {
        unichar c = [地址 characterAtIndex:i];
        if (c == 地址参数开始符号) {
            skip = true;
            skippedCharacters = true;
            新地址[index++] = 地址参数符号;
        } else if (c == 地址参数结束符号) {
            skip = false;
        } else if (!skip) {
            新地址[index++] = c;
        }
    }

    if (!skippedCharacters) {
        return 地址;
    }
    
    NSString *泛型地址 = [[NSString alloc] initWithCharacters:新地址 length:index];
    return 泛型地址;
}

- (void)_requestGeneric:(bool)joinOnly inCurrentQueue:(bool)inCurrentQueue path:(NSString *)path options:(NSDictionary *)options flags:(int)flags subscriber:(id<订阅者>)subscriber {
    ActionHandler *actionHandler = subscriber.handler;
    dispatch_block_t requestBlock = ^{
        if (![actionHandler 是否有订阅者]) {
            NSLog(@"[ActorModel] Error: %s:%d: actionHandler.subscriber is nil", __PRETTY_FUNCTION__, __LINE__);
            return;
        }
        
        NSMutableDictionary *activeRequests = self.activeRequests;
        NSMutableDictionary *cancelTimers = self.cancelRequestTimers;

        NSString *genericPath = [self 给地址生成泛型地址:path];

        NSMutableDictionary *requestInfo = nil;

        NSMutableDictionary *cancelRequestInfo = cancelTimers[path];
        if (cancelRequestInfo != nil) {
            自定义Timer *timer = cancelRequestInfo[kTimer];
            [timer 取消];
            timer = nil;
            requestInfo = cancelRequestInfo[kRequestInfo];
            activeRequests[path] = requestInfo;
            [cancelTimers removeObjectForKey:path];
            NSLog(@"[ActorModel] Resuming request to \"%@\"", path);
        }

        if (requestInfo == nil) {
            requestInfo = activeRequests[path];
        }
        
        if (joinOnly && requestInfo == nil) {
            return;
        }
        
        if (requestInfo == nil) {
            Actor *requestActor = [Actor 泛型地址对应的Actor类:genericPath 地址:path];
            if (requestActor != nil) {
                NSMutableArray *subscribers = [[NSMutableArray alloc] initWithObjects:actionHandler, nil];
                
                requestInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               requestActor, kRequestActor,
                               subscribers, kSubscribers,
                               nil];
                
                activeRequests[path] = requestInfo;
                
                [requestActor 准备:options];
                
                bool executeNow = true;
                if (requestActor.请求队列名称 != nil) {
                    NSMutableArray *requestQueue = self.requestQueues[requestActor.请求队列名称];
                    if (requestQueue == nil) {
                        requestQueue = [[NSMutableArray alloc] initWithArray:@[requestActor]];
                        self.requestQueues[requestActor.请求队列名称] = requestQueue;
                    } else {
                        [requestQueue addObject:requestActor];
                        if ([requestQueue count] > 1) {
                            executeNow = false;
                            NSLog(@"[ActorModel] Adding request %@ to request queue \"%@\"", requestActor, requestActor.请求队列名称);
                        }
                    }
                }
                
                if (executeNow) {
                    [requestActor 执行:options];
                } else {
                    requestActor.已储存的Options = options;
                }
            } else {
                NSLog(@"[ActorModel] Error: request actor not found for \"%@\"", path);
            }
        } else {
            NSMutableArray *subscribers = requestInfo[kSubscribers];
            if (![subscribers containsObject:actionHandler]) {
                NSLog(@"[ActorModel] Joining subscriber to the subscribers of \"%@\"", path);
                [subscribers addObject:actionHandler];
            } else {
                NSLog(@"[ActorModel] Continue to watch for actor \"%@\"", path);
            }
            
            Actor *actor = requestInfo[kRequestActor];
            if (actor.请求队列名称 == nil) {
                [actor 新订阅者加入:actionHandler options:options 已在当前队列中:false];
            } else {
                NSMutableArray *requestQueue = self.requestQueues[actor.请求队列名称];
                if (requestQueue == nil || requestQueue.count == 0) {
                    [actor 新订阅者加入:actionHandler options:options 已在当前队列中:false];
                } else {
                    [actor 新订阅者加入:actionHandler options:options 已在当前队列中:[requestQueue objectAtIndex:0] != actor];
                }
            }
        }
    };
    
    if (inCurrentQueue) {
        requestBlock();
    } else {
        [self dispatchOnActorQueue:requestBlock];
    }
}

- (NSArray *)马上使该泛型地址相关Actors重订阅:(NSString *)泛型地址 地址前缀:(NSString *)地址前缀 订阅者:(id<订阅者>)订阅者 {
    NSMutableDictionary *activeRequests = _activeRequests;
    NSMutableDictionary *cancelTimers = _cancelRequestTimers;
    
    NSMutableArray *rejoinPaths = [NSMutableArray new];
    
    for (NSString *地址 in activeRequests.allKeys) {
        if ([地址 isEqualToString:泛型地址] || ([[self 给地址生成泛型地址:地址] isEqualToString:泛型地址] && (地址前缀.length == 0 || [地址 hasPrefix:地址前缀]))) {
            [rejoinPaths addObject:地址];
        }
    }
    
    for (NSString *地址 in cancelTimers.allKeys) {
        if ([[self 给地址生成泛型地址:地址] isEqualToString:泛型地址] && [地址 hasPrefix:地址前缀]) {
            [rejoinPaths addObject:地址];
        }
    }
    
    for (NSString *地址 in rejoinPaths) {
        [self _requestGeneric:true inCurrentQueue:true path:地址 options:nil flags:0 subscriber:订阅者];
    }
    
    return rejoinPaths;
}

- (bool)是否有该泛型地址的Actor在运行:(NSString *)泛型地址 {
    if (![self 当前是ActorDispatchQueue]) {
        NSLog(@"[ActorModel] %s should be called from actor queue", __PRETTY_FUNCTION__);
        return nil;
    }
    
    __block bool result = false;
    
    [_activeRequests enumerateKeysAndObjectsUsingBlock:^(__unused NSString *地址, NSDictionary *actorInfo, BOOL *stop) {
        Actor *actor = actorInfo[kRequestActor];
        
        if ([泛型地址 isEqualToString:[actor.class 泛型地址]]) {
            result = true;
            if (stop != NULL) {
                *stop = true;
            }
        }
    }];
    
    if (!result) {
        [_cancelRequestTimers enumerateKeysAndObjectsUsingBlock:^(__unused NSString *地址, NSDictionary *actorInfo, BOOL *stop) {
            Actor *actor = actorInfo[kRequestActor];
            
            if ([泛型地址 isEqualToString:[actor.class 泛型地址]]) {
                result = true;
                if (stop != NULL) {
                    *stop = true;
                }
            }
        }];
    }
    
    return result;
}

- (bool)是否有该前缀地址的Actor在运行:(NSString *)地址前缀 {
    if (![self 当前是ActorDispatchQueue]) {
        NSLog(@"[ActorModel] %s should be called from actor queue", __PRETTY_FUNCTION__);
        return nil;
    }

    __block bool result = false;

    [_activeRequests enumerateKeysAndObjectsUsingBlock:^(NSString *地址, __unused id obj, BOOL *stop) {
        if ([地址 hasPrefix:地址前缀]) {
            result = true;
            if (stop != NULL) {
                *stop = true;
            }
        }
    }];

    if (!result) {
        [_cancelRequestTimers enumerateKeysAndObjectsUsingBlock:^(NSString *地址, __unused id obj, BOOL *stop) {
            if ([地址 hasPrefix:地址前缀]) {
                result = true;
                if (stop != NULL) {
                    *stop = true;
                }
            }
        }];
    }

    return result;
}

- (NSArray *)该地址前缀正在运行的Actors:(NSString *)地址前缀 {
    if (![self 当前是ActorDispatchQueue]) {
        NSLog(@"[ActorModel] %s should be called from actor queue", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray new];
    
    [_activeRequests enumerateKeysAndObjectsUsingBlock:^(NSString *地址, NSDictionary *actorInfo, __unused BOOL *stop) {
        if ([地址 hasPrefix:地址前缀]) {
            Actor *actor = actorInfo[kRequestActor];
            if (actor != nil) {
                [array addObject:actor];
            }
        }
    }];
    
    [_cancelRequestTimers enumerateKeysAndObjectsUsingBlock:^(NSString *地址, NSDictionary *actorInfo, __unused BOOL *stop) {
        if ([地址 hasPrefix:地址前缀]) {
            Actor *actor = actorInfo[kRequestActor];
            if (actor != nil) {
                [array addObject:actor];
            }
        }
    }];
    
    return array;
}

- (Actor *)该地址正在运行的Actor:(NSString *)地址 {
    if (![self 当前是ActorDispatchQueue]) {
        NSLog(@"[ActorModel] %s should be called from actor queue", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSMutableDictionary *requestInfo = _activeRequests[地址];
    if (requestInfo != nil) {
        Actor *requestActor = requestInfo[kRequestActor];
        return requestActor;
    }
    
    NSMutableDictionary *cancelRequestInfo = _cancelRequestTimers[地址];
    if (cancelRequestInfo != nil) {
        Actor *requestActor = cancelRequestInfo[kRequestInfo][kRequestActor];
        return requestActor;
    }
    
    return nil;
}

- (void)让该地址相关的超时Actor马上取消:(NSString *)地址 {
    NSMutableDictionary *cancelRequestInfo = _cancelRequestTimers[地址];
    if (cancelRequestInfo != nil) {
        自定义Timer *timer = cancelRequestInfo[kTimer];
        [timer 开始并取消];
        timer = nil;
    }
}

- (void)请求Actor:(NSString *)地址 options:(NSDictionary *)options 订阅者:(id<订阅者>)订阅者 {
    [self _requestGeneric:false inCurrentQueue:false path:地址 options:options flags:0 subscriber:订阅者];
}

- (void)请求Actor:(NSString *)地址 options:(NSDictionary *)options 订阅者:(id<订阅者>)订阅者 flags:(int)flags {
    [self _requestGeneric:false inCurrentQueue:false path:地址 options:options flags:flags subscriber:订阅者];
}

- (void)订阅该地址:(NSString *)地址 订阅者:(id<订阅者>)订阅者 {
    ActionHandler *actionHandler = 订阅者.handler;
    if (actionHandler == nil) {
        NSLog(@"[ActorModel] Warning: actionHandler is nil in %s:%d", __PRETTY_FUNCTION__, __LINE__);
        return;
    }
    
    [self dispatchOnActorQueue:^{
        NSMutableArray *subscribers = self.liveSubscribers[地址];
        if (subscribers == nil) {
            subscribers = [NSMutableArray new];
            self.liveSubscribers[地址] = subscribers;
        }
        
        if (![subscribers containsObject:actionHandler]) {
            [subscribers addObject:actionHandler];
        }
    }];
}

- (void)订阅该组地址:(NSArray *)地址数组 订阅者:(id<订阅者>)订阅者 {
    ActionHandler *actionHandler = 订阅者.handler;
    if (actionHandler == nil) {
        NSLog(@"[ActorModel] Warning: actionHandler is nil in %s:%d", __PRETTY_FUNCTION__, __LINE__);
        return;
    }
    
    [self dispatchOnActorQueue:^{
        for (NSString *地址 in 地址数组) {
            NSMutableArray *subscribers = self.liveSubscribers[地址];
            if (subscribers == nil) {
                subscribers = [NSMutableArray new];
                self.liveSubscribers[地址] = subscribers;
            }
            
            if (![subscribers containsObject:actionHandler]) {
                [subscribers addObject:actionHandler];
            }
        }
    }];
}

- (void)订阅该地址的泛型地址:(NSString *)地址 订阅者:(id<订阅者>)订阅者 {
    ActionHandler *actionHandler = 订阅者.handler;
    if (actionHandler == nil) {
        NSLog(@"[ActorModel] Warning: actionHandler is nil in %s:%d", __PRETTY_FUNCTION__, __LINE__);
        return;
    }
    
    [self dispatchOnActorQueue:^{
        NSString *泛型地址 = [self 给地址生成泛型地址:地址];
        NSMutableArray *subscribers = self.liveSubscribers[泛型地址];
        if (subscribers == nil) {
            subscribers = [NSMutableArray new];
            self.liveSubscribers[泛型地址] = subscribers;
        }
        
        if (![subscribers containsObject:actionHandler]) {
            [subscribers addObject:actionHandler];
        }
    }];
}

- (void)removeRequestActorFromQueue:(NSString *)path fromRequestActor:(Actor *)requestActor {
    NSMutableArray *requestQueue = _requestQueues[requestActor.请求队列名称 == nil ? path : requestActor.请求队列名称];
    if (requestQueue == nil) {
        NSLog(@"[ActorModel] Warning: requestQueue is nil");
    } else {
        if (requestQueue.count == 0) {
            NSLog(@"[ActorModel] Warning: request queue \"%@\" is empty.", requestActor.请求队列名称);
        } else {
            if ([requestQueue objectAtIndex:0] == requestActor) {
                [requestQueue removeObjectAtIndex:0];
                
                if (requestQueue.count != 0) {
                    Actor *nextRequest = nil;
                    id nextRequestOptions = nil;
                    
                    nextRequest = [requestQueue objectAtIndex:0];
                    nextRequestOptions = nextRequest.已储存的Options;
                    nextRequest.已储存的Options = nil;
                    
                    if (nextRequest != nil && !nextRequest.已取消)
                        [nextRequest 执行:nextRequestOptions];
                } else {
                    [_requestQueues removeObjectForKey:requestActor.请求队列名称];
                }
            } else {
                if ([requestQueue containsObject:requestActor]) {
                    [requestQueue removeObject:requestActor];
                } else {
                    NSLog(@"[ActorModel] Warning: request queue \"%@\" doesn't contain request to %@", requestActor.请求队列名称, requestActor.地址);
                }
            }
        }
    }
}

- (void)移除订阅者:(id<订阅者>)订阅者 {
    [self 根据Handler移除订阅者:订阅者.handler];
}

- (void)根据Handler移除订阅者:(ActionHandler *)handler {
    ActionHandler *actionHandler = handler;
    if (actionHandler == nil) {
        NSLog(@"[ActorModel] Warning: actor handle is nil in removeSubscriber");
        return;
    }
    
    bool alreadyExecuting = false;
    os_unfair_lock_lock(&removeSubscriberRequestsLock);
    if (_removeSubscriberRequests.count > 0) {
        alreadyExecuting = true;
    }
    [_removeSubscriberRequests addObject:actionHandler];
    os_unfair_lock_unlock(&removeSubscriberRequestsLock);
    
    if (alreadyExecuting && ![self 当前是ActorDispatchQueue]) {
        return;
    }
    
    [self dispatchOnHighPriorityQueue:^{
        NSMutableArray *removeSubscribers = [NSMutableArray new];
        
        os_unfair_lock_lock(&removeSubscriberRequestsLock);
        [removeSubscribers addObjectsFromArray:self.removeSubscriberRequests];
        [self.removeSubscriberRequests removeAllObjects];
        os_unfair_lock_unlock(&removeSubscriberRequestsLock);
        
        for (ActionHandler *actionHandler in removeSubscribers) {
            for (id key in [self.activeRequests allKeys]) {
                NSMutableDictionary *requestInfo = self.activeRequests[key];
                NSMutableArray *subscribers = requestInfo[kSubscribers];
                [subscribers removeObject:actionHandler];
                
                if (subscribers.count == 0) {
                    [self scheduleCancelRequest:(NSString *)key];
                }
            }
            
            NSMutableArray *keysToRemove = nil;
            for (NSString *key in [self.liveSubscribers allKeys]) {
                NSMutableArray *subscribers = self.liveSubscribers[key];
                [subscribers removeObject:actionHandler];
                
                if (subscribers.count == 0) {
                    if (keysToRemove == nil) {
                        keysToRemove = [NSMutableArray new];
                    }
                    [keysToRemove addObject:key];
                }
            }
            
            if (keysToRemove != nil) {
                [self.liveSubscribers removeObjectsForKeys:keysToRemove];
            }
        }
    }];
}

- (void)从该地址移除所有订阅者:(NSString *)地址 {
    [self dispatchOnHighPriorityQueue:^{
        NSMutableDictionary *requestInfo = self.activeRequests[地址];
        if (requestInfo != nil) {
            NSMutableArray *subscribers = requestInfo[kSubscribers];
            [subscribers removeAllObjects];
            [self scheduleCancelRequest:地址];
        }
    }];
}

- (void)移除订阅者:(id<订阅者>)订阅者 从该地址:(NSString *)地址 {
    ActionHandler *actionHandler = 订阅者.handler;
    [self 根据Handler移除订阅者:actionHandler 从该地址:地址];
}

- (void)根据Handler移除订阅者:(ActionHandler *)actionHandler 从该地址:(NSString *)地址 {
    if (actionHandler == nil) {
        NSLog(@"[ActorModel] Warning: actor handle is nil in removeSubscriber:fromPath");
        return;
    }
    
    bool alreadyExecuting = false;
    os_unfair_lock_lock(&removeSubscriberFromPathRequestsLock);
    if (_removeSubscriberFromPathRequests.count > 0) {
        alreadyExecuting = true;
    }
    RequestData *data = [RequestData new];
    data.handler = actionHandler;
    data.path = 地址;
    [_removeSubscriberFromPathRequests addObject:data];
    os_unfair_lock_unlock(&removeSubscriberFromPathRequestsLock);
    
    if (alreadyExecuting && ![self 当前是ActorDispatchQueue]) {
        return;
    }
    
    [self dispatchOnHighPriorityQueue:^{
        NSMutableArray *removeSubscribersFromPath = [NSMutableArray new];
        
        os_unfair_lock_lock(&removeSubscriberFromPathRequestsLock);
        [removeSubscribersFromPath addObjectsFromArray:self.removeSubscriberFromPathRequests];
        [self.removeSubscriberFromPathRequests removeAllObjects];
        os_unfair_lock_unlock(&removeSubscriberFromPathRequestsLock);
        
        if (removeSubscribersFromPath.count > 1) {
            NSLog(@"[ActorModel] Cancelled %ld requests at once", removeSubscribersFromPath.count);
        }
        
        for (RequestData *data in removeSubscribersFromPath) {
            ActionHandler *actionHandler = data.handler;
            NSString *path = data.path;
            if (path == nil) {
                continue;
            }
            
            // active requests
            {
                NSMutableDictionary *requestInfo = self.activeRequests[path];
                if (requestInfo != nil) {
                    NSMutableArray *subscribers = requestInfo[kSubscribers];
                    if ([subscribers containsObject:actionHandler]) {
                        [subscribers removeObject:actionHandler];
                    }
                    if (subscribers.count == 0) {
                        [self scheduleCancelRequest:(NSString *)path];
                    }
                }
            }
            
            // live subscribers
            {
                NSMutableArray *subscribers = self.liveSubscribers[path];
                if ([subscribers containsObject:actionHandler]) {
                    [subscribers removeObject:actionHandler];
                }
                if (subscribers.count == 0) {
                    [self.liveSubscribers removeObjectForKey:path];
                }
            }
        }
    }];
}

- (bool)是否有该地址的Actor在运行:(NSString *)地址 {
    if (_activeRequests[地址] != nil) {
        return true;
    }
    return false;
}

- (void)派发资源到该地址:(NSString *)地址 资源:(id)资源 {
    [self 派发资源到该地址:地址 资源:资源 options:nil];
}

- (void)派发资源到该地址:(NSString *)地址 资源:(id)资源 options:(NSDictionary *)options {
    [self dispatchOnActorQueue:^{
        NSString *泛型地址 = [self 给地址生成泛型地址:地址];
        NSArray *subscribers = [self.liveSubscribers[地址] copy];
        if (subscribers != nil) {
            for (ActionHandler *handler in subscribers) {
                id<订阅者> 订阅者 = handler.订阅者;
                if (订阅者 != nil) {
                    if ([订阅者 respondsToSelector:@selector(收到该地址资源:资源:options:)]) {
                        [订阅者 收到该地址资源:地址 资源:资源 options:options];
                    }
                    
                    if (handler.是否在主线程释放) {
                        dispatch_async(dispatch_get_main_queue(), ^{ [订阅者 class]; });
                    }
                    订阅者 = nil;
                }
            }
        }
        
        if (![泛型地址 isEqualToString:地址]) {
            NSArray *subscribers = self.liveSubscribers[泛型地址];
            if (subscribers != nil) {
                for (ActionHandler *handler in subscribers) {
                    id<订阅者> 订阅者 = handler.订阅者;
                    if (订阅者 != nil) {
                        if ([订阅者 respondsToSelector:@selector(收到该地址资源:资源:options:)]) {
                            [订阅者 收到该地址资源:地址 资源:资源 options:options];
                        }
                        
                        if (handler.是否在主线程释放) {
                            dispatch_async(dispatch_get_main_queue(), ^{ [订阅者 class]; });
                        }
                        订阅者 = nil;
                    }
                }
            }
        }
    }];
}

- (void)actor请求完成:(NSString *)地址 结果:(id)结果 {
    [self dispatchOnActorQueue:^{
        NSMutableDictionary *requestInfo = self.activeRequests[地址];
        if (requestInfo != nil) {
            Actor *requestActor = requestInfo[kRequestActor];
            
            NSMutableArray *subscribers = requestInfo[kSubscribers];
            [self.activeRequests removeObjectForKey:地址];
            for (ActionHandler *handler in subscribers) {
                id<订阅者> 订阅者 = handler.订阅者;
                if (订阅者 != nil) {
                    if ([订阅者 respondsToSelector:@selector(actor请求完成:状态码:结果:)]) {
                        [订阅者 actor请求完成:地址 状态码:Actor请求结果成功 结果:结果];
                    }
                    
                    if (handler.是否在主线程释放) {
                        dispatch_async(dispatch_get_main_queue(), ^{ [订阅者 class]; });
                    }
                    订阅者 = nil;
                }
            }
            [subscribers removeAllObjects];
            
            if (requestActor == nil) {
                NSLog(@"[ActorModel] Warning ***** requestActor is nil");
            } else if (requestActor.请求队列名称 != nil) {
                [self removeRequestActorFromQueue:requestActor.请求队列名称 fromRequestActor:requestActor];
            }
        }
    }];
}

- (void)派发消息给正在执行中的Actors:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型 {
    [self dispatchOnActorQueue:^{
        NSMutableDictionary *requestInfo = self.activeRequests[地址];
        if (requestInfo != nil) {
            NSArray *subscribersCopy = [requestInfo[kSubscribers] copy];
            for (ActionHandler *handler in subscribersCopy) {
                [handler 通知该地址收到消息:地址 消息:消息 消息类型:消息类型];
            }
        }
    }];
}

- (void)派发消息给订阅该地址的订阅者:(NSString *)地址 消息:(id)消息 消息类型:(NSString *)消息类型 {
    [self dispatchOnActorQueue:^{
        NSString *genericPath = [self 给地址生成泛型地址:地址];
        NSArray *handlers = self.liveSubscribers[genericPath];
        for (ActionHandler *handler in handlers) {
            if ([handler respondsToSelector:@selector(通知该地址收到消息:消息:消息类型:)]) {
                [handler 通知该地址收到消息:地址 消息:消息 消息类型:消息类型];
            }
        }
    }];
}

- (void)actor请求失败:(NSString *)地址 原因:(int)原因 {
    [self dispatchOnActorQueue:^{
        NSMutableDictionary *requestInfo = self.activeRequests[地址];
        if (requestInfo != nil) {
            Actor *requestActor = requestInfo[kRequestActor];
            
            NSMutableArray *pathSubscribers = requestInfo[kSubscribers];
            [self.activeRequests removeObjectForKey:地址];
            for (ActionHandler *handler in pathSubscribers) {
                id<订阅者> subscriber = handler.订阅者;
                if (subscriber != nil) {
                    if ([subscriber respondsToSelector:@selector(actor请求完成:状态码:结果:)]) {
                        [subscriber actor请求完成:地址 状态码:原因 结果:nil];
                    }
                    
                    if (handler.是否在主线程释放) {
                        dispatch_async(dispatch_get_main_queue(), ^{ [subscriber class]; });
                    }
                    subscriber = nil;
                }
            }
            [pathSubscribers removeAllObjects];
            
            if (requestActor == nil) {
                NSLog(@"[ActorModel] Warning: requestActor is nil");
            } else if (requestActor.请求队列名称 != nil) {
                [self removeRequestActorFromQueue:requestActor.请求队列名称 fromRequestActor:requestActor];
            }
        }
    }];
}

- (void)派发进度到该地址:(NSString *)地址 进度:(CGFloat)进度 {
    [self dispatchOnActorQueue:^{
        NSMutableDictionary *requestInfo = self.activeRequests[地址];
        if (requestInfo == nil) {
            requestInfo = self.activeRequests[地址];
        }
        
        if (requestInfo != nil) {
            NSMutableArray *subscribers = requestInfo[kSubscribers];
            for (ActionHandler *handler in subscribers) {
                id<订阅者> 订阅者 = handler.订阅者;
                if (订阅者 != nil) {
                    if ([订阅者 respondsToSelector:@selector(收到该地址进度:进度:)]) {
                        [订阅者 收到该地址进度:地址 进度:进度];
                    }
                    
                    if (handler.是否在主线程释放) {
                        dispatch_async(dispatch_get_main_queue(), ^{ [订阅者 class]; });
                    }
                    订阅者 = nil;
                }
            }
        }
    }];
}

- (void)scheduleCancelRequest:(NSString *)path {
    NSMutableDictionary *activeRequests = _activeRequests;
    NSMutableDictionary *cancelTimers = _cancelRequestTimers;
    
    NSMutableDictionary *requestInfo = activeRequests[path];
    NSMutableDictionary *cancelRequestInfo = cancelTimers[path];
    if (requestInfo != nil && cancelRequestInfo == nil) {
        Actor *requestActor = requestInfo[kRequestActor];
        NSTimeInterval cancelTimeout = requestActor.超时时长;
        
        if (cancelTimeout <= DBL_EPSILON) {
            [activeRequests removeObjectForKey:path];
            
            [requestActor 取消];
            NSLog(@"[ActorModel] Cancelled request to \"%@\"", path);
            if (requestActor.请求队列名称 != nil) {
                [self removeRequestActorFromQueue:requestActor.请求队列名称 fromRequestActor:requestActor];
            }
        } else {
            NSLog(@"[ActorModel] Will cancel request to \"%@\" in %f s", path, cancelTimeout);
            NSDictionary *cancelDict = [NSDictionary dictionaryWithObjectsAndKeys:path, kPath, [NSNumber numberWithInt:0], @"type", nil];
            自定义Timer *timer = [[自定义Timer alloc] initWith超时时长:cancelTimeout 重复执行:false completion:^{
                [self performCancelRequest:cancelDict];
            } queue:[self 串行ActorDispatchQueue]];
            
            cancelRequestInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:requestInfo, kRequestInfo, nil];
            cancelRequestInfo[kTimer] = timer;
            cancelTimers[path] = cancelRequestInfo;
            [activeRequests removeObjectForKey:path];
            
            [timer 开始];
        }
    } else if (cancelRequestInfo == nil) {
        NSLog(@"[ActorModel] Warning: cannot cancel request to \"%@\": no active request found", path);
    }
}
         
- (void)performCancelRequest:(NSDictionary *)cancelDict {
    NSString *path = cancelDict[kPath];
    
    [self dispatchOnActorQueue:^{
        NSMutableDictionary *cancelTimers = self.cancelRequestTimers;

        NSMutableDictionary *cancelRequestInfo = cancelTimers[path];
        if (cancelRequestInfo == nil) {
            NSLog(@"[ActorModel] Warning: cancelRequestTimerEvent: \"%@\": no cancel info found", path);
            return;
        }
        NSDictionary *requestInfo = cancelRequestInfo[kRequestInfo];
        Actor *requestActor = requestInfo[kRequestActor];
        if (requestActor == nil) {
            NSLog(@"[ActorModel] Warning: active request actor for \"%@\" not fond, cannot cancel request", path);
        } else {
            [requestActor 取消];
            NSLog(@"[ActorModel] Cancelled request to \"%@\"", path);
            if (requestActor.请求队列名称 != nil) {
                [self removeRequestActorFromQueue:requestActor.请求队列名称 fromRequestActor:requestActor];
            }
        }
        [cancelTimers removeObjectForKey:path];
    }];
}

@end
