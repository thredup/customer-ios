//
//  KUSObjectDataSource_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/30/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSObjectDataSource.h"

#import "KUSAPIClient.h"

@interface KUSObjectDataSource (Private)

@property (nonatomic, strong, readonly) KUSAPIClient *apiClient;

// Methods to subclass
- (NSURL *)URL;
- (Class)modelClass;

@end
