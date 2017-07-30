//
//  KUSObjectDataSource.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/29/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUSAPIClient;
@class KUSModel;
@protocol KUSObjectDataSourceListener;
@interface KUSObjectDataSource : NSObject

@property (nonatomic, readonly) BOOL isFetching;
@property (nonatomic, readonly) BOOL didFetch;
@property (nonatomic, readonly) NSError *error;

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient;
- (instancetype)init NS_UNAVAILABLE;

// Data methods
- (__kindof KUSModel *)object;

// Listener methods
- (void)addListener:(id<KUSObjectDataSourceListener>)listener;
- (void)removeListener:(id<KUSObjectDataSourceListener>)listener;

// Fetch methods
- (void)fetch;

@end

@protocol KUSObjectDataSourceListener <NSObject>

@optional
- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource;
- (void)objectDataSource:(KUSObjectDataSource *)dataSource didReceiveError:(NSError *)error;

@end
