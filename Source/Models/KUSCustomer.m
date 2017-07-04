//
//  KUSCustomer.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSCustomer.h"

@implementation KUSCustomer

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"customer";
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        // TODO: Customer attributes?
    }
    return self;
}

@end
