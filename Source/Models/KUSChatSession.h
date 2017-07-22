//
//  KUSChatSession.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"

@interface KUSChatSession : KUSModel

@property (nonatomic, copy, readonly) NSString *preview;
@property (nonatomic, copy, readonly) NSString *trackingId;

@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, copy, readonly) NSDate *lastSeenAt;

@end
