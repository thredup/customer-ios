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
@property (nonatomic, strong, null_resettable) KUSUsersDataSource *usersDataSource;

@property (nonatomic, strong, null_resettable) KUSRequestManager *requestManager;

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

        [self.chatSettingsDataSource fetch];
    }
    return self;
}

#pragma mark - Public methods

- (void)resetTracking
{
    // Nil out any user-specific datasources
    _chatSessionsDataSource = nil;

    // Request a new tracking token
    [self.trackingTokenDataSource reset];
}

#pragma mark - Datasource objects

- (KUSChatSessionsDataSource *)chatSessionsDataSource
{
    if (_chatSessionsDataSource == nil) {
        _chatSessionsDataSource = [[KUSChatSessionsDataSource alloc] initWithUserSession:self];
    }
    return _chatSessionsDataSource;
}

- (KUSChatSettingsDataSource *)chatSettingsDataSource
{
    if (_chatSettingsDataSource == nil) {
        _chatSettingsDataSource = [[KUSChatSettingsDataSource alloc] initWithUserSession:self];
    }
    return _chatSettingsDataSource;
}

- (KUSTrackingTokenDataSource *)trackingTokenDataSource
{
    if (_trackingTokenDataSource == nil) {
        _trackingTokenDataSource = [[KUSTrackingTokenDataSource alloc] initWithUserSession:self];
    }
    return _trackingTokenDataSource;
}

- (KUSUsersDataSource *)usersDataSource
{
    if (_usersDataSource == nil) {
        _usersDataSource = [[KUSUsersDataSource alloc] initWithUserSession:self];
    }
    return _usersDataSource;
}

#pragma mark - Request manager

- (KUSRequestManager *)requestManager
{
    if (_requestManager == nil) {
        _requestManager = [[KUSRequestManager alloc] initWithUserSession:self];
    }
    return _requestManager;
}

@end
