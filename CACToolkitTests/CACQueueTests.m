//
//  CACToolkitTests.m
//  CACToolkitTests
//
//  Created by Christopher Eliasson on 2018-06-14.
//  Copyright © 2018 Code and Crayons. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Queue.h"

@interface CACQueueTests : XCTestCase
@property (nonatomic, strong) Queue *queue;
@property (nonatomic) QueueTypeEnum type;
@end

@implementation CACQueueTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [_queue cancelAllOperations];
}

- (void)testLIFO {
    XCTestExpectation *expectation = [self expectationWithDescription:@"FIFO Queue"];
    __block NSMutableDictionary *result = [NSMutableDictionary new];
    
    _queue = [[Queue alloc] init:QueueLIFO];
    int limit = 15;
    __block int done = 1;
    for (int i=1;i<limit;i++) {
        
        __block NSString *added = [NSString stringWithFormat:@"%i", i];
        [_queue executeOperation:^{
            [NSThread sleepForTimeInterval:0.001f];
            NSLog(@"Operation %i is done.", i);
    
            NSString *finished = [NSString stringWithFormat:@"%i", done];
            done++;
            [result setObject:finished forKey:added];
            
        } key:[NSString stringWithFormat:@"%i", i] cancelExisting:YES withCallback:^{
            [expectation fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        NSLog(@"Finishing result: %@", result);
        
        // Test is successful if all but the first operation is LIFO (the first operation will start before the queue is fully loaded and
        // won't cancel that operation. Thus the first operation finished will be the first one added in this case.
        __block BOOL success = YES;
        [result enumerateKeysAndObjectsUsingBlock:^(NSString *added, NSString *finished, BOOL *stop) {
            
            if ((limit - [added intValue] + 1) != [finished intValue] && [added intValue] != 1) {
                success = NO;
            }
        }];
        
        XCTAssert(success, @"Should be true");
    }];
}

- (void)testFIFO {
    _queue = [[Queue alloc] init:QueueFIFO];
}

- (void)testCancelAllOperations {
    
}

- (void)testCancelAllOperationsWithKeys {
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
    }];
}

@end
