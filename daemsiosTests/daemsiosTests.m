//
//  daemsiosTests.m
//  daemsiosTests
//
//  Created by Chance on 2017/4/1.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface daemsiosTests : XCTestCase

@end

@implementation daemsiosTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    for (int a = 0; a < 10; a++) {
        NSLog(@" a = %d", a);
        if (a == 5) {
            goto reset;
        }
        NSLog(@" next a = %d", a);
    reset:
        NSLog(@"goto a = %d", a);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
