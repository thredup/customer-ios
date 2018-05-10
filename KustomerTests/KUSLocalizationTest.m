//
//  KUSLocalizationTest.m
//  KustomerTests
//
//  Created by Hunain Shahid on 08/05/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KUSLocalization.h"

@interface KUSLocalizationTest : XCTestCase

@end

@implementation KUSLocalizationTest

- (void)testTable {
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    [[KUSLocalization sharedInstance] setTable:@"Localizable.strings"];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Cancel"], @"Cancel");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Attachment"], @"Attachment");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Just now"], @"Just now");
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    [[KUSLocalization sharedInstance] setTable:@"Testing.strings"];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Cancel"], @"Cancel");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Attachment"], @"Attachment");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Just now"], @"Just now");
}

- (void)testRTL {
    BOOL systemIsRTL = [NSLocale characterDirectionForLanguage:[[NSLocale preferredLanguages] firstObject]] == NSLocaleLanguageDirectionRightToLeft;
    [[KUSLocalization sharedInstance] setLocale:nil];
    XCTAssertEqual([[KUSLocalization sharedInstance] isCurrentLanguageRTL], systemIsRTL);
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    XCTAssertEqual([[KUSLocalization sharedInstance] isCurrentLanguageRTL], NO);
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ur"]];
    XCTAssertEqual([[KUSLocalization sharedInstance] isCurrentLanguageRTL], YES);
}

- (void)testLocalizedString {
    [[KUSLocalization sharedInstance] setLocale:nil];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Cancel"], @"Cancel");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Attachment"], @"Attachment");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Just now"], @"Just now");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Camera"], @"Camera");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Photo Library"], @"Photo Library");
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Cancel"], @"Cancel");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Attachment"], @"Attachment");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Just now"], @"Just now");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Camera"], @"Camera");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Photo Library"], @"Photo Library");
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ur"]];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Cancel"], @"منسوخ کریں");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Attachment"], @"منسلکہ");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Just now"], @"ابھی ابھی");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Camera"], @"کیمرہ");
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] localizedString:@"Photo Library"], @"تصویر لائبریری");
}

- (void)testLocale {
    [[KUSLocalization sharedInstance] setLocale:nil];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] currentLocale], [NSLocale currentLocale]);
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] currentLocale], [[NSLocale alloc] initWithLocaleIdentifier:@"en"]);
    
    [[KUSLocalization sharedInstance] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ur"]];
    XCTAssertEqualObjects([[KUSLocalization sharedInstance] currentLocale], [[NSLocale alloc] initWithLocaleIdentifier:@"ur"]);
}

@end
