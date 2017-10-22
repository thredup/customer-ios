//
//  KUSDelegateProxyTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 10/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSDelegateProxy.h"

@interface KUSDelegateProxyTests : XCTestCase <KustomerDelegate> {
    KUSDelegateProxy *_delegateProxy;

    BOOL _shouldDisplayInAppNotification;
    BOOL _didTapOnInAppNotification;
}

@end

@implementation KUSDelegateProxyTests

- (void)setUp
{
    [super setUp];

    _delegateProxy = [[KUSDelegateProxy alloc] init];
    _shouldDisplayInAppNotification = NO;
    _didTapOnInAppNotification = NO;
}

- (void)testDefaultBehavior
{
    XCTAssertTrue([_delegateProxy shouldDisplayInAppNotification]);

    [_delegateProxy didTapOnInAppNotification];
    XCTAssertFalse(_didTapOnInAppNotification);
}

- (void)testOverriddenBehavior
{
    [_delegateProxy setDelegate:self];

    _shouldDisplayInAppNotification = YES;
    XCTAssertTrue([_delegateProxy shouldDisplayInAppNotification]);

    _shouldDisplayInAppNotification = NO;
    XCTAssertFalse([_delegateProxy shouldDisplayInAppNotification]);

    _shouldDisplayInAppNotification = YES;
    XCTAssertTrue([_delegateProxy shouldDisplayInAppNotification]);

    [_delegateProxy didTapOnInAppNotification];
    XCTAssertTrue(_didTapOnInAppNotification);
}

#pragma mark - KustomerDelegate methods

- (BOOL)kustomerShouldDisplayInAppNotification
{
    return _shouldDisplayInAppNotification;
}

- (void)kustomerDidTapOnInAppNotification
{
    _didTapOnInAppNotification = YES;
}

@end
