//
//  KUSPushClient.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPushClient.h"

#import <Pusher/Pusher.h>

#import "KUSUserSession.h"

@interface KUSPushClient () <KUSObjectDataSourceListener, PTPusherDelegate> {
    __weak KUSUserSession *_userSession;

    PTPusher *_pusherClient;
    PTPusherChannel *_pusherChannel;
    PTPusherChannel *_pusherIdentifiedChannel;
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

- (void)dealloc
{
    [_pusherClient unsubscribeAllChannels];
    [_pusherClient disconnect];
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
    if (_userSession.trackingTokenDataSource.currentTrackingToken == nil) {
        return;
    }

    if (_pusherClient == nil) {
        _pusherClient = [PTPusher pusherWithKey:@"YOUR_API_KEY" delegate:self encrypted:YES];
        _pusherClient.authorizationURL = [self _pusherAuthURL];
        [_pusherClient connect];
    }

    NSString *pusherChannelName = [self _pusherChannelName];
    if (pusherChannelName && _pusherChannel == nil) {
        _pusherChannel = [_pusherClient subscribeToChannelNamed:pusherChannelName];
        [_pusherChannel bindToEventNamed:@"kustomer.tracking.identity.update"
                                  target:self
                                  action:@selector(_onPusherIdentityUpdate:)];
    }

    NSString *pusherIdentifiedChannelName = [self _pusherIdentifiedChannelName];
    if (pusherIdentifiedChannelName && _pusherIdentifiedChannel == nil) {
        _pusherIdentifiedChannel = [_pusherClient subscribeToChannelNamed:pusherIdentifiedChannelName];
        [_pusherIdentifiedChannel bindToEventNamed:@"kustomer.app.chat.message.send"
                                            target:self
                                            action:@selector(_onPusherChatMessageSend:)];
    }
}

#pragma mark - Pusher event methods

- (void)_onPusherIdentityUpdate:(PTPusherEvent *)event
{
    NSLog(@"Received updated tracking token from Pusher");

    [_userSession.trackingTokenDataSource fetch];
}

- (void)_onPusherChatMessageSend:(PTPusherEvent *)event
{
    NSLog(@"Received chat message from Pusher");

    NSArray<KUSChatMessage *> *chatMessages = [KUSChatMessage objectsWithJSON:event.data[@"data"]];
    for (KUSChatMessage *chatMessage in chatMessages) {
        KUSChatMessagesDataSource *messagesDataSource = [_userSession chatMessagesDataSourceForSessionId:chatMessage.sessionId];
        [messagesDataSource upsertMessageReceivedFromPusher:chatMessage];
    }
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _connectToChannelsIfNecessary];
}

#pragma mark - PTPusherDelegate methods

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Pusher connection did connect");
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect
{
    NSLog(@"Pusher connection did disconnect with errror: %@", error);
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error
{
    NSLog(@"Pusher connection failed with error: %@", error);
}

- (void)pusher:(PTPusher *)pusher willAuthorizeChannel:(PTPusherChannel *)channel
withAuthOperation:(PTPusherChannelAuthorizationOperation *)operation
{
    [operation.mutableURLRequest setValue:kKustomerCORSHeaderValue forHTTPHeaderField:kKustomerCORSHeaderKey];
    [operation.mutableURLRequest setValue:_userSession.trackingTokenDataSource.currentTrackingToken
                       forHTTPHeaderField:kKustomerTrackingTokenHeaderKey];
}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel
{
    NSLog(@"Pusher did subscribe to channel: %@", channel.name);
}

- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error
{
    NSLog(@"Pusher did fail to subscribe to channel: %@ with error: %@", channel.name, error);
}

@end
