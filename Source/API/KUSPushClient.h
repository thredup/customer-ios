//
//  KUSPushClient.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KUSTypingIndicator.h"

@class KUSUserSession;
@protocol KUSPushClientListener;
@interface KUSPushClient : NSObject

@property (nonatomic, assign) BOOL supportViewControllerPresented;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;

- (void)onClientActivityTick;

// Listener methods
- (void)setListener:(id<KUSPushClientListener>)listener;
- (void)removeListener:(id<KUSPushClientListener>)listener;

// Typing indicator methods
- (void)connectToChatActivityChannel:(NSString *)sessionId;
- (void)disconnectFromChatAcitvityChannel;
- (void)sendChatActivityForSessionId:(NSString *)sessionId activityData:(NSDictionary *)activityData;


@end

@protocol KUSPushClientListener <NSObject>

@optional
- (void)pushClient:(KUSPushClient *)pushClient didChange:(KUSTypingIndicator *)typingIndicator;

@end
