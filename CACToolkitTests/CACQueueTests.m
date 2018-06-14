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
@property (nonatomic, strong) Queue *testQueue;
@end

@implementation CACQueueTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _testQueue = [[Queue alloc] init:QueueFIFO];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [_testQueue cancelAllOperations];
}

- (void)testFIFO {
    for (int i=0;i<1000;i++) {
        [_testQueue executeOperation:^{
            int count = 0;
            for (int i=0; i<100000; i++) {
                count++;
            }
        } key:[NSString stringWithFormat:@"%i", i] cancelExisting:YES];
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
    }];
}

@end
