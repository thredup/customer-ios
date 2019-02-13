//
//  KUSDescribeConversationTests.m
//  KustomerTests
//
//  Created by BrainX Technologies on 12/02/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KustomerTestConstants.h"
#import "Kustomer.h"
#import "Kustomer_Private.h"
#import "OCMock.h"
#import "KUSUserSession.h"
#import "KUSUserSession_Private.h"
#import "KUSRequestManager.h"
#import "KUSChatSessionsDataSource.h"
#import "KUSDate.h"

@interface KUSDescribeConversationTests : XCTestCase {
    NSMutableDictionary *expectedChatAttributes;
    id requestManager;
    id sessionsDataSource;
    KUSChatSession *session;
    NSInteger performRequestCount;
}
@end

@implementation KUSDescribeConversationTests

- (void)setUp
{
    [super setUp];

    [Kustomer initializeWithAPIKey:KUSTestAPIKey];
    
    NSDictionary *json = @{ @"type": @"chat_session", @"id": @"__fake" };
    session = [[KUSChatSession alloc] initWithJSON:json];
    sessionsDataSource = OCMPartialMock([[Kustomer sharedInstance].userSession chatSessionsDataSource]);
    
    requestManager = OCMClassMock([KUSRequestManager class]);
    OCMStub([requestManager performRequestType:KUSRequestTypePatch
                                      endpoint:[OCMArg any]
                                        params:[OCMArg any]
                                 authenticated:[OCMArg any]
                                    completion:[OCMArg any]]).
    andDo((^(NSInvocation *invocation){
        performRequestCount += 1;
        OCMArg* chatSessionAttibutes;
        [invocation getArgument: &chatSessionAttibutes atIndex: 4];
        NSDictionary *chatSessionAttibutesDict =(NSDictionary*)chatSessionAttibutes;
        XCTAssertTrue([chatSessionAttibutesDict[@"custom"] isEqualToDictionary:expectedChatAttributes]);
    }));
    
    [Kustomer sharedInstance].userSession.requestManager = requestManager;
}

- (void)testDescribeWithoutSession
{
    performRequestCount = 0;
    OCMStub([sessionsDataSource mostRecentSession]).andReturn(nil);
    
    NSDictionary *attribute1 = @{ @"name" : @"Najeeb" };
    [Kustomer describeConversation:attribute1];
    XCTAssertEqual(performRequestCount, 0);
 }

- (void)testDescribeWithValidSession
{
    performRequestCount = 0;
    OCMStub([sessionsDataSource mostRecentSession]).andReturn(session);
    
    NSDictionary *attribute1 = @{ @"name" : @"Najeeb" };
    expectedChatAttributes = [[NSMutableDictionary alloc]initWithDictionary:attribute1];
    [Kustomer describeConversation:attribute1];
    XCTAssertEqual(performRequestCount, 1);
}

- (void)testDescribeMergingAttribute
{
    performRequestCount = 0;
    OCMStub([sessionsDataSource mostRecentSession]).andReturn(session);
    
    NSDictionary *attribute1 = @{ @"name" : @"Najeeb" };
    expectedChatAttributes = [[NSMutableDictionary alloc]initWithDictionary:attribute1];
    [Kustomer describeConversation:attribute1];
    XCTAssertEqual(performRequestCount, 1);
    
    NSDictionary *attribute2 = @{ @"company" : @"Brainx" };
    [expectedChatAttributes addEntriesFromDictionary:attribute2];
    [Kustomer describeConversation:attribute2];
    XCTAssertEqual(performRequestCount, 2);
}


@end
