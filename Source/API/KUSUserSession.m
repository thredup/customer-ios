//
//  KUSUserSession.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUserSession.h"

@interface KUSUserSession ()

@property (nonatomic, copy, readonly) NSString *orgName;
@property (nonatomic, copy, readonly) NSString *organizationName;  // User-facing (capitalized) version of orgName

// Lazy-loaded methods
@property (nonatomic, strong, null_resettable) KUSChatSessionsDataSource *chatSessionsDataSource;
@property (nonatomic, strong, null_resettable) KUSChatSettingsDataSource *chatSettingsDataSource;
@property (nonatomic, strong, null_resettable) KUSTrackingTokenDataSource *trackingTokenDataSource;

@end

@implementation KUSUserSession

#pragma mark - Lifecycle methods

- (instancetype)initWithOrgName:(NSString *)orgName
{
    self = [super init];
    if (self) {
        _orgName = orgName;

        if (_orgName.length) {
            NSString *firstLetter = [[_orgName substringToIndex:1] uppercaseString];
            _organizationName = [firstLetter stringByAppendingString:[_orgName substringFromIndex:1]];
        }
    }
    return self;
}

#pragma mark - Datasource objects

- (KUSChatSessionsDataSource *)chatSessionsDataSource
{
    if (_chatSessionsDataSource == nil) {
        // TODO: Fix when converted to userSession
        _chatSessionsDataSource = [[KUSChatSessionsDataSource alloc] initWithAPIClient:nil];
    }
    return _chatSessionsDataSource;
}

- (KUSChatSettingsDataSource *)chatSettingsDataSource
{
    if (_chatSettingsDataSource == nil) {
        // TODO: Fix when converted to userSession
        _chatSettingsDataSource = [[KUSChatSettingsDataSource alloc] initWithAPIClient:nil];
    }
    return _chatSettingsDataSource;
}

- (KUSTrackingTokenDataSource *)trackingTokenDataSource
{
    if (_trackingTokenDataSource == nil) {
        // TODO: Fix when converted to userSession
        _trackingTokenDataSource = [[KUSTrackingTokenDataSource alloc] initWithAPIClient:nil];
    }
    return _trackingTokenDataSource;
}

@end
