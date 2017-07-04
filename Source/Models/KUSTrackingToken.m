//
//  KUSTrackingToken.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSTrackingToken.h"

@implementation KUSTrackingToken

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"tracking_token";
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _trackingId = [json valueForKeyPath:@"attributes.trackingId"];
        _token = [json valueForKeyPath:@"attributes.token"];
        _verified = [[json valueForKeyPath:@"attributes.verified"] boolValue];
    }
    return self;
}

@end
