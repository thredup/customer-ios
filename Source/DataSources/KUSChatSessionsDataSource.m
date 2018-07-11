//
//  KUSChatSessionsDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSessionsDataSource.h"

#import "KUSPaginatedDataSource_Private.h"

#import "KUSDate.h"
#import "KUSLog.h"

@interface KUSChatSession (SortDate)

- (NSDate *)sortDate;

@end

@interface KUSChatSessionsDataSource () <KUSChatMessagesDataSourceListener> {
    NSDictionary<NSString *, NSObject *> *_pendingCustomChatSessionAttributes;

    NSMutableDictionary<NSString *, NSDate *> *_localLastSeenAtBySessionId;
}

@end

@implementation KUSChatSessionsDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _localLastSeenAtBySessionId = [[NSMutableDictionary alloc] init];

        [self addListener:self];
    }
    return self;
}

#pragma mark - KUSPaginatedDataSource methods

- (NSURL *)firstURL
{
    return [self.userSession.requestManager URLForEndpoint:@"/c/v1/chat/sessions"];
}

- (Class)modelClass
{
    return [KUSChatSession class];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors
{
    return @[
        [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO],
        [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:NO]
    ];
}

#pragma mark - Public methods

- (void)upsertNewSessions:(NSArray<KUSChatSession *> *)chatSessions
{
    if (chatSessions.count == 1) {
        [self upsertObjects:chatSessions];
    } else if (chatSessions.count > 1) {
        NSMutableArray<KUSChatSession *> *reversedSessions = [[NSMutableArray alloc] initWithCapacity:chatSessions.count];
        for (KUSChatSession *chatSession in chatSessions.reverseObjectEnumerator) {
            [reversedSessions addObject:chatSession];
        }
        [self upsertObjects:reversedSessions];
    }
}

- (void)createSessionWithTitle:(NSString *)title completion:(void(^)(NSError *error, KUSChatSession *session))completion
{
    __weak KUSChatSessionsDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/chat/sessions"
     params:@{ @"title": title }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (error) {
             if (completion) {
                 completion(error, nil);
             }
             return;
         }

         KUSChatSession *session = [[KUSChatSession alloc] initWithJSON:response[@"data"]];
         if (session) {
             [weakSelf upsertObjects:@[ session ]];
         }
         if (completion) {
             completion(nil, session);
         }
     }];
}

- (void)updateLastSeenAtForSessionId:(NSString *)sessionId completion:(void(^)(NSError *error, KUSChatSession *session))completion
{
    if (sessionId.length == 0) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([NSError new], nil);
            });
        }
        return;
    }

    NSDate *lastSeenAtDate = [NSDate date];
    [_localLastSeenAtBySessionId setObject:lastSeenAtDate forKey:sessionId];
    NSString *lastSeenAtString = [KUSDate stringFromDate:lastSeenAtDate];

    __weak KUSChatSessionsDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePut
     endpoint:[NSString stringWithFormat:@"/c/v1/chat/sessions/%@", sessionId]
     params:@{ @"lastSeenAt": lastSeenAtString }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (error) {
             if (completion) {
                 completion(error, nil);
             }
             return;
         }

         KUSChatSession *session = [[KUSChatSession alloc] initWithJSON:response[@"data"]];
         if (session) {
             [weakSelf upsertObjects:@[ session ]];
         }
         if (completion) {
             completion(nil, session);
         }
     }];
}

- (void)submitFormMessages:(NSArray<NSDictionary *> *)messages
                    formId:(NSString *)formId
                completion:(void (^)(NSError *, KUSChatSession *, NSArray<KUSChatMessage *> *))completion
{
    __weak KUSChatSessionsDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:[NSString stringWithFormat:@"/c/v1/chat/forms/%@/responses", formId]
     params:@{ @"messages": messages }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (error) {
             if (completion) {
                 completion(error, nil, nil);
             }
             return;
         }

         KUSChatSession *chatSession = nil;
         NSMutableArray<KUSChatMessage *> *chatMessages = [[NSMutableArray alloc] init];

         NSArray<NSDictionary *> *includedModelsJSON = response[@"included"];
         for (NSDictionary *includedModelJSON in includedModelsJSON) {
             NSString *type = includedModelJSON[@"type"];
             if ([type isEqual:[KUSChatSession modelType]]) {
                 chatSession = [[KUSChatSession alloc] initWithJSON:includedModelJSON];
             } else if ([type isEqual:[KUSChatMessage modelType]]) {
                 KUSChatMessage *chatMessage = [[KUSChatMessage alloc] initWithJSON:includedModelJSON];
                 [chatMessages addObject:chatMessage];
             }
         }

         if (chatSession) {
             [weakSelf upsertObjects:@[ chatSession ]];
         }
         if (completion) {
             completion(nil, chatSession, chatMessages);
         }
     }];
}

