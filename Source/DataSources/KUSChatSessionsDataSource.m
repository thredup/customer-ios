//
//  KUSChatSessionsDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSessionsDataSource.h"

#import "KUSPaginatedDataSource_Private.h"

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

@end
