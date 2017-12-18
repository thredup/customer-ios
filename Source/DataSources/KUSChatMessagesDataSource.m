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
#import "KUSUserSession_Private.h"

@interface KUSChatMessagesDataSource () {
    NSString *_sessionId;
    BOOL _createdLocally;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)initForNewConversationWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _createdLocally = YES;
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession sessionId:(NSString *)sessionId;
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _sessionId = sessionId;
    }
    return self;
}

#pragma mark - KUSPaginatedDataSource methods

- (void)addListener:(id<KUSChatMessagesDataSourceListener>)listener
{
    [super addListener:listener];
}

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

- (BOOL)didFetch
{
    if (_createdLocally) {
        return YES;
    }
    return [super didFetch];
}

- (BOOL)didFetchAll
{
    if (_createdLocally) {
        return YES;
    }
    return [super didFetchAll];
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
    // Insert placeholder "sending" messages
    NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage messagesWithSendingText:text];
    if (temporaryMessages.count) {
        [self upsertNewMessages:temporaryMessages];
    }

    // Logic to handle a chat session error or a message send error
    void(^handleError)(void) = ^void() {
        [self removeObjects:temporaryMessages];

        KUSChatMessage *failedMessage = [[KUSChatMessage alloc] initFailedWithText:text];
        [self upsertNewMessages:@[failedMessage]];
    };

    // Logic to handle a successful message send
    void(^handleMessageSend)(NSDictionary *) = ^void(NSDictionary *response) {
        [self removeObjects:temporaryMessages];

        NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage objectsWithJSON:response[@"data"]];
        [self upsertNewMessages:temporaryMessages];
    };

    // Logic to actually send a message
    void (^sendMessage)(void) = ^void() {
        [self.userSession.requestManager
         performRequestType:KUSRequestTypePost
         endpoint:@"/c/v1/chat/messages"
         params:@{ @"body": text, @"session": _sessionId }
         authenticated:YES
         completion:^(NSError *error, NSDictionary *response) {
             if (error) {
                 KUSLogError(@"Error sending message: %@", error);
                 handleError();
                 return;
             }

             handleMessageSend(response);
         }];

    };

    if (_sessionId) {
        sendMessage();
    } else {
        [self.userSession.chatSessionsDataSource
         createSessionWithTitle:text
         completion:^(NSError *error, KUSChatSession *session) {
             if (error) {
                 KUSLogError(@"Error creating session: %@", error);
                 handleError();
                 return;
             }

             // Grab the session id
             _sessionId = session.oid;

             // Insert the current messages data source into the userSession's lookup table
             [self.userSession.chatMessagesDataSources setObject:self forKey:session.oid];

             // Notify listeners
             for (id<KUSChatMessagesDataSourceListener> listener in [self.listeners copy]) {
                 if ([listener respondsToSelector:@selector(chatMessagesDataSource:didCreateSessionId:)]) {
                     [listener chatMessagesDataSource:self didCreateSessionId:session.oid];
                 }
             }

             sendMessage();
         }];
    }
}

- (void)resendMessage:(KUSChatMessage *)message
{
    if (message) {
        [self removeObjects:@[ message ]];
        [self sendTextMessage:message.body];
    }
}

@end
