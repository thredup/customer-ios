//
//  KUSChatSettings.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSettings.h"

#import "KUSChatMessage.h"

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
        _autoreply = NSStringSanitizedAutoreply(NSStringFromKeyPath(json, @"attributes.autoreply"));
        _activeFormId = NSStringFromKeyPath(json, @"attributes.activeForm");
        _pusherAccessKey = NSStringFromKeyPath(json, @"attributes.pusherAccessKey");
        _enabled = BOOLFromKeyPath(json, @"attributes.enabled");
    }
    return self;
}

#pragma mark - Convenience methods

NSString *_Nullable NSStringSanitizedAutoreply(NSString * _Nullable autoreply)
{
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedAutoreply = [autoreply stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if (trimmedAutoreply.length > 0) {
        return trimmedAutoreply;
    }
    return nil;
}

@end
