//
//  Kustomer.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "Kustomer.h"

@interface Kustomer ()

@property (nonatomic, copy) NSString *accessToken;

@end

@implementation Kustomer

#pragma mark - Class methods

+ (void)initializeWithAccessToken:(NSString *)accessToken
{
    [[self sharedInstance] setAccessToken:accessToken];
}

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static Kustomer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

@end
