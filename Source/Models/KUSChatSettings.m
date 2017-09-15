//
//  KUSChatSettings.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSettings.h"

#import "KUSChatMessage.h"

@implementation KUSChatSettings {
    KUSChatMessage *_autoreplyMessage;
}

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"chat_settings";
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _teamName = NSStringFromKeyPath(json, @"attributes.teamName");
        _teamIconURL = NSURLFromKeyPath(json, @"attributes.teamIconUrl");
        _greeting = NSStringFromKeyPath(json, @"attributes.greeting");
        _autoreply = NSStringFromKeyPath(json, @"attributes.autoreply");
        _enabled = BOOLFromKeyPath(json, @"attributes.enabled");
        _pusherAccessKey = NSStringFromKeyPath(json, @"attributes.pusherAccessKey");
    }
    return self;
}

#pragma mark - Convenience methods

- (KUSChatMessage *)autoreplyMessage
{
    if (_autoreplyMessage == nil) {
        _autoreplyMessage = [[KUSChatMessage alloc] initWithAutoreply:self.autoreply];
    }
    return _autoreplyMessage;
}

@end
