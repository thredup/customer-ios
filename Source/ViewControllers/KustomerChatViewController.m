//
//  KustomerChatViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/2/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerChatViewController.h"

#import <Pusher/Pusher.h>

// TODO: Move elsewhere/retrieve from server
static NSString *kPusherAPIKey = @"ACCESS_TOKEN";
static NSString *kPusherAuthEndpoint = @"https://kustomer.api.kustomerapp.com/c/v1/pusher/auth";

@interface KustomerChatViewController () <PTPusherDelegate>

@property (nonatomic, strong) PTPusher *pusherClient;

@end

@implementation KustomerChatViewController

#pragma mark - Lifecycle methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];

    self.pusherClient = [PTPusher pusherWithKey:kPusherAPIKey delegate:self encrypted:YES];
    self.pusherClient.authorizationURL = [NSURL URLWithString:kPusherAuthEndpoint];

    PTPusherChannel *appChannel = [self.pusherClient subscribeToChannelNamed:@"app"];
    PTPusherChannel *identityChannel = [self.pusherClient subscribeToChannelNamed:@"identity"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAppChannelEventNotification:)
                                                 name:PTPusherEventReceivedNotification
                                               object:appChannel];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveIdentityChannelEventNotification:)
                                                 name:PTPusherEventReceivedNotification
                                               object:identityChannel];

    [self.pusherClient connect];
}

#pragma mark - PTPusherDelegate methods

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect
{
    NSLog(@"Did disconnect with error: %@", error);
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error
{
    NSLog(@"Failed with error: %@", error);
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent
{
    NSLog(@"Did receive error event: %@", errorEvent.message);
}

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Connection did connect");
}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel
{
    NSLog(@"Did subscribe to channel: %@", channel.name);
}

- (void)pusher:(PTPusher *)pusher
willAuthorizeChannel:(PTPusherChannel *)channel
withAuthOperation:(PTPusherChannelAuthorizationOperation *)operation
{
    [operation.mutableURLRequest setValue:@"kustomer" forHTTPHeaderField:@"X-Kustomer"];
    [operation.mutableURLRequest setValue:@"" forHTTPHeaderField:@"x-kustomer-tracking-token"];
}

#pragma mark - Event methods

- (void)didReceiveAppChannelEventNotification:(NSNotification *)notification
{
    PTPusherEvent *event = [notification.userInfo objectForKey:PTPusherEventUserInfoKey];
    NSLog(@"App channel event: %@", event);
}

- (void)didReceiveIdentityChannelEventNotification:(NSNotification *)notification
{
    PTPusherEvent *event = [notification.userInfo objectForKey:PTPusherEventUserInfoKey];
    NSLog(@"Identity channel event: %@", event);
}

@end
