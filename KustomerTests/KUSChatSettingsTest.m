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

@end
