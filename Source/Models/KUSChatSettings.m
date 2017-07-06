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
        _teamName = [json valueForKeyPath:@"attributes.teamName"];
        _teamIconURL = [NSURL URLWithString:[json valueForKeyPath:@"attributes.teamIconUrl"]];
        _greeting = [json valueForKeyPath:@"attributes.greeting"];
        _autoreply = [json valueForKeyPath:@"attributes.autoreply"];
        _enabled = [[json valueForKeyPath:@"attributes.enabled"] boolValue];
    }
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)json orgName:(NSString *)orgName
{
    self = [self initWithJSON:json];
    if (self) {
        // To match getCurrentCompanySettings() in src/api/api.js::L202
        if (self.teamName.length == 0 && orgName.length > 0) {
            _teamName = [[[orgName substringToIndex:1] uppercaseString] stringByAppendingString:[orgName substringFromIndex:1]];
        }
    }
    return self;
}

@end
