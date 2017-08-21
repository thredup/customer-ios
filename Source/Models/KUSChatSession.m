//
//  KUSChatSession.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSession.h"

@implementation KUSChatSession

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"chat_session";
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _preview = NSStringFromKeyPath(json, @"attributes.preview");
        _trackingId = NSStringFromKeyPath(json, @"attributes.trackingId");

        _createdAt = DateFromKeyPath(json, @"attributes.createdAt");
        _lastSeenAt = DateFromKeyPath(json, @"attributes.lastSeenAt");
    }
    return self;
}

#pragma mark - NSObject methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: oid: %@; preview: %@>",
            NSStringFromClass([self class]), self, self.oid, self.preview];
}

@end
