//
//  KUSUserSession.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUserSession.h"

#import "KUSPushClient.h"

@interface KUSUserSession ()

@property (nonatomic, copy, readonly) NSString *orgId;
@property (nonatomic, copy, readonly) NSString *orgName;
@property (nonatomic, copy, readonly) NSString *organizationName;  // User-facing (capitalized) version of orgName

// Lazy-loaded methods
@property (nonatomic, strong, null_resettable) KUSChatSessionsDataSource *chatSessionsDataSource;
@property (nonatomic, strong, null_resettable) KUSChatSettingsDataSource *chatSettingsDataSource;
@property (nonatomic, strong, null_resettable) KUSTrackingTokenDataSource *trackingTokenDataSource;

@property (nonatomic, strong, null_resettable) NSMutableDictionary<NSString *, KUSUserDataSource *> *userDataSources;
@property (nonatomic, strong, null_resettable) NSMutableDictionary<NSString *, KUSChatMessagesDataSource *> *chatMessagesDataSources;

@property (nonatomic, strong, null_resettable) KUSRequestManager *requestManager;
@property (nonatomic, strong, null_resettable) KUSPushClient *pushClient;

@end

@implementation KUSUserSession

#pragma mark - Lifecycle methods

- (instancetype)initWithOrgName:(NSString *)orgName orgId:(NSString *)orgId
{
    self = [super init];
    if (self) {
        _orgName = orgName;
        _orgId = orgId;

        if (_orgName.length) {
            NSString *firstLetter = [[_orgName substringToIndex:1] uppercaseString];
            _organizationName = [firstLetter stringByAppendingString:[_orgName substringFromIndex:1]];
        }

        [self pushClient];
        [self.chatSettingsDataSource fetch];
    }
    return self;
}

#pragma mark - Public methods

- (void)resetTracking
{
    // Nil out any user-specific datasources
    _chatSessionsDataSource = nil;
    _pushClient = nil;

    [self pushClient];
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

- (NSMutableDictionary<NSString *, KUSUserDataSource *> *)userDataSources
{
    if (_userDataSources == nil) {
        _userDataSources = [[NSMutableDictionary alloc] init];
    }
    return _userDataSources;
}

- (NSMutableDictionary<NSString *, KUSChatMessagesDataSource *> *)chatMessagesDataSources
{
    if (_chatMessagesDataSources == nil) {
        _chatMessagesDataSources = [[NSMutableDictionary alloc] init];
    }
    return _chatMessagesDataSources;
}

- (KUSChatMessagesDataSource *)chatMessagesDataSourceForSession:(KUSChatSession *)session
{
    NSString *sessionId = session.oid;
    KUSChatMessagesDataSource *chatMessagesDataSource = [self.chatMessagesDataSources objectForKey:sessionId];
    if (chatMessagesDataSource == nil) {
        chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithUserSession:self chatSession:session];
        [self.chatMessagesDataSources setObject:chatMessagesDataSource forKey:sessionId];
    }

    return chatMessagesDataSource;
}

- (KUSUserDataSource *)userDataSourceForUserId:(NSString *)userId
{
    if (userId.length == 0 || [userId isEqualToString:@"__team"]) {
        return nil;
    }

    KUSUserDataSource *userDataSource = [self.userDataSources objectForKey:userId];
    if (userDataSource == nil) {
        userDataSource = [[KUSUserDataSource alloc] initWithUserSession:self userId:userId];
        [self.userDataSources setObject:userDataSource forKey:userId];
    }

    return userDataSource;
}

#pragma mark - Request manager

- (KUSRequestManager *)requestManager
{
    if (_requestManager == nil) {
        _requestManager = [[KUSRequestManager alloc] initWithUserSession:self];
    }
    return _requestManager;
}

#pragma mark - Push client


- (KUSPushClient *)pushClient
{
    if (_pushClient == nil) {
        _pushClient = [[KUSPushClient alloc] initWithUserSession:self];
    }
    return _pushClient;
}

@end
