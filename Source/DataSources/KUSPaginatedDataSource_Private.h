//
//  KUSPaginatedDataSource_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"

#import "KUSUserSession.h"

@interface KUSPaginatedDataSource (Private)

@property (nonatomic, weak, readonly) KUSUserSession *userSession;
@property (nonatomic, strong, readonly) NSHashTable<id<KUSPaginatedDataSourceListener>> *listeners;

// Methods to subclass
- (NSURL *)firstURL;
- (Class)modelClass;

- (void)prependObjects:(NSArray<KUSModel *> *)objects;
- (void)updateObjects:(NSArray<KUSModel *> *)objects;
- (void)removeObjects:(NSArray<KUSModel *> *)objects;

@end
