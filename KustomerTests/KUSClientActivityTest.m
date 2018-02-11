//
//  KUSClientActivityTest.m
//  KustomerTests
//
//  Created by Daniel Amitay on 2/11/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSClientActivity.h"

@interface KUSClientActivityTest : XCTestCase

@end

@implementation KUSClientActivityTest

- (void)testClientActivityParsingOne
{
    KUSClientActivity *clientActivity = [[KUSClientActivity alloc] initWithJSON:@{
        @"type": @"client_activity",
        @"id": @"5a7afadacb1dc9001169e97e",
        @"attributes": @{
            @"trackingId": @"5a7a3d7d2d8dbf00100c4d55",
            @"intervals": @[@{ @"seconds": @35 }, @{ @"seconds": @70 }],
            @"ip": @"216.139.145.141",
            @"languages": @[@"en-US", @"en"],
            @"currentPage": @"pricing",
            @"currentPageSeconds": @0,
            @"previousPage": @"home",
            @"createdAt": @"2018-02-07T13:10:50.096Z",
            @"userAgent": @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36"
        }
    }];

    XCTAssertNotNil(clientActivity);
    NSArray<NSNumber *> *expectedIntervals = @[@35.0, @70.0];
    XCTAssertEqualObjects(clientActivity.intervals, expectedIntervals);
    XCTAssertEqualObjects(clientActivity.currentPage, @"pricing");
    XCTAssertEqualObjects(clientActivity.previousPage, @"home");
    XCTAssertEqual(clientActivity.currentPageSeconds, 0.0);
}

- (void)testClientActivityParsingTwo
{
    KUSClientActivity *clientActivity = [[KUSClientActivity alloc] initWithJSON:@{
        @"type": @"client_activity",
        @"id": @"5a7afadacb1dc9001169e97e",
        @"attributes": @{
            @"trackingId": @"5a7a3d7d2d8dbf00100c4d55",
            @"intervals": @[@{ @"seconds": @10 }, @{ @"seconds": @20 }, @{ @"seconds": @30 }],
            @"currentPage": @"profile",
            @"currentPageSeconds": @20,
            @"previousPage": @"settings",
            @"createdAt": @"2018-02-07T13:10:50.096Z",
        }
    }];

    XCTAssertNotNil(clientActivity);
    NSArray<NSNumber *> *expectedIntervals = @[@10.0, @20.0, @30.0];
    XCTAssertEqualObjects(clientActivity.intervals, expectedIntervals);
    XCTAssertEqualObjects(clientActivity.currentPage, @"profile");
    XCTAssertEqualObjects(clientActivity.previousPage, @"settings");
    XCTAssertEqual(clientActivity.currentPageSeconds, 20.0);
}

- (void)testClientActivityParsingMissingType
{
    KUSClientActivity *clientActivity = [[KUSClientActivity alloc] initWithJSON:@{
        @"id": @"5a7afadacb1dc9001169e97e",
        @"attributes": @{
            @"trackingId": @"5a7a3d7d2d8dbf00100c4d55",
            @"intervals": @[@{ @"seconds": @10 }, @{ @"seconds": @20 }, @{ @"seconds": @30 }],
            @"currentPage": @"profile",
            @"currentPageSeconds": @20,
            @"previousPage": @"settings",
            @"createdAt": @"2018-02-07T13:10:50.096Z",
        }
    }];

    XCTAssertNil(clientActivity);
}

@end
