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

@interface KUSChatSessionsDataSource () <KUSPaginatedDataSourceListener> {
    NSDictionary<NSString *, NSObject *> *_pendingCustomChatSessionAttributes;
}

@end

@implementation KUSChatSessionsDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
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
        [NSSortDescriptor sortDescriptorWithKey:@"lastMessageAt" ascending:NO],
        [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO],
        [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:NO]
    ];
}

#pragma mark - Public methods

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

    NSString *lastSeenAtString = [KUSDate stringFromDate:[NSDate date]];
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
             if ([type isEqualToString:@"chat_session"]) {
                 chatSession = [[KUSChatSession alloc] initWithJSON:includedModelJSON];
             } else if ([type isEqualToString:@"chat_message"]) {
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
    KUSChatSession *mostRecentChatSession = [self _mostRecentChatSession];
    NSString *mostRecentChatSessionId = mostRecentChatSession.oid;
    if (mostRecentChatSessionId) {
        [self _flushCustomAttributes:customAttributes toChatSessionId:mostRecentChatSessionId];
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

- (KUSChatSession * _Nullable)_mostRecentChatSession
{
    NSDate *mostRecentMessageAt = nil;
    KUSChatSession *mostRecentChatSession = nil;
    for (KUSChatSession *chatSession in self.allObjects) {
        if (mostRecentMessageAt == nil) {
            mostRecentMessageAt = chatSession.lastMessageAt;
            mostRecentChatSession = chatSession;
        } else if ([mostRecentMessageAt earlierDate:chatSession.lastMessageAt] == mostRecentMessageAt) {
            mostRecentMessageAt = chatSession.lastMessageAt;
            mostRecentChatSession = chatSession;
        }
    }
    return mostRecentChatSession;
}

- (NSDate * _Nullable)lastMessageAt
{
    return [self _mostRecentChatSession].lastMessageAt;
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (_pendingCustomChatSessionAttributes) {
        KUSChatSession *mostRecentChatSession = [self _mostRecentChatSession];
        NSString *mostRecentChatSessionId = mostRecentChatSession.oid;
        if (mostRecentChatSessionId) {
            [self _flushCustomAttributes:_pendingCustomChatSessionAttributes toChatSessionId:mostRecentChatSessionId];
            _pendingCustomChatSessionAttributes = nil;
        }
    }
}

@end
