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

@end
