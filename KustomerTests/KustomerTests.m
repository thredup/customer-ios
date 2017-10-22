//
//  KustomerTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Kustomer.h"
#import "Kustomer_Private.h"
#import "KUSUserSession.h"

static NSString *KUSTestAPIKey = @"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJvcmdOYW1lIjoidGVzdCIsIm9yZyI6InRlc3QiLCJqdGkiOiIxNDkyYTM2Mi1kNzA2LTQzYTgtOWY5Ni01ZTcwODg0NjU0MmYiLCJpYXQiOjE1MDg2NDYzNDYsImV4cCI6MTUwODY0OTk0Nn0.829Y_s-fvslDJIQueqjjfBUkdxNXshJFFM5Hl7m4g8M";

@interface KustomerTests : XCTestCase

@end

@implementation KustomerTests

- (void)setUp
{
    [super setUp];
    [Kustomer setLogOptions:kNilOptions];
}

- (void)testExpectsValidAPIKey
{
    XCTAssertThrows([Kustomer initializeWithAPIKey:nil]);
    XCTAssertThrows([Kustomer initializeWithAPIKey:@""]);
    XCTAssertThrows([Kustomer initializeWithAPIKey:@"key"]);
}

- (void)testValidAPIKeySuccess
{
    XCTAssertNoThrow([Kustomer initializeWithAPIKey:KUSTestAPIKey]);
}

- (void)testWasProperlySetup
{
    [Kustomer initializeWithAPIKey:KUSTestAPIKey];
    XCTAssertNotNil([Kustomer sharedInstance]);
    XCTAssertNotNil([Kustomer sharedInstance].userSession);
}

- (void)testUserSessionHasExpectedProperties
{
    [Kustomer initializeWithAPIKey:KUSTestAPIKey];
    KUSUserSession *userSession = [Kustomer sharedInstance].userSession;
    XCTAssertEqualObjects(userSession.orgId, @"test");
    XCTAssertEqualObjects(userSession.orgName, @"test");
    XCTAssertEqualObjects(userSession.organizationName, @"Test");
}

- (void)testInitializeWithAPIKeyPerformance
{
    [self measureBlock:^{
        [Kustomer initializeWithAPIKey:KUSTestAPIKey];
    }];
}

@end
