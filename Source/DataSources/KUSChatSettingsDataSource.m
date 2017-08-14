//
//  KUSChatSettingsDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/31/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSettingsDataSource.h"

#import "KUSObjectDataSource_Private.h"

@implementation KUSChatSettingsDataSource

- (void)performRequestWithCompletion:(KUSRequestCompletion)completion
{
    NSURL *URL = [self.apiClient URLForEndpoint:@"/v1/chat/settings"];
    [self.apiClient performRequestType:KUSAPIRequestTypeGet
                                   URL:URL
                                params:nil
                            completion:completion];
}

- (Class)modelClass
{
    return [KUSChatSettings class];
}

@end
