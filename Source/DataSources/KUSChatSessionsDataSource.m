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
    return [self.apiClient URLForEndpoint:@"/v1/chat/sessions"];
}

- (Class)modelClass
{
    return [KUSChatSession class];
}

@end
