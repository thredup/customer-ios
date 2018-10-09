//
//  KUSMLNode.m
//  Kustomer
//
//  Created by BrainX Technologies on 01/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSMLNode.h"

@implementation KUSMLNode

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
        _nodeDisplayName = NSStringFromKeyPath(json, @"displayName");
        _nodeId = NSStringFromKeyPath(json, @"id");
        _nodeChilds = [KUSMLNode objectsWithJSONs:NSArrayFromKeyPath(json, @"children")];
    }
    return self;
}

@end
