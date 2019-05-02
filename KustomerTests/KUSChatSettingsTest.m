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

- (void)testKUSBusinessHoursAvailability
{
    //Online
    NSDictionary *jsonOnline = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"offhoursDisplay": @"online" }};
    KUSChatSettings *chatSettingsOnline = [[KUSChatSettings alloc] initWithJSON:jsonOnline];
    XCTAssertNotNil(chatSettingsOnline);
    XCTAssertEqual(chatSettingsOnline.availability, KUSBusinessHoursAvailabilityOnline);
    
    //Offline
    NSDictionary *jsonOffline = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"offhoursDisplay": @"offline" }};
    KUSChatSettings *chatSettingsOffline = [[KUSChatSettings alloc] initWithJSON:jsonOffline];
    XCTAssertNotNil(chatSettingsOffline);
    XCTAssertEqual(chatSettingsOffline.availability, KUSBusinessHoursAvailabilityOffline);
    
    //Hide Chat
    NSDictionary *jsonHideChat = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"offhoursDisplay": @"unknown" }};
    KUSChatSettings *chatSettingsHideChat = [[KUSChatSettings alloc] initWithJSON:jsonHideChat];
    XCTAssertNotNil(chatSettingsHideChat);
    XCTAssertEqual(chatSettingsHideChat.availability, KUSBusinessHoursAvailabilityHideChat);
}

- (void)testKUSVolumeControlMode
{
    //Upfront
    NSDictionary *jsonUpfront = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"volumeControl": @{ @"mode": @"upfront" }}};
    KUSChatSettings *chatSettingsUpfront = [[KUSChatSettings alloc] initWithJSON:jsonUpfront];
    XCTAssertNotNil(chatSettingsUpfront);
    XCTAssertEqual(chatSettingsUpfront.volumeControlMode, KUSVolumeControlModeUpfront);
    
    //Delayed
    NSDictionary *jsonDelayed = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"volumeControl": @{ @"mode": @"delayed" }}};
    KUSChatSettings *chatSettingsDelayed = [[KUSChatSettings alloc] initWithJSON:jsonDelayed];
    XCTAssertNotNil(chatSettingsDelayed);
    XCTAssertEqual(chatSettingsDelayed.volumeControlMode, KUSVolumeControlModeDelayed);
    
    //Unknown
    NSDictionary *jsonUnknown = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"volumeControl": @{ @"mode": @"unknown" }}};
    KUSChatSettings *chatSettingsUnknown = [[KUSChatSettings alloc] initWithJSON:jsonUnknown];
    XCTAssertNotNil(chatSettingsUnknown);
    XCTAssertEqual(chatSettingsUnknown.volumeControlMode, KUSVolumeControlModeUnknown);
}

- (void)testTypingIndicatorSettingCustomerWeb
{
    NSDictionary *jsonTypingIndicatorCustomerWebNil = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ }};
    KUSChatSettings *chatSettingsTypingIndicatorCustomerWebNil = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorCustomerWebNil];
    XCTAssertNotNil(chatSettingsTypingIndicatorCustomerWebNil);
    XCTAssertFalse(chatSettingsTypingIndicatorCustomerWebNil.shouldShowTypingIndicatorCustomerWeb);
    
    NSDictionary *jsonTypingIndicatorCustomerWebNo = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"showTypingIndicatorCustomerWeb": @NO}};
    KUSChatSettings *chatSettingsTypingIndicatorCustomerWebNo = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorCustomerWebNo];
    XCTAssertNotNil(chatSettingsTypingIndicatorCustomerWebNo);
    XCTAssertFalse(chatSettingsTypingIndicatorCustomerWebNo.shouldShowTypingIndicatorCustomerWeb);
    
    NSDictionary *jsonTypingIndicatorCustomerWebYes = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"showTypingIndicatorCustomerWeb": @YES}};
    KUSChatSettings *chatSettingsTypingIndicatorCustomerWebYes = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorCustomerWebYes];
    XCTAssertNotNil(chatSettingsTypingIndicatorCustomerWebYes);
    XCTAssertTrue(chatSettingsTypingIndicatorCustomerWebYes.shouldShowTypingIndicatorCustomerWeb);
}

- (void)testTypingIndicatorSettingWeb
{
    NSDictionary *jsonTypingIndicatorWebNil = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ }};
    KUSChatSettings *chatSettingsTypingIndicatorWebNil = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorWebNil];
    XCTAssertNotNil(chatSettingsTypingIndicatorWebNil);
    XCTAssertFalse(chatSettingsTypingIndicatorWebNil.shouldShowTypingIndicatorWeb);
    
    NSDictionary *jsonTypingIndicatorWebNo = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"showTypingIndicatorWeb": @NO}};
    KUSChatSettings *chatSettingsTypingIndicatorWebNo = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorWebNo];
    XCTAssertNotNil(chatSettingsTypingIndicatorWebNo);
    XCTAssertFalse(chatSettingsTypingIndicatorWebNo.shouldShowTypingIndicatorWeb);
    
    NSDictionary *jsonTypingIndicatorWebYes = @{@"id": @"__fake", @"type": @"chat_settings", @"attributes": @{ @"showTypingIndicatorWeb": @YES}};
    KUSChatSettings *chatSettingsTypingIndicatorWebYes = [[KUSChatSettings alloc] initWithJSON:jsonTypingIndicatorWebYes];
    XCTAssertNotNil(chatSettingsTypingIndicatorWebYes);
    XCTAssertTrue(chatSettingsTypingIndicatorWebYes.shouldShowTypingIndicatorWeb);
}

@end
