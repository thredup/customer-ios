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

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient chatSession:(KUSChatSession *)session
{
    self = [super initWithAPIClient:apiClient];
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
        NSString *endpoint = [NSString stringWithFormat:@"/v1/chat/sessions/%@/messages", sessionId];
        return [self.apiClient URLForEndpoint:endpoint];
    }
    return nil;
}

- (Class)modelClass
{
    return [KUSChatMessage class];
}

@end
