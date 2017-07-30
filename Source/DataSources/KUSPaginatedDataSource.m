//
//  KUSPaginatedDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedDataSource.h"
#import "KUSPaginatedDataSource_Private.h"

#import "KUSPaginatedResponse.h"

@interface KUSPaginatedDataSource () {
    NSHashTable<id<KUSPaginatedDataSourceListener>> *_listeners;

    NSMutableArray<KUSModel *> *_fetchedModels;
    NSMutableDictionary<NSString *, KUSModel *> *_fetchedModelsById;

    KUSPaginatedResponse *_mostRecentPaginatedResponse;
    KUSPaginatedResponse *_lastPaginatedResponse;
}

@property (nonatomic, strong, readwrite) KUSAPIClient *apiClient;

@property (nonatomic, readwrite) BOOL isFetching;
@property (nonatomic, readwrite) BOOL didFetch;
@property (nonatomic, readwrite) BOOL didFetchAll;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation KUSPaginatedDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient
{
    self = [super init];
    if (self) {
        _apiClient = apiClient;

        _listeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];

        _fetchedModels = [[NSMutableArray alloc] init];
        _fetchedModelsById = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public methods

- (NSUInteger)count
{
    return [_fetchedModels count];
}

- (NSArray<__kindof KUSModel *> *)allObjects
{
    return [_fetchedModels copy];
}

- (__kindof KUSModel *)objectWithId:(NSString *)oid
{
    return [_fetchedModelsById objectForKey:oid];
}

- (__kindof KUSModel *)objectAtIndex:(NSUInteger)index
{
    return [_fetchedModels objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(__kindof KUSModel *)object
{
    return [self _indexOfObjectId:object.oid];
}

- (__kindof KUSModel *)firstObject
{
    return [_fetchedModels firstObject];
}

- (NSUInteger)_indexOfObjectId:(NSString *)objectId
{
    if (objectId == nil) {
        return NSNotFound;
    }
    KUSModel *internalObject = [self objectWithId:objectId];
    if (internalObject == nil) {
        return NSNotFound;
    }
    return [_fetchedModels indexOfObjectIdenticalTo:internalObject];
}

#pragma mark - Listener methods

- (void)addListener:(id<KUSPaginatedDataSourceListener>)listener
{
    [_listeners addObject:listener];
}

- (void)removeListener:(id<KUSPaginatedDataSourceListener>)listener
{
    [_listeners removeObject:listener];
}

#pragma mark - Fetch methods

- (void)fetchLatest
{
    NSURL *URL = [self firstURL];
    if (_mostRecentPaginatedResponse.firstPath) {
        URL = [self.apiClient URLForPath:_mostRecentPaginatedResponse.firstPath];
    }
    if (URL == nil) {
        return;
    }
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    self.error = nil;

    __weak KUSPaginatedDataSource *weakSelf = self;
    [self.apiClient
     performRequestType:KUSAPIRequestTypeGet
     URL:URL
     params:nil
     completion:^(NSError *error, NSDictionary *json) {
         __strong KUSPaginatedDataSource *strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         KUSPaginatedResponse *response = [[KUSPaginatedResponse alloc] initWithJSON:json modelClass:[strongSelf modelClass]];
         [strongSelf _prependResponse:response error:error];
     }];
}

- (void)fetchNext
{
    NSURL *URL;
    if (_lastPaginatedResponse.nextPath) {
        URL = [self.apiClient URLForPath:_lastPaginatedResponse.nextPath];
    }
    if (URL == nil) {
        return;
    }
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    self.error = nil;

    __weak KUSPaginatedDataSource *weakSelf = self;
    [self.apiClient
     performRequestType:KUSAPIRequestTypeGet
     URL:URL
     params:nil
     completion:^(NSError *error, NSDictionary *json) {
         __strong KUSPaginatedDataSource *strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         KUSPaginatedResponse *response = [[KUSPaginatedResponse alloc] initWithJSON:json modelClass:[strongSelf modelClass]];
         [strongSelf _appendResponse:response error:error];
     }];
}

#pragma mark - Subclass methods

- (NSURL *)firstURL
{
    return nil;
}

- (Class)modelClass
{
    return [KUSModel class];
}

#pragma mark - Internal methods

- (void)_appendResponse:(KUSPaginatedResponse *)response error:(NSError *)error
{
    if (error || response == nil) {
        self.isFetching = NO;
        self.error = error;
        [self notifyAnnouncersDidError:error];
        return;
    }

    _lastPaginatedResponse = response;
    _mostRecentPaginatedResponse = response;

    NSMutableDictionary<NSString *, NSNumber *> *objectIdToPrevious = [[NSMutableDictionary alloc] init];

    for (KUSModel *object in response.objects) {
        NSUInteger indexOfObject = [self indexOfObject:object];
        if (indexOfObject == NSNotFound) {
            // New object
            [_fetchedModels addObject:object];
        } else {
            // Updated/moved object
            [_fetchedModels removeObjectAtIndex:indexOfObject];
            [_fetchedModels addObject:object];
        }
        [_fetchedModelsById setObject:object forKey:object.oid];
        [objectIdToPrevious setObject:@(indexOfObject) forKey:object.oid];
    }
    BOOL didNotifyWillChange = NO;
    for (NSString *objectId in objectIdToPrevious) {
        NSUInteger previousIndex = [objectIdToPrevious[objectId] unsignedIntegerValue];
        NSUInteger indexOfObject = [self _indexOfObjectId:objectId];
        if (previousIndex != indexOfObject) {
            if (!didNotifyWillChange) {
                [self notifyAnnouncersWillChangeContent];
                didNotifyWillChange = YES;
            }

            KUSModel *object = [self objectWithId:objectId];
            [self notifyAnnouncersForObject:object previousIndex:previousIndex newIndex:indexOfObject];
        }
    }

    self.isFetching = NO;
    self.didFetch = YES;
    self.didFetchAll = response.nextPath == nil;

    if (didNotifyWillChange) {
        [self notifyAnnouncersDidChangeContent];
    }
    [self notifyAnnouncersDidLoad];
}

- (void)_prependResponse:(KUSPaginatedResponse *)response error:(NSError *)error
{
    if (error || response == nil) {
        self.isFetching = NO;
        self.error = error;
        [self notifyAnnouncersDidError:error];
        return;
    }

    _mostRecentPaginatedResponse = response;

    NSMutableDictionary<NSString *, NSNumber *> *objectIdToPrevious = [[NSMutableDictionary alloc] init];

    for (KUSModel *object in response.objects) {
        NSUInteger indexOfObject = [self indexOfObject:object];
        if (indexOfObject == NSNotFound) {
            // New object
            [_fetchedModels insertObject:object atIndex:0];
        } else {
            // Updated/moved object
            [_fetchedModels removeObjectAtIndex:indexOfObject];
            [_fetchedModels insertObject:object atIndex:0];
        }
        [_fetchedModelsById setObject:object forKey:object.oid];
        [objectIdToPrevious setObject:@(indexOfObject) forKey:object.oid];
    }
    BOOL didNotifyWillChange = NO;
    for (NSString *objectId in objectIdToPrevious) {
        NSUInteger previousIndex = [objectIdToPrevious[objectId] unsignedIntegerValue];
        NSUInteger indexOfObject = [self _indexOfObjectId:objectId];
        if (previousIndex != indexOfObject) {
            if (!didNotifyWillChange) {
                [self notifyAnnouncersWillChangeContent];
                didNotifyWillChange = YES;
            }

            KUSModel *object = [self objectWithId:objectId];
            [self notifyAnnouncersForObject:object previousIndex:previousIndex newIndex:indexOfObject];
        }
    }

    self.isFetching = NO;
    self.didFetch = YES;

    if (didNotifyWillChange) {
        [self notifyAnnouncersDidChangeContent];
    }
    [self notifyAnnouncersDidLoad];
}

#pragma mark - Internal listener methods

- (void)notifyAnnouncersWillChangeContent
{
    for (id<KUSPaginatedDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(paginatedDataSourceWillChangeContent:)]) {
            [listener paginatedDataSourceWillChangeContent:self];
        }
    }
}

- (void)notifyAnnouncersDidChangeContent
{
    for (id<KUSPaginatedDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(paginatedDataSourceDidChangeContent:)]) {
            [listener paginatedDataSourceDidChangeContent:self];
        }
    }
}

