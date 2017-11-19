//
//  KUSChatSettingsTest.m
//  KustomerTests
//
//  Created by Daniel Amitay on 11/19/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSChatSettings.h"

@interface KUSChatSettingsTest : XCTestCase

@end

@implementation KUSChatSettingsTest

- (void)testAutoreplyWhitespaceTrim
{
    NSDictionary *json = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes" : @{ @"autoreply": @"  Hello\n" }};
    KUSChatSettings *chatSettings = [[KUSChatSettings alloc] initWithJSON:json];
    XCTAssertNotNil(chatSettings);
    XCTAssertEqualObjects(chatSettings.autoreply, @"Hello");
}

- (void)testWhitespaceAutoreply
{
    NSDictionary *json = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes" : @{ @"autoreply": @"  " }};
    KUSChatSettings *chatSettings = [[KUSChatSettings alloc] initWithJSON:json];
    XCTAssertNotNil(chatSettings);
    XCTAssertNil(chatSettings.autoreply);
}

@end
