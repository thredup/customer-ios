//
//  KUSPushClient.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPushClient.h"

#import "KUSUserSession.h"

@interface KUSPushClient () <KUSObjectDataSourceListener> {
    __weak KUSUserSession *_userSession;
}

@end

@implementation KUSPushClient

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

        [_userSession.trackingTokenDataSource addListener:self];
        [self _connectToChannelsIfNecessary];
    }
    return self;
}

#pragma mark - Channel constructors

- (NSURL *)_pusherAuthURL
{
    return [_userSession.requestManager URLForEndpoint:@"/c/v1/pusher/auth"];
}

- (NSString *)_pusherChannelName
{
    KUSTrackingToken *trackingTokenObj = _userSession.trackingTokenDataSource.object;
    if (trackingTokenObj.trackingId) {
        return [NSString stringWithFormat:@"presence-external-%@-tracking-%@", _userSession.orgId, trackingTokenObj.trackingId];
    }
    return nil;
}

- (NSString *)_pusherIdentifiedChannelName
{
    KUSTrackingToken *trackingTokenObj = _userSession.trackingTokenDataSource.object;
    if (trackingTokenObj.customerId) {
        return [NSString stringWithFormat:@"presence-external-%@-customer-%@", _userSession.orgId, trackingTokenObj.customerId];
    }
    return nil;
}

#pragma mark - Internal methods

- (void)_connectToChannelsIfNecessary
{
    // TODO:
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _connectToChannelsIfNecessary];
}

@end
