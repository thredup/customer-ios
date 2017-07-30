//
//  KUSObjectDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/29/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSObjectDataSource.h"

#import "KUSAPIClient.h"

@interface KUSObjectDataSource () {
    NSHashTable<id<KUSObjectDataSourceListener>> *_listeners;
}

@property (nonatomic, readwrite) BOOL isFetching;
@property (nonatomic, readwrite) BOOL didFetch;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) __kindof KUSModel *object;

@property (nonatomic, strong, readwrite) KUSAPIClient *apiClient;

@end

@implementation KUSObjectDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient
{
    self = [super init];
    if (self) {
        _apiClient = apiClient;

        _listeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

#pragma mark - Public methods

- (__kindof KUSModel *)object
{
    return nil;
}

- (void)fetch
{
    NSURL *URL = nil;
    if (URL == nil) {
        return;
    }
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    self.error = nil;

    __weak KUSObjectDataSource *weakSelf = self;
    [self.apiClient
     performRequestType:KUSAPIRequestTypeGet
     URL:URL
     params:nil
     completion:^(NSError *error, NSDictionary *response) {
         __strong KUSObjectDataSource *strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         KUSModel *model = [[KUSModel alloc] initWithJSON:response];
         if (error || model == nil) {
             weakSelf.error = error;
             [self notifyAnnouncersDidError:error];
         } else {
             weakSelf.object = model;
             [self notifyAnnouncersDidLoad];
         }
     }];
}

#pragma mark - Subclass methods

- (NSURL *)URL
{
    return nil;
}

- (Class)modelClass
{
    return [KUSModel class];
}

#pragma mark - Listener methods

- (void)addListener:(id<KUSObjectDataSourceListener>)listener
{
    [_listeners addObject:listener];
}

- (void)removeListener:(id<KUSObjectDataSourceListener>)listener
{
    [_listeners removeObject:listener];
}

#pragma mark - Internal listener methods

- (void)notifyAnnouncersDidError:(NSError *)error
{
    for (id<KUSObjectDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(objectDataSource:didReceiveError:)]) {
            [listener objectDataSource:self didReceiveError:error];
        }
    }
}

- (void)notifyAnnouncersDidLoad
{
    for (id<KUSObjectDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(objectDataSourceDidLoad:)]) {
            [listener objectDataSourceDidLoad:self];
        }
    }
}

@end