- (void)describeActiveConversation:(NSDictionary<NSString *, NSObject *> *)customAttributes
{
    KUSChatSession *mostRecentSession = [self mostRecentSession];
    NSString *mostRecentSessionId = mostRecentSession.oid;
    if (mostRecentSessionId) {
        [self _flushCustomAttributes:customAttributes toChatSessionId:mostRecentSessionId];
    } else {
        // Merge previously queued custom attributes with the latest custom attributes
        NSMutableDictionary<NSString *, NSObject *> *pendingCustomChatSessionAttributes = [[NSMutableDictionary alloc] init];
        if (_pendingCustomChatSessionAttributes) {
            [pendingCustomChatSessionAttributes addEntriesFromDictionary:_pendingCustomChatSessionAttributes];
        }
        [pendingCustomChatSessionAttributes addEntriesFromDictionary:customAttributes];
        _pendingCustomChatSessionAttributes = pendingCustomChatSessionAttributes;

        [self fetchLatest];
    }
}

#pragma mark - Internal methods

- (void)_flushCustomAttributes:(NSDictionary<NSString *, NSObject *> *)customAttributes toChatSessionId:(NSString *)chatSessionId
{
    NSDictionary<NSString *, NSObject *> *formData = @{ @"custom" : customAttributes };
    NSString *endpoint = [NSString stringWithFormat:@"/c/v1/conversations/%@", chatSessionId];
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePatch
     endpoint:endpoint
     params:formData
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (error) {
             KUSLogError(@"Error updating chat attributes: %@", error);
         }
     }];
}


#pragma mark - Helper methods

- (KUSChatSession * _Nullable)mostRecentSession
{
    NSDate *mostRecentMessageAt = nil;
    KUSChatSession *mostRecentSession = nil;
    for (KUSChatSession *chatSession in self.allObjects) {
        if (mostRecentMessageAt == nil) {
            mostRecentMessageAt = chatSession.lastMessageAt;
            mostRecentSession = chatSession;
        } else if ([mostRecentMessageAt laterDate:chatSession.lastMessageAt] == chatSession.lastMessageAt) {
            mostRecentMessageAt = chatSession.lastMessageAt;
            mostRecentSession = chatSession;
        }
    }
    return mostRecentSession ?: self.firstObject;
}

- (NSDate * _Nullable)lastMessageAt
{
    return [self mostRecentSession].lastMessageAt;
}

- (NSDate * _Nullable)lastSeenAtForSessionId:(NSString *)sessionId
{
    KUSChatSession *chatSession = [self objectWithId:sessionId];
    NSDate *chatSessionDate = chatSession.lastSeenAt;
    NSDate *localDate = [_localLastSeenAtBySessionId objectForKey:sessionId];
    return [chatSessionDate ?: localDate laterDate:localDate];
}

- (NSUInteger)totalUnreadCountExcludingSessionId:(NSString *)excludedSessionId
{
    NSUInteger count = 0;
    for (KUSChatSession *session in self.allObjects) {
        NSString *sessionId = session.oid;
        if (excludedSessionId && [excludedSessionId isEqualToString:sessionId]) {
            continue;
        }
        KUSChatMessagesDataSource *messagesDataSource = [self.userSession chatMessagesDataSourceForSessionId:sessionId];
        NSDate *sessionLastSeenAt = [self lastSeenAtForSessionId:sessionId];
        NSUInteger unreadCountForSession = [messagesDataSource unreadCountAfterDate:sessionLastSeenAt];
        count += unreadCountForSession;
    }
    return count;
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (dataSource == self) {
        if (_pendingCustomChatSessionAttributes) {
            KUSChatSession *mostRecentSession = [self mostRecentSession];
            NSString *mostRecentSessionId = mostRecentSession.oid;
            if (mostRecentSessionId) {
                [self _flushCustomAttributes:_pendingCustomChatSessionAttributes toChatSessionId:mostRecentSessionId];
                _pendingCustomChatSessionAttributes = nil;
            }
        }

        NSArray<NSString *> *sessionIds = [self.allObjects valueForKeyPath:@"@unionOfObjects.oid"];
        for (NSString *sessionId in sessionIds) {
            KUSChatMessagesDataSource *messagesDataSource = [self.userSession chatMessagesDataSourceForSessionId:sessionId];
            [messagesDataSource addListener:self];
        }
    } else if ([dataSource isKindOfClass:[KUSChatMessagesDataSource class]]) {
        [self sortObjects];
        [self notifyAnnouncersDidChangeContent];
    }
}

@end

@implementation KUSChatSession (SortDate)

- (NSDate *)sortDate
{
    KUSUserSession *userSession = [Kustomer sharedInstance].userSession;
    KUSChatMessagesDataSource *messagesDataSource = [userSession chatMessagesDataSourceForSessionId:self.oid];
    KUSChatMessage *chatMessage = (messagesDataSource.count ? [messagesDataSource objectAtIndex:0] : nil);
    NSDate *laterLastMessageAt = [chatMessage.createdAt ?: self.lastMessageAt laterDate:self.lastMessageAt];
    return laterLastMessageAt ?: self.createdAt;
}

@end
