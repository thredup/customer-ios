//
//  KUSSatisfactionFormTest.m
//  KustomerTests
//
//  Created by BrainX Technologies on 24/04/2019.
//  Copyright © 2019 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KUSSatisfactionForm.h"

@interface KUSSatisfactionFormTest : XCTestCase

@end

@implementation KUSSatisfactionFormTest

- (void)testSatisfactionFormInitializer
{
    
    KUSSatisfactionForm *satisfactionForm = [[KUSSatisfactionForm alloc] initWithJSON:@{
      @"type": @"satisfaction",
      @"id": @"fake_satisfaction_id",
      @"attributes": @{
              @"questions": @[@{
                      @"id": @"fake_question_id",
                      @"prompt": @"Thank you, Any further details? Share your experience with us?",
                      @"type": @"response"
                }],
              @"ratingPrompt": @"How satisfied were you with your interaction?",
              @"scale": @{
                      @"labelHigh": @"Extremely Likely",
                      @"labelLow": @"Not Likely at all",
                      @"options": @5,
                      @"type": @"number"
                }
        }
      }];
    
    XCTAssertNotNil(satisfactionForm);
    XCTAssertEqualObjects(satisfactionForm.ratingPrompt, @"How satisfied were you with your interaction?");
    XCTAssertEqualObjects(satisfactionForm.scaleLabelLow, @"Not Likely at all");
    XCTAssertEqualObjects(satisfactionForm.scaleLabelHigh, @"Extremely Likely");
    XCTAssertEqual(satisfactionForm.scaleType, KUSSatisfactionScaleTypeNumber);
    XCTAssertEqual(satisfactionForm.scaleOptions, 5);
    KUSFormQuestion *formQuestion = satisfactionForm.questions.firstObject;
    XCTAssertEqualObjects(formQuestion.prompt, @"Thank you, Any further details? Share your experience with us?");
}


@end
