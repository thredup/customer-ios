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

- (void)testFailedChatMessage
{
    NSString *failedText = @"Yes it is red";
    KUSChatMessage *failedMessage = [[KUSChatMessage alloc] initFailedWithText:failedText];
    XCTAssertNotNil(failedMessage);

    XCTAssertEqual(failedMessage.type, KUSChatMessageTypeText);
    XCTAssertEqual(failedMessage.direction, KUSChatMessageDirectionIn);
    XCTAssertEqual(failedMessage.state, KUSChatMessageStateFailed);
    XCTAssertNotNil(failedMessage.oid);
    XCTAssertEqualObjects(failedMessage.body, failedText);
}

- (void)testSendingChatMessagesSingle
{
    NSString *sendingText = @"Hey how are you?";
    NSArray<KUSChatMessage *> *messages = [KUSChatMessage messagesWithSendingText:sendingText];
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1);

    KUSChatMessage *chatMessage = [messages firstObject];
    XCTAssertNotNil(chatMessage);
    XCTAssertEqual(chatMessage.type, KUSChatMessageTypeText);
    XCTAssertEqual(chatMessage.direction, KUSChatMessageDirectionIn);
    XCTAssertEqual(chatMessage.state, KUSChatMessageStateSending);
    XCTAssertNotNil(chatMessage.oid);
    XCTAssertEqualObjects(chatMessage.body, sendingText);
}

- (void)testSendingChatMessagesDouble
{
    NSString *sendingText = @"Here is what it looks like: ![Image](https://www.example.com/image.png)";
    NSArray<KUSChatMessage *> *messages = [KUSChatMessage messagesWithSendingText:sendingText];
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 2);

    KUSChatMessage *firstMessage = [messages firstObject];
    XCTAssertNotNil(firstMessage);
    XCTAssertEqual(firstMessage.type, KUSChatMessageTypeText);
    XCTAssertEqual(firstMessage.direction, KUSChatMessageDirectionIn);
    XCTAssertEqual(firstMessage.state, KUSChatMessageStateSending);
    XCTAssertNotNil(firstMessage.oid);
    XCTAssertEqualObjects(firstMessage.body, @"Here is what it looks like:");

    KUSChatMessage *secondMessage = [messages lastObject];
    XCTAssertNotNil(secondMessage);
    XCTAssertEqual(secondMessage.type, KUSChatMessageTypeImage);
    XCTAssertEqual(secondMessage.direction, KUSChatMessageDirectionIn);
    XCTAssertEqual(secondMessage.state, KUSChatMessageStateSending);
    XCTAssertNotNil(secondMessage.oid);
    XCTAssertEqualObjects(secondMessage.body, @"https://www.example.com/image.png");
    XCTAssertEqualObjects(secondMessage.imageURL.absoluteString, @"https://www.example.com/image.png");
}

@end
