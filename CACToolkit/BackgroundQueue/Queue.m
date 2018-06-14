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
    
    /* TODO
     Need a way to add operation and then callback somehow. Right now I can only add code of blocks and execute them...maybe this is fine? Start manually or always start queue instantly???
     */
}

- (instancetype)init {
    self = [super init];
    if (self) {
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

- (void)startExecution {
    // We are not executing yet, start executing queue in background
    if (_state != QueueRunning) {
        _state = QueueRunning;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self execute];
        });
    }
}

@end
