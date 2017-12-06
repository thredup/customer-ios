//
//  KUSUserDefaults.m
//  Kustomer
//
//  Created by Daniel Amitay on 12/6/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUserDefaults.h"

#import "KUSRequestManager.h"
#import "KUSUserSession.h"

NSString * const kDidCaptureEmailKey = @"kDidCaptureEmail";

@implementation KUSUserDefaults {
    NSUserDefaults *_userDefaults;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        NSString *suiteName = [NSString stringWithFormat:@"%@_kustomer_defaults", userSession.orgName];
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    }
    return self;
}

#pragma mark - Reset method

- (void)reset
{
    NSArray<NSString *> *allUserDefaultsKeys = _userDefaults.dictionaryRepresentation.allKeys;
    for (NSString *userDefaultsKey in allUserDefaultsKeys) {
        [_userDefaults removeObjectForKey:userDefaultsKey];
    }
}

#pragma mark - Public setters and getters

- (void)setDidCaptureEmail:(BOOL)didCaptureEmail
{
    [_userDefaults setBool:didCaptureEmail forKey:kDidCaptureEmailKey];
}

- (BOOL)didCaptureEmail
{
    return [_userDefaults boolForKey:kDidCaptureEmailKey];
}

- (void)setTrackingToken:(NSString *)trackingToken
{
    [_userDefaults setObject:trackingToken forKey:kKustomerTrackingTokenHeaderKey];
}

- (NSString * _Nullable)trackingToken
{
    return [_userDefaults stringForKey:kKustomerTrackingTokenHeaderKey];
}

@end
