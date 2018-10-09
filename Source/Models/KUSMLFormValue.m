//
//  KUSMLFormValue.m
//  Kustomer
//
//  Created by BrainX Technologies on 01/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSMLFormValue.h"

@implementation KUSMLFormValue

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
        _propertyDisplayName = NSStringFromKeyPath(json, @"displayName");
        _lastNodeRequired = BOOLFromKeyPath(json, @"lastNodeRequired");
        _tree = [KUSMLNode objectsWithJSONs:NSArrayFromKeyPath(json, @"tree.children")];
    }
    return self;
}

@end
