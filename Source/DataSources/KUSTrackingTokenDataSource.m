//
//  KUSTrackingTokenDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSTrackingTokenDataSource.h"

#import "KUSObjectDataSource_Private.h"

@implementation KUSTrackingTokenDataSource

- (void)performRequestWithCompletion:(KUSRequestCompletion)completion
{
    NSURL *URL = [self.apiClient URLForEndpoint:@"/v1/tracking/tokens/current"];
    [self.apiClient performRequestType:KUSAPIRequestTypeGet
                                   URL:URL
                                params:nil
                            completion:completion];
}

- (Class)modelClass
{
    return [KUSTrackingToken class];
}

@end
