//
//  KUSChatMessagesDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessagesDataSource.h"

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

- (void)upsertMessageReceivedFromPusher:(KUSChatMessage *)chatMessage
{
    if (chatMessage) {
        [self prependObjects:@[ chatMessage ]];
    }
}

- (void)sendTextMessage:(NSString *)text completion:(void(^)(NSError *error, KUSChatMessage *message))completion
{
    NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage messagesWithPlaceholderText:text];
    if (temporaryMessages.count) {
        [self prependObjects:temporaryMessages];
    }

    __weak KUSChatMessagesDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/chat/messages"
     params:@{ @"body": text, @"session": _sessionId }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (temporaryMessages.count) {
             [self removeObjects:temporaryMessages];
         }
         if (error) {
             if (completion) {
                 completion(error, nil);
             }
             return;
         }

         NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage objectsWithJSON:response[@"data"]];
         if (temporaryMessages.count) {
             [weakSelf prependObjects:temporaryMessages];
         }

         KUSChatMessage *message = [[KUSChatMessage alloc] initWithJSON:response[@"data"]];
         if (completion) {
             completion(nil, message);
         }
     }];
}

@end
