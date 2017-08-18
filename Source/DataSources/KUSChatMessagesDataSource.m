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
    KUSChatSession *_chatSession;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession chatSession:(KUSChatSession *)session;
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _chatSession = session;
    }
    return self;
}

#pragma mark - KUSPaginatedDataSource methods

- (NSURL *)firstURL
{
    NSString *sessionId = _chatSession.oid;
    if (sessionId) {
        NSString *endpoint = [NSString stringWithFormat:@"/c/v1/chat/sessions/%@/messages", sessionId];
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

@end
