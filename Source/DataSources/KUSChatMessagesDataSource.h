//
//  KUSChatMessagesDataSource.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"

#import "KUSChatMessage.h"

@class KUSChatMessagesDataSource;
@protocol KUSChatMessagesDataSourceListener <KUSPaginatedDataSourceListener>

@optional
- (void)chatMessagesDataSource:(KUSChatMessagesDataSource *)dataSource didCreateSessionId:(NSString *)sessionId;

@end

@interface KUSChatMessagesDataSource : KUSPaginatedDataSource

- (instancetype)initForNewConversationWithUserSession:(KUSUserSession *)userSession;
- (instancetype)initWithUserSession:(KUSUserSession *)userSession sessionId:(NSString *)sessionId;
- (instancetype)initWithUserSession:(KUSUserSession *)userSession NS_UNAVAILABLE;

- (void)addListener:(id<KUSChatMessagesDataSourceListener>)listener;

- (NSString *)firstOtherUserId;
- (NSUInteger)unreadCountAfterDate:(NSDate *)date;

- (void)upsertNewMessages:(NSArray<KUSChatMessage *> *)chatMessages;

- (void)sendTextMessage:(NSString *)text;
- (void)resendMessage:(KUSChatMessage *)message;

@end
