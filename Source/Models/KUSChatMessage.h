//
//  KUSChatMessage.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"

typedef NS_ENUM(NSInteger, KUSChatMessageDirection) {
    KUSChatMessageDirectionIn,
    KUSChatMessageDirectionOut
};

@interface KUSChatMessage : KUSModel

@property (nonatomic, copy, readonly) NSString *trackingId;
@property (nonatomic, copy, readonly) NSString *body;

@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, assign, readonly) KUSChatMessageDirection direction;

- (instancetype)initWithAutoreply:(NSString *)autoreply;

@end
