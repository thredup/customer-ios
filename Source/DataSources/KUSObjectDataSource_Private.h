//
//  KUSObjectDataSource_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/30/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSObjectDataSource.h"

#import "KUSAPIClient.h"
#import "KUSRequestManager.h"

@interface KUSObjectDataSource (Private)

@property (nonatomic, weak, readonly) KUSAPIClient *apiClient;

// Methods to subclass
- (void)performRequestWithCompletion:(KUSRequestCompletion)completion;
- (Class)modelClass;

@end
