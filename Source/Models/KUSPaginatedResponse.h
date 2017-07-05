//
//  KUSPaginatedResponse.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUSModel;
@interface KUSPaginatedResponse : NSObject

@property (nonatomic, copy, readonly, nonnull) NSArray<__kindof KUSModel *> *objects;

@property (nonatomic, assign, readonly) NSUInteger page;
@property (nonatomic, assign, readonly) NSUInteger pageSize;

@property (nonatomic, strong, readonly, nullable) NSURL *selfURL;
@property (nonatomic, strong, readonly, nullable) NSURL *firstURL;
@property (nonatomic, strong, readonly, nullable) NSURL *prevURL;
@property (nonatomic, strong, readonly, nullable) NSURL *nextURL;

- (instancetype _Nullable)initWithJSON:(NSDictionary * _Nonnull)json modelClass:(Class _Nonnull)modelClass;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

@end
