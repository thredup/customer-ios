//
//  KUSChatSettings.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"

@class KUSChatMessage;
@interface KUSChatSettings : KUSModel

@property (nonatomic, copy, readonly) NSString *teamName;
@property (nonatomic, copy, readonly) NSURL *teamIconURL;
@property (nonatomic, copy, readonly) NSString *greeting;
@property (nonatomic, copy, readonly) NSString *autoreply;
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, copy, readonly) NSString *pusherAccessKey;

- (instancetype)initWithJSON:(NSDictionary *)json;

- (KUSChatMessage *)autoreplyMessage;

@end
