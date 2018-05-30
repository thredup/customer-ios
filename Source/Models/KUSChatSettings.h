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
@property (nonatomic, copy, readonly) NSString *activeFormId;
@property (nonatomic, copy, readonly) NSString *pusherAccessKey;
@property (nonatomic, assign, readonly) BOOL enabled;

@property (nonatomic, copy, readonly) NSString *waitMessage;
@property (nonatomic, copy, readonly) NSString *customWaitMessage;
@property (nonatomic, assign, readonly) NSInteger timeOut;
@property (nonatomic, assign, readonly) NSInteger promptDelay;
@property (nonatomic, assign, readonly) BOOL hideWaitOption;
@property (nonatomic, copy, readonly) NSArray<NSString *> *followUpChannels;
@property (nonatomic, assign, readonly) BOOL useDynamicWaitMessage;
@property (nonatomic, assign, readonly) BOOL markDoneAfterTimeout;
@property (nonatomic, assign, readonly) BOOL volumeControlEnabled;


@end
