//
//  KUSChatMessageTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 10/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSChatMessage.h"

@interface KUSChatMessageTests : XCTestCase

@end

@implementation KUSChatMessageTests

- (void)testInvalidAutoreplyChatMessage
{
    NSString *autoreplyText = @"";
    KUSChatMessage *autoreplyMessage = [[KUSChatMessage alloc] initWithAutoreply:autoreplyText];
    XCTAssertNil(autoreplyMessage);
}

- (void)testValidAutoreplyChatMessage
{
    NSString *autoreplyText = @"Hello how can we help you?";
    KUSChatMessage *autoreplyMessage = [[KUSChatMessage alloc] initWithAutoreply:autoreplyText];
    XCTAssertNotNil(autoreplyMessage);

    XCTAssertEqual(autoreplyMessage.type, KUSChatMessageTypeText);
    XCTAssertEqual(autoreplyMessage.direction, KUSChatMessageDirectionOut);
    XCTAssertEqual(autoreplyMessage.state, KUSChatMessageStateSent);
    XCTAssertEqualObjects(autoreplyMessage.oid, @"__autoreply");
    XCTAssertEqualObjects(autoreplyMessage.body, autoreplyText);
}

@end
