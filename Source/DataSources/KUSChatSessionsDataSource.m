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

@implementation KUSChatSessionsDataSource

#pragma mark - KUSPaginatedDataSource methods

- (NSURL *)firstURL
{
    return [self.userSession.requestManager URLForEndpoint:@"/c/v1/chat/sessions"];
}

- (Class)modelClass
{
    return [KUSChatSession class];
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
             [weakSelf prependObjects:@[ session ]];
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
             [weakSelf updateObjects:@[ session ]];
         }
         if (completion) {
             completion(nil, session);
         }
     }];
}

- (void)describeActiveConversation:(NSDictionary<NSString *, NSObject *> *)customAttributes completion:(void(^)(BOOL, NSError *))completion
{
    KUSChatSession *mostRecentChatSession = [self _mostRecentChatSession];
    if (mostRecentChatSession) {
        NSDictionary<NSString *, NSObject *> *formData = @{ @"custom" : customAttributes };
        NSString *endpoint = [NSString stringWithFormat:@"/c/v1/conversations/%@", mostRecentChatSession.sessionId];
        [self.userSession.requestManager
         performRequestType:KUSRequestTypePatch
         endpoint:endpoint
         params:formData
         authenticated:YES
         completion:^(NSError *error, NSDictionary *response) {
             if (completion) {
                 completion(error == nil, error);
             }
         }];
    } else {
        // TODO: Queue up conversation describe commands
    }
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

@end
