//
//  KUSChatMessagesDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessagesDataSource.h"

#import "KUSLog.h"
#import "KUSPaginatedDataSource_Private.h"

@interface KUSChatMessagesDataSource () {
    NSString *_sessionId;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession sessionId:(NSString *)sessionId;
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _sessionId = sessionId;
    }
    return self;
}

#pragma mark - KUSPaginatedDataSource methods

- (NSURL *)firstURL
{
    if (_sessionId) {
        NSString *endpoint = [NSString stringWithFormat:@"/c/v1/chat/sessions/%@/messages", _sessionId];
        return [self.userSession.requestManager URLForEndpoint:endpoint];
    }
    return nil;
}

- (Class)modelClass
{
    return [KUSChatMessage class];
}

#pragma mark - Public methods

- (NSString *)firstOtherUserId
{
    for (KUSChatMessage *message in self.allObjects) {
        BOOL currentUser = message.direction == KUSChatMessageDirectionIn;
        if (!currentUser) {
            return message.sentById;
        }
    }
    return nil;
}

- (NSUInteger)unreadCountAfterDate:(NSDate *)date
{
    NSUInteger count = 0;
    for (KUSChatMessage *message in self.allObjects) {
        BOOL currentUser = message.direction == KUSChatMessageDirectionIn;
        if (currentUser) {
            return count;
        }
        if (message.createdAt) {
            if ([message.createdAt compare:date] == NSOrderedAscending) {
                return count;
            }
            count++;
        }
    }
    return count;
}

- (void)upsertNewMessages:(NSArray<KUSChatMessage *> *)chatMessages
{
    if (chatMessages.count == 1) {
        [self prependObjects:chatMessages];
    } else if (chatMessages.count > 1) {
        NSMutableArray<KUSChatMessage *> *reversedMessages = [[NSMutableArray alloc] initWithCapacity:chatMessages.count];
        for (KUSChatMessage *chatMessage in chatMessages.reverseObjectEnumerator) {
            [reversedMessages addObject:chatMessage];
        }
        [self prependObjects:reversedMessages];
    }
}

- (void)sendTextMessage:(NSString *)text
{
    NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage messagesWithSendingText:text];
    if (temporaryMessages.count) {
        [self upsertNewMessages:temporaryMessages];
    }

    __weak KUSChatMessagesDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/chat/messages"
     params:@{ @"body": text, @"session": _sessionId }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (temporaryMessages.count) {
             [weakSelf removeObjects:temporaryMessages];
         }
         if (error) {
             KUSLogError(@"Error sending message: %@", error);

             KUSChatMessage *failedMessage = [[KUSChatMessage alloc] initFailedWithText:text];
             [weakSelf upsertNewMessages:@[failedMessage]];
             return;
         }

         NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage objectsWithJSON:response[@"data"]];
         if (temporaryMessages.count) {
             [weakSelf upsertNewMessages:temporaryMessages];
         }
     }];
}

- (void)resendMessage:(KUSChatMessage *)message
{
    if (message) {
        [self removeObjects:@[ message ]];
        [self sendTextMessage:message.body];
    }
}

@end
