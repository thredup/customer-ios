//
//  KUSChatMessagesDataSource.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"

#import "KUSChatMessage.h"
#import "KUSChatSession.h"

@interface KUSChatMessagesDataSource : KUSPaginatedDataSource

- (instancetype)initWithUserSession:(KUSUserSession *)userSession chatSession:(KUSChatSession *)session;
- (instancetype)initWithUserSession:(KUSUserSession *)userSession NS_UNAVAILABLE;

- (NSString *)firstOtherUserId;

@end
