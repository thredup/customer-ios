//
//  KUSTeam.m
//  Kustomer
//
//  Created by Daniel Amitay on 12/19/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSTeam.h"

@implementation KUSTeam

#pragma mark - Class methods

+ (NSString * _Nullable)modelType
{
    return nil;
}

+ (BOOL)enforcesModelType
{
    return NO;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _displayName = NSStringFromKeyPath(json, @"attributes.displayName");
        _icon = NSStringFromKeyPath(json, @"attributes.icon");
    }
    return self;
}

@end