- (void)notifyAnnouncersForObject:(__kindof KUSModel *)object previousIndex:(NSUInteger)prevIndex newIndex:(NSUInteger)newIndex
{
    KUSPaginatedDataSourceChangeType changeType = KUSPaginatedDataSourceChangeUpdate;
    if (prevIndex == NSNotFound) {
        changeType = KUSPaginatedDataSourceChangeInsert;
    } else if (newIndex == NSNotFound) {
        changeType = KUSPaginatedDataSourceChangeDelete;
    } else if (prevIndex != newIndex) {
        changeType = KUSPaginatedDataSourceChangeMove;
    }
    for (id<KUSPaginatedDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(paginatedDataSource:didChangeObject:atIndex:forChangeType:newIndex:)]) {
            [listener paginatedDataSource:self
                          didChangeObject:object
                                  atIndex:prevIndex
                            forChangeType:changeType
                                 newIndex:newIndex];
        }
    }
}

- (void)notifyAnnouncersDidError:(NSError *)error
{
    for (id<KUSPaginatedDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(paginatedDataSource:didReceiveError:)]) {
            [listener paginatedDataSource:self didReceiveError:error];
        }
    }
}

- (void)notifyAnnouncersDidLoad
{
    for (id<KUSPaginatedDataSourceListener> listener in _listeners) {
        if ([listener respondsToSelector:@selector(paginatedDataSourceDidLoad:)]) {
            [listener paginatedDataSourceDidLoad:self];
        }
    }
}

@end
