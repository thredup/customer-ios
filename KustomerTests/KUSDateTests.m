//
//  KUSDateTests.m
//  KustomerTests
//
//  Created by Daniel Amitay on 10/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSDate.h"

static NSTimeInterval KUSDateEpochTime = 1508694952;
static NSString *KUSExpectedDateString = @"2017-10-22T17:55:52.000Z";

@interface KUSDateTests : XCTestCase

@end

@implementation KUSDateTests

- (void)testDateToStringConversion
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:KUSDateEpochTime];
    NSString *dateString = [KUSDate stringFromDate:date];
    XCTAssertEqualObjects(dateString, KUSExpectedDateString);
}

- (void)testStringToDateConversion
{
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:KUSDateEpochTime];
    NSDate *convertedDate = [KUSDate dateFromString:KUSExpectedDateString];
    XCTAssertEqualObjects(convertedDate, expectedDate);
}

- (void)testDateToStringAndBackConversion
{
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [KUSDate stringFromDate:currentDate];
    NSDate *stringDate = [KUSDate dateFromString:dateString];
    // The conversion suffers from sub-millisecond conversion loss, but that is expected
    XCTAssertEqualWithAccuracy(stringDate.timeIntervalSince1970, currentDate.timeIntervalSince1970, 0.001);
}

- (void)test100StringToDatePerformance
{
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            __unused NSDate *convertedDate = [KUSDate dateFromString:KUSExpectedDateString];
        }
    }];
}

- (void)test100DateToStringPerformance
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:KUSDateEpochTime];
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            __unused NSString *dateString = [KUSDate stringFromDate:date];
        }
    }];
}

@end
