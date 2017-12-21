//
//  KUSFormDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 12/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSFormDataSource.h"
#import "KUSObjectDataSource_Private.h"

@interface KUSFormDataSource () {
    NSString *_formId;
}

@end

@implementation KUSFormDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession formId:(NSString *)formId
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _formId = [formId copy];
    }
    return self;
}

#pragma mark - KUSObjectDataSource subclass methods

- (void)performRequestWithCompletion:(KUSRequestCompletion)completion
{
    [self.userSession.requestManager getEndpoint:[NSString stringWithFormat:@"/c/v1/chat/forms/%@", _formId]
                                   authenticated:YES
                                      completion:completion];
}

- (Class)modelClass
{
    return [KUSForm class];
}

@end
