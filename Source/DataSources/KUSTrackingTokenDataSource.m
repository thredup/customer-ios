//
//  KUSTrackingTokenDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSTrackingTokenDataSource.h"

#import "KUSObjectDataSource_Private.h"

@interface KUSTrackingTokenDataSource () <KUSObjectDataSourceListener>

@end

@implementation KUSTrackingTokenDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        [self addListener:self];
    }
    return self;
}

#pragma mark - KUSObjectDataSource subclass methods

- (void)performRequestWithCompletion:(KUSRequestCompletion)completion
{
    NSURL *URL = [self.userSession.requestManager URLForEndpoint:@"/c/v1/tracking/tokens/current"];
    [self.userSession.requestManager performRequestType:KUSRequestTypeGet
                                                    URL:URL
                                                 params:nil
                                          authenticated:NO
                                      additionalHeaders:[self _additionalHeaders]
                                             completion:completion];
}

- (Class)modelClass
{
    return [KUSTrackingToken class];
}

#pragma mark - Public methods

- (nullable NSString *)currentTrackingToken
{
    KUSTrackingToken *trackingTokenObj = self.object;
    return trackingTokenObj.token;
}

#pragma mark - Internal methods

- (nullable NSDictionary *)_additionalHeaders
{
    NSString *currentTrackingToken = self.currentTrackingToken;
    if (currentTrackingToken) {
        return @{
            kKustomerTrackingTokenHeaderKey: currentTrackingToken
        };
    }
    NSString *cachedTrackingToken = [[NSUserDefaults standardUserDefaults] stringForKey:kKustomerTrackingTokenHeaderKey];
    if (cachedTrackingToken) {
        return @{
            kKustomerTrackingTokenHeaderKey: cachedTrackingToken
        };
    }
    return nil;
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    NSString *currentTrackingToken = self.currentTrackingToken;
    [[NSUserDefaults standardUserDefaults] setObject:currentTrackingToken forKey:kKustomerTrackingTokenHeaderKey];
}

@end
