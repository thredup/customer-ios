//
//  KUSChatMessage.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessage.h"

@implementation KUSChatMessage

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"chat_message";
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _trackingId = [json valueForKeyPath:@"attributes.trackingId"];
        _body = [json valueForKeyPath:@"attributes.body"];
    }
    return self;
}

@end
