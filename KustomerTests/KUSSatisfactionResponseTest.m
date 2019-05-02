//
//  KUSSatisfactionResponseTest.m
//  KustomerTests
//
//  Created by BrainX Technologies on 24/04/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KUSSatisfactionResponse.h"

@interface KUSSatisfactionResponseTest : XCTestCase

@end

@implementation KUSSatisfactionResponseTest

- (void)testSatisfactionResponseInitializer
{
    KUSSatisfactionResponse *satisfactionResponse = [[KUSSatisfactionResponse alloc] initWithJSON:@{
        @"type": @"satisfaction_response",
        @"id": @"fake_satisfaction_response_id",
        @"attributes": @{
            @"answers": @[@{
                @"id": @"fake_answer_id",
                @"answer": @"Nice experience"
            }],
            @"createdAt": @"2019-04-18T13:03:39.511Z",
            @"updatedAt": @"2019-04-18T13:03:39.511Z",
            @"lockedAt": @"2019-04-18T13:03:39.511Z",
            @"submittedAt": @"2019-04-18T13:03:39.511Z",
            @"rating": @2,
            @"status": @"rated"
        }
    }];

    XCTAssertNotNil(satisfactionResponse);
    XCTAssertNotNil(satisfactionResponse.createdAt);
    XCTAssertNotNil(satisfactionResponse.updatedAt);
    XCTAssertNotNil(satisfactionResponse.lockedAt);
    XCTAssertNotNil(satisfactionResponse.submittedAt);
    XCTAssertEqual(satisfactionResponse.rating, 2);
    XCTAssertEqual(satisfactionResponse.status, KUSSatisfactionResponseStatusRated);
    XCTAssertEqual(satisfactionResponse.answers.count, 1);
    XCTAssertEqual([satisfactionResponse.answers objectForKey:@"fake_answer_id"], @"Nice experience");
    
}

@end
