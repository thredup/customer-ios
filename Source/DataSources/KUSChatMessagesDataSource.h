//
//  KUSChatMessagesDataSource.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"

#import "KUSChatMessage.h"
#import "KUSFormQuestion.h"

#import <UIKit/UIKit.h>

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

- (NSString *)sessionId;
- (BOOL)isAnyMessageByCurrentUser;
- (NSString *)firstOtherUserId;
- (NSArray<NSString *> *)otherUserIds;
- (NSUInteger)unreadCountAfterDate:(NSDate *)date;
- (BOOL)shouldPreventSendingMessage;
- (KUSFormQuestion *)currentQuestion;
- (KUSChatMessage *)latestMessage;
- (KUSFormQuestion *)volumeControlCurrentQuestion;
- (BOOL)isChatClosed;

- (void)upsertNewMessages:(NSArray<KUSChatMessage *> *)chatMessages;
- (void)sendMessageWithText:(NSString *)text attachments:(NSArray<UIImage *> *)attachments;
- (void)sendMessageWithText:(NSString *)text attachments:(NSArray<UIImage *> *)attachments value:(NSString *)value;
- (void)resendMessage:(KUSChatMessage *)message;
- (void)endChat:(NSString *)reason withCompletion:(void (^)(BOOL))completion;

@end
