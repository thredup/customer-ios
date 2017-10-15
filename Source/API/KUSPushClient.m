//
//  KUSPushClient.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPushClient.h"

#import <Pusher/Pusher.h>
#import <Pusher/PTPusherConnection.h>

#import "KUSAudio.h"
#import "KUSNotificationWindow.h"
#import "KUSUserSession.h"

static const NSTimeInterval KUSPollingTimerInterval = 45.0;

@interface KUSPushClient () <KUSObjectDataSourceListener, KUSPaginatedDataSourceListener, PTPusherDelegate> {
    __weak KUSUserSession *_userSession;

    BOOL _shouldBeConnectedToPusher;
    NSTimer *_pollingTimer;
    NSString *_updatedSessionId;

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
        _shouldBeConnectedToPusher = NO;

        [_userSession.chatSettingsDataSource addListener:self];
        [_userSession.trackingTokenDataSource addListener:self];

        [self _connectToChannelsIfNecessary];
    }
    return self;
}

- (void)dealloc
{
    [_pollingTimer invalidate];
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
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    if (chatSettings.pusherAccessKey == nil) {
        return;
    }
    if (_userSession.trackingTokenDataSource.currentTrackingToken == nil) {
        return;
    }

    if (_pusherClient == nil) {
        _pusherClient = [PTPusher pusherWithKey:chatSettings.pusherAccessKey delegate:self encrypted:YES];
        _pusherClient.authorizationURL = [self _pusherAuthURL];
    }

    // Connect or disconnect from pusher and create or invalidate a polling timer accordingly
    if (_shouldBeConnectedToPusher) {
        // Stop polling
        [_pollingTimer invalidate];
        _pollingTimer = nil;

        // Make sure we're connected
        [_pusherClient connect];
    } else {
        // Make sure we're polling
        if (_pollingTimer == nil) {
            _pollingTimer = [NSTimer timerWithTimeInterval:KUSPollingTimerInterval
                                                    target:self
                                                  selector:@selector(_onPollTick)
                                                  userInfo:nil
                                                   repeats:YES];
            _pollingTimer.tolerance = KUSPollingTimerInterval / 10.0;
            [[NSRunLoop mainRunLoop] addTimer:_pollingTimer forMode:NSRunLoopCommonModes];

            // Tick immediately
            [_pollingTimer fire];
        }

        // Make sure we're disconnected
        [_pusherClient disconnect];
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

- (void)_onPollTick
{
    KUSTrackingToken *trackingToken = _userSession.trackingTokenDataSource.object;
    if (trackingToken.customerId.length && !_userSession.chatSessionsDataSource.didFetch) {
        [_userSession.chatSessionsDataSource fetchLatest];
    }

    if (_userSession.chatSessionsDataSource.didFetch) {
        for (KUSChatSession *session in _userSession.chatSessionsDataSource.allObjects) {
            KUSChatMessagesDataSource *messagesDataSource = [_userSession chatMessagesDataSourceForSessionId:session.oid];
            [messagesDataSource addListener:self];
            [messagesDataSource fetchLatest];
        }
    }
}

#pragma mark - Property methods

- (void)setSupportViewControllerPresented:(BOOL)supportViewControllerPresented
{
    _supportViewControllerPresented = supportViewControllerPresented;
    _shouldBeConnectedToPusher = supportViewControllerPresented;

    [self _connectToChannelsIfNecessary];
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

    if (self.supportViewControllerPresented) {
        [KUSAudio playMessageReceivedSound];
    } else {
        KUSChatMessage *chatMessage = chatMessages.firstObject;
        KUSChatSession *chatSession = [[_userSession chatSessionsDataSource] objectWithId:chatMessage.sessionId];
        if ([_userSession.delegateProxy shouldDisplayInAppNotification] && chatSession) {
            [KUSAudio playMessageReceivedSound];
            [[KUSNotificationWindow sharedInstance] showChatSession:chatSession];
        }
    }
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _connectToChannelsIfNecessary];

    KUSTrackingToken *trackingToken = _userSession.trackingTokenDataSource.object;
    if (trackingToken.customerId.length && !_userSession.chatSessionsDataSource.didFetch) {
        [_userSession.chatSessionsDataSource fetchLatest];
    }
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSource:(KUSPaginatedDataSource *)dataSource
            didChangeObject:(__kindof KUSModel *)object
                    atIndex:(NSUInteger)oldIndex
              forChangeType:(KUSPaginatedDataSourceChangeType)type
                   newIndex:(NSUInteger)newIndex
{
    if (_pollingTimer == nil) {
        return;
    }
    if (![dataSource isKindOfClass:[KUSChatMessagesDataSource class]]) {
        return;
    }
    if (type != KUSPaginatedDataSourceChangeInsert) {
        return;
    }

    KUSChatMessage *chatMessage = (KUSChatMessage *)object;
    _updatedSessionId = chatMessage.sessionId;
}

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (_updatedSessionId) {
        KUSChatSession *chatSession = [[_userSession chatSessionsDataSource] objectWithId:_updatedSessionId];
        if ([_userSession.delegateProxy shouldDisplayInAppNotification] && chatSession) {
            [KUSAudio playMessageReceivedSound];
            [[KUSNotificationWindow sharedInstance] showChatSession:chatSession];
        }
    }
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
