//
//  KUSVCTimerManagerTests.m
//  KustomerTests
//
//  Created by BrainX Technologies on 08/04/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KUSVolumeControlTimerManager.h"

static NSTimeInterval KUSTimerDelay = 10;

@interface KUSVCTimerManagerTests : XCTestCase <KUSVolumeControlTimerListener> {
    XCTestExpectation *expectation;
}
@end

@implementation KUSVCTimerManagerTests

- (void)testCreateTimerForSession
{
    expectation = [self expectationWithDescription:@"Expectation for sessionId"];
    
    [[KUSVolumeControlTimerManager sharedInstance] createVolumeControlTimerForSession:@"sessionId" listener:self delay:KUSTimerDelay];
    
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    
    [self waitForExpectationsWithTimeout:KUSTimerDelay+1 handler:nil];
    
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
}

- (void)testInvalidateTimerForSession
{
    [[KUSVolumeControlTimerManager sharedInstance] createVolumeControlTimerForSession:@"sessionId" listener:self delay:KUSTimerDelay];
    
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    
    [[KUSVolumeControlTimerManager sharedInstance] createVolumeControlTimerForSession:@"sessionId1" listener:self delay:KUSTimerDelay];
    
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId1"]);
    
    [[KUSVolumeControlTimerManager sharedInstance] invalidateVCTimerForSession:@"sessionId"];
    
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId1"]);
    
    [[KUSVolumeControlTimerManager sharedInstance] invalidateVCTimerForSession:@"sessionId1"];
    
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId1"]);
}

- (void)testInvalidateAllTimers
{
    [[KUSVolumeControlTimerManager sharedInstance] createVolumeControlTimerForSession:@"sessionId" listener:self delay:KUSTimerDelay];
    
    [[KUSVolumeControlTimerManager sharedInstance] createVolumeControlTimerForSession:@"sessionId1" listener:self delay:KUSTimerDelay];
    
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    XCTAssertTrue([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId1"]);
    
    [[KUSVolumeControlTimerManager sharedInstance] invalidateVCTimers];
    
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] hasVCTimers]);
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId"]);
    XCTAssertFalse([[KUSVolumeControlTimerManager sharedInstance] sessionHasVCTimer:@"sessionId1"]);
}

- (void)volumeControlTimerDidComplete:(KUSTimer *)timer
{
    [expectation fulfill];
}

@end
