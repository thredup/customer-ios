//
//  KUSTypingIndicatorTest.m
//  KustomerTests
//
//  Created by Hunain Shahid on 18/04/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSTypingIndicator.h"

@interface KUSTypingIndicatorTest : XCTestCase

@end

@implementation KUSTypingIndicatorTest

- (void)testTypingIndicatorParsing {
    // Testing parsing with valid json and status (typing)
    NSDictionary *jsonTypingIndicator = @{@"id": @"__fake", @"type": @"conversation", @"userId": @"__fake_user", @"status" : @"typing"};
    KUSTypingIndicator *typingIndicator = [[KUSTypingIndicator alloc] initWithJSON:jsonTypingIndicator];
    
    XCTAssertNotNil(typingIndicator);
    XCTAssertEqual(typingIndicator.oid, @"__fake");
    XCTAssertEqual(typingIndicator.userId, @"__fake_user");
    XCTAssertEqual(typingIndicator.typingStatus, KUSTyping);
    
    // Testing parsing with valid json and status (typing-ended)
    NSDictionary *jsonTypingIndicatorTypingEnded = @{@"id": @"__fake", @"type": @"conversation", @"userId": @"__fake_user", @"status" : @"typing-ended"};
    KUSTypingIndicator *typingIndicatorEnded = [[KUSTypingIndicator alloc] initWithJSON:jsonTypingIndicatorTypingEnded];
    
    XCTAssertNotNil(typingIndicatorEnded);
    XCTAssertEqual(typingIndicatorEnded.oid, @"__fake");
    XCTAssertEqual(typingIndicatorEnded.userId, @"__fake_user");
    XCTAssertEqual(typingIndicatorEnded.typingStatus, KUSTypingEnded);
    
    // Testing parsing with valid json and unknown typing reponse
    NSDictionary *jsonTypingIndicatorTypingUnknown = @{@"id": @"__fake", @"type": @"conversation", @"userId": @"__fake_user"};
    KUSTypingIndicator *typingIndicatorUnknown = [[KUSTypingIndicator alloc] initWithJSON:jsonTypingIndicatorTypingUnknown];
    
    XCTAssertNotNil(typingIndicatorUnknown);
    XCTAssertEqual(typingIndicatorUnknown.oid, @"__fake");
    XCTAssertEqual(typingIndicatorUnknown.userId, @"__fake_user");
    XCTAssertEqual(typingIndicatorUnknown.typingStatus, KUSTypingUnknown);
    
    // Testing parsing with in-valid json
    NSDictionary *jsonTypingIndicatorTypingInvalid = @{@"type": @"conversation", @"userId": @"__fake_user"};
    KUSTypingIndicator *typingIndicatorInvalid = [[KUSTypingIndicator alloc] initWithJSON:jsonTypingIndicatorTypingInvalid];
    
    XCTAssertNil(typingIndicatorInvalid);
}


@end
