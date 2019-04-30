//
//  KUSTimerTests.m
//  KustomerTests
//
//  Created by BrainX Technologies on 06/04/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KUSTimer.h"

static NSTimeInterval KUSTimerDelay = 10;

@interface KUSTimerTests : XCTestCase {
    XCTestExpectation *expectation;
}

@end

@implementation KUSTimerTests

- (void)testKUSTimerCreation
{
    expectation = [self expectationWithDescription:@"Expectation for schedule timer"];
    
    KUSTimer *timer = [KUSTimer scheduledTimerWithTimeInterval:KUSTimerDelay
                                                        target:self
                                                        selector:@selector(timerCompletionBlock:)
                                                        repeats:false];
    timer.userInfo = @"sessionId";
    XCTAssertEqual(timer.timeInterval, KUSTimerDelay);
    XCTAssertEqual(timer.userInfo, @"sessionId");
    XCTAssertNotNil(timer.timer);
    
    [self waitForExpectationsWithTimeout:KUSTimerDelay+1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}


- (void)testKUSTimerPause
{
    KUSTimer *timer = [KUSTimer scheduledTimerWithTimeInterval:KUSTimerDelay
                                                        target:self
                                                      selector:@selector(timerCompletionBlock:)
                                                       repeats:false];
    XCTAssertNotNil(timer.timer);
    [timer pause];
    XCTAssertNil(timer.timer);

}

- (void)testKUSTimerResume
{
    expectation = [self expectationWithDescription:@"Expectation for resume timer"];
    
    KUSTimer *timer = [KUSTimer scheduledTimerWithTimeInterval:KUSTimerDelay
                                                        target:self
                                                      selector:@selector(timerCompletionBlock:)
                                                       repeats:false];
    XCTAssertNotNil(timer.timer);
    [timer pause];
    XCTAssertNil(timer.timer);
    [timer resume];
    XCTAssertNotNil(timer.timer);
    
    [self waitForExpectationsWithTimeout:KUSTimerDelay+1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)testKUSTimerInvalidate
{
    KUSTimer *timer = [KUSTimer scheduledTimerWithTimeInterval:KUSTimerDelay
                                                        target:self
                                                      selector:@selector(timerCompletionBlock:)
                                                       repeats:false];
    XCTAssertNotNil(timer.timer);
    [timer invalidate];
    XCTAssertNil(timer.timer);
    [timer resume];
    XCTAssertNil(timer.timer);
}

- (void)timerCompletionBlock:(KUSTimer *)timer
{
    [expectation fulfill];
}

@end
