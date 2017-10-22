//
//  KUSUserSessionTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 10/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KustomerTestConstants.h"
#import "KUSUserSession.h"

@interface KUSUserSessionTests : XCTestCase

@end

@implementation KUSUserSessionTests

- (void)testUserSessionCreatesDefaultProperties
{
    KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
    XCTAssertNotNil(userSession.chatSessionsDataSource);
    XCTAssertNotNil(userSession.chatSettingsDataSource);
    XCTAssertNotNil(userSession.trackingTokenDataSource);
    XCTAssertNotNil(userSession.requestManager);
    XCTAssertNotNil(userSession.pushClient);
    XCTAssertNotNil(userSession.delegateProxy);
}

- (void)test100UserSessionsPerformance
{
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            __unused KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
        }
    }];
}

@end
