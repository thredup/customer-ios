//
//  KustomerTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KustomerTestConstants.h"
#import "Kustomer.h"
#import "Kustomer_Private.h"
#import "KUSUserSession.h"

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
    XCTAssertEqualObjects(userSession.orgId, @"testOrgId");
    XCTAssertEqualObjects(userSession.orgName, @"testOrgName");
    XCTAssertEqualObjects(userSession.organizationName, @"TestOrgName");
}

- (void)testInitializeWithAPIKeyPerformance
{
    [self measureBlock:^{
        [Kustomer initializeWithAPIKey:KUSTestAPIKey];
    }];
}

@end
