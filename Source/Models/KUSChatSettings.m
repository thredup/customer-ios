//
//  KUSChatSettings.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSettings.h"

@implementation KUSChatSettings

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
    }
    return self;
}

@end
