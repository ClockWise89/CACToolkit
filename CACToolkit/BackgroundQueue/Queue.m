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

- (void)cancelRunningOperation {
    @synchronized (pendingOperations) {
        NSString *key;
        if (_type == QueueLIFO) {
            key = [pendingOperations lastObject];
            
        } else if (_type == QueueFIFO) {
            key = [pendingOperations firstObject];
        }
        
        [self cancelOperationsWithKeys:@[key]];
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

// Use this to wait for entire queue to finish executing. Use case: Longer background operations that does not require updates on UI thread.
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

// Use this to start queue immediately. Use case: TableViews
- (void)executeOperation:(Operation)block key:(NSString*)key cancelExisting:(BOOL)cancel withCallback:(void (^)(void))callback{
    
    [self addOperation:block key:key cancelExisting:cancel];
    @synchronized (pendingOperations) {
        if (pendingOperations.count > 0 && _state != QueueRunning) _state = QueueStart;
    }
    
    if (_state == QueueStart) {
        _state = QueueRunning;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self execute];
            callback();
        });
    
        // OUTCOMMENTED CODE IS TO CANCEL RUNNING OPERATION AND PLACE IT LAST WHEN WE ADD A NEW OPERATION
//    } else if (_state == QueueRunning) {
//        @synchronized (pendingOperations) {
//            NSString *runningKey;
//
//            if (_type == QueueFIFO) {
//                runningKey = [pendingOperations firstObject];
//
//
//
//            } else if(_type == QueueLIFO) {
//                runningKey = [pendingOperations lastObject];
//
//
//                if (queue[runningKey]) {
//                    if (!cancel) return; // Operation already in queue and we do not cancel
//                    id object = queue[runningKey];
//
//                    // Operation already in queue, we need to cancel it
//                    [queue removeObjectForKey:runningKey];
//                    [pendingOperations removeObject:runningKey];
//
//                    [pendingOperations addObject:runningKey];
//                    queue[runningKey] = object;
//                }
//
//            }
//        }
//
//        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
//            [self execute];
//            callback();
//        });
    }
}
@end
