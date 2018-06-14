//
//  Queue.h
//  CACToolkit
//
//  Created by Christopher Eliasson on 2018-06-14.
//  Copyright © 2018 Code and Crayons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^Operation)(void);

typedef enum {
    QueueRunning,
    QueuePaused,
    QueueStopped
} QueueStateEnum;

typedef enum {
    QueueLIFO,
    QueueFIFO
} QueueTypeEnum;

@interface Queue : NSObject
@property (nonatomic, readonly) QueueStateEnum state;
@property (nonatomic, readonly) QueueTypeEnum type;
@end
