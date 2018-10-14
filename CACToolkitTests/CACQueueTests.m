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

- (void)testFIFO {
    XCTestExpectation *expectation = [self expectationWithDescription:@"FIFO Queue"];
    __block NSMutableArray *result = [NSMutableArray new];
    
    _queue = [[Queue alloc] init:QueueLIFO];
    int limit = 15;
    for (int i=0;i<limit;i++) {
        [_queue executeOperation:^{
    
            [NSThread sleepForTimeInterval:0.3f];
            NSLog(@"Operation %i is done.", i);
            [result addObject: [NSString stringWithFormat:@"%i", i]];
            
            
            
        } key:[NSString stringWithFormat:@"%i", i] cancelExisting:YES withCallback:^{
            [expectation fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        NSLog(@"Finishing result: %@", result);
        
    }];
}

- (void)testLIFO {
    _queue = [[Queue alloc] init:QueueLIFO];
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
