//
//  KUSRequestManagerTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 10/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSUserSession.h"
#import "KUSRequestManager.h"

static NSString *KUSTestOrgId = @"testOrgId";
static NSString *KUSTestOrgName = @"testOrgName";

@interface KUSRequestManagerTests : XCTestCase

@end

@implementation KUSRequestManagerTests

- (void)testUserSessionCreatesDefaultRequestManager
{
    KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
    XCTAssertNotNil(userSession.requestManager);
}

- (void)testRequestManagerBaseUrl
{
    KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
    KUSRequestManager *requestManager = [[KUSRequestManager alloc] initWithUserSession:userSession];
    NSURL *baseURL = [requestManager URLForEndpoint:@""];
    XCTAssertEqualObjects(baseURL.absoluteString, @"https://testOrgName.api.kustomerapp.com");
}

- (void)testRequestManagerEndpointURLs
{
    KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
    KUSRequestManager *requestManager = [[KUSRequestManager alloc] initWithUserSession:userSession];
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/customers/current"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/customers/current");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/identity"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/identity");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/pusher/auth"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/pusher/auth");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/chat/messages"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/chat/messages");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/chat/sessions"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/chat/sessions");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/chat/settings"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/chat/settings");
    XCTAssertEqualObjects([requestManager URLForEndpoint:@"/c/v1/tracking/tokens/current"].absoluteString,
                          @"https://testOrgName.api.kustomerapp.com/c/v1/tracking/tokens/current");
}

- (void)testRequestManagerInitPerformance
{
    KUSUserSession *userSession = [[KUSUserSession alloc] initWithOrgName:KUSTestOrgName orgId:KUSTestOrgId];
    [self measureBlock:^{
        __unused KUSRequestManager *requestManager = [[KUSRequestManager alloc] initWithUserSession:userSession];
    }];
}

@end
