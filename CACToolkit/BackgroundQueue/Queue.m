//
//  Queue.m
//  CACToolkit
//
//  Created by Christopher Eliasson on 2018-06-14.
//  Copyright © 2018 Code and Crayons. All rights reserved.
//

#import "Queue.h"

@implementation Queue {
    NSMutableArray *pendingOperations;
    NSMutableDictionary *queue;
}

- (instancetype)init:(QueueTypeEnum)type {
    self = [super init];
    if (self) {
        _type = type;
        _state = QueueStopped;
        pendingOperations = [NSMutableArray new];
        queue = [NSMutableDictionary new];
    }
    return self;
}

- (void)addOperation:(Operation)block key:(NSString*)key cancelExisting:(BOOL)cancel {
    @synchronized (pendingOperations) {
        if (queue[key]) {
            if (!cancel) return; // Operation already in queue and we do not cancel
            
            // Operation already in queue, we need to cancel it
            [queue removeObjectForKey:key];
            [pendingOperations removeObject:key];
        }
        
        // Add operation to queue
        [pendingOperations addObject:key];
        queue[key] = block;
    }
}

- (void)cancelAllOperations {
    @synchronized (pendingOperations) {
        [pendingOperations removeAllObjects];
        [queue removeAllObjects];
    }
}

- (void)cancelOperationsWithKeys:(NSArray *)keys {
    @synchronized (pendingOperations) {
        for (NSString *key in keys) {
            if (queue[key]) {
                [queue removeObjectForKey:key];
                [pendingOperations removeObject:key];
            }
        }
    }
}

- (void)execute {
    Operation block;
    NSString *key;
    @synchronized (pendingOperations) {
        if (_type == QueueLIFO) {
            key = [pendingOperations lastObject];
        
        } else if (_type == QueueFIFO) {
            key = [pendingOperations firstObject];
        }
        block = [queue objectForKey:key];
    }
    
    block();
    BOOL finishedQueueExecution = YES;
    @synchronized (pendingOperations) {
        [pendingOperations removeObject:key];
        [queue removeObjectForKey:key];
        
        if (pendingOperations.count > 0)
            finishedQueueExecution = NO;
    }
    
    if (!finishedQueueExecution) {
        [self execute];
    
    } else {
        _state = QueueStopped;
    }
}

// Use this to wait for entire queue to finish executing. Needs to build the queue beforehand.
- (void)executeFullQueueWithCallback:(void(^)(void))callback {
    // We are not executing yet, start executing queue in background
    if (_state != QueueRunning) {
        _state = QueueRunning;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self execute];
            callback();
        });
    }
}

// Use this to start queue immediately and perform callback for each item. No need to build up queue first.
- (void)executeOperation:(Operation)block key:(NSString*)key cancelExisting:(BOOL)cancel {
    
    [self addOperation:block key:key cancelExisting:cancel];
    @synchronized (pendingOperations) {
        if (pendingOperations.count > 0 && _state != QueueRunning) _state = QueueStart;
    }
    
    if (_state == QueueStart) {
        _state = QueueRunning;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self execute];
        });
    }
}
@end
