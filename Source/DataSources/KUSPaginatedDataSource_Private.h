//
//  KUSPaginatedDataSource_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"

#import "KUSAPIClient.h"

@interface KUSPaginatedDataSource (Private)

@property (nonatomic, weak, readonly) KUSAPIClient *apiClient;

// Methods to subclass
- (NSURL *)firstURL;
- (Class)modelClass;

@end
