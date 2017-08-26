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

@property (nonatomic, weak, readwrite) KUSUserSession *userSession;

@property (nonatomic, readwrite) BOOL isFetching;
@property (nonatomic, readwrite) BOOL didFetch;
@property (nonatomic, readwrite) BOOL didFetchAll;
@property (nonatomic, strong, readwrite) NSError *error;

@property (nonatomic, strong, nullable) NSObject *requestMarker;

@end

@implementation KUSPaginatedDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

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
        URL = [self.userSession.requestManager URLForEndpoint:_mostRecentPaginatedResponse.firstPath];
    }
    if (URL == nil) {
        return;
    }
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    self.error = nil;

    NSObject *requestMarker = [[NSObject alloc] init];
    self.requestMarker = requestMarker;

    __weak KUSPaginatedDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypeGet
     URL:URL
     params:nil
     authenticated:YES
     completion:^(NSError *error, NSDictionary *json) {
         __strong KUSPaginatedDataSource *strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         // Check to make sure that the request marker did not change
         if (strongSelf.requestMarker != requestMarker) {
             return;
         }
         strongSelf.requestMarker = nil;

         KUSPaginatedResponse *response = [[KUSPaginatedResponse alloc] initWithJSON:json modelClass:[strongSelf modelClass]];
         [strongSelf _prependResponse:response error:error];
     }];
}

- (void)fetchNext
{
    NSURL *URL;
    if (_lastPaginatedResponse) {
        URL = [self.userSession.requestManager URLForEndpoint:_lastPaginatedResponse.nextPath];
    } else if (_mostRecentPaginatedResponse) {
        URL = [self.userSession.requestManager URLForEndpoint:_mostRecentPaginatedResponse.nextPath];
    }
    if (URL == nil) {
        return;
    }
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    self.error = nil;

    NSObject *requestMarker = [[NSObject alloc] init];
    self.requestMarker = requestMarker;

    __weak KUSPaginatedDataSource *weakSelf = self;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypeGet
     URL:URL
     params:nil
     authenticated:YES
     completion:^(NSError *error, NSDictionary *json) {
         __strong KUSPaginatedDataSource *strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         // Check to make sure that the request marker did not change
         if (strongSelf.requestMarker != requestMarker) {
             return;
         }
         strongSelf.requestMarker = nil;

         KUSPaginatedResponse *response = [[KUSPaginatedResponse alloc] initWithJSON:json modelClass:[strongSelf modelClass]];
         [strongSelf _appendResponse:response error:error];
     }];
}

- (void)cancel
{
    self.isFetching = NO;
    self.requestMarker = nil;
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
        [objectIdToPrevious setObject:@(indexOfObject) forKey:object.oid];
    }
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
    self.didFetchAll = (self.didFetchAll || response.nextPath == nil);

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

    self.isFetching = NO;
    self.didFetch = YES;
    self.didFetchAll = (self.didFetchAll || response.nextPath == nil);

    [self prependObjects:response.objects];

    [self notifyAnnouncersDidLoad];
}

- (void)prependObjects:(NSArray<KUSModel *> *)objects
{
    NSMutableDictionary<NSString *, NSNumber *> *objectIdToPrevious = [[NSMutableDictionary alloc] init];

    for (KUSModel *object in objects.reverseObjectEnumerator) {
        NSUInteger indexOfObject = [self indexOfObject:object];
        [objectIdToPrevious setObject:@(indexOfObject) forKey:object.oid];
    }
    for (KUSModel *object in objects.reverseObjectEnumerator) {
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

    if (didNotifyWillChange) {
        [self notifyAnnouncersDidChangeContent];
    }
}

- (void)updateObjects:(NSArray<KUSModel *> *)objects
{
    if (objects.count == 0) {
        return;
    }

    BOOL didNotifyWillChange = NO;
    for (KUSModel *object in objects) {
        NSUInteger indexOfObject = [self indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            if (!didNotifyWillChange) {
                [self notifyAnnouncersWillChangeContent];
                didNotifyWillChange = YES;
            }
            [_fetchedModels replaceObjectAtIndex:indexOfObject withObject:object];
            [_fetchedModelsById setObject:object forKey:object.oid];
            [self notifyAnnouncersForObject:object previousIndex:indexOfObject newIndex:indexOfObject];
        }
    }

    if (didNotifyWillChange) {
        [self notifyAnnouncersDidChangeContent];
    }
}

- (void)removeObjects:(NSArray<KUSModel *> *)objects
{
    if (objects.count == 0) {
        return;
    }

    BOOL didNotifyWillChange = NO;
    for (KUSModel *object in objects) {
        NSUInteger indexOfObject = [self indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            if (!didNotifyWillChange) {
                [self notifyAnnouncersWillChangeContent];
                didNotifyWillChange = YES;
            }
            [_fetchedModels removeObjectAtIndex:indexOfObject];
            [_fetchedModelsById removeObjectForKey:object.oid];
            [self notifyAnnouncersForObject:object previousIndex:indexOfObject newIndex:NSNotFound];
        }
    }

    if (didNotifyWillChange) {
        [self notifyAnnouncersDidChangeContent];
    }
}

#pragma mark - Internal listener methods

- (void)notifyAnnouncersWillChangeContent
{
    for (id<KUSPaginatedDataSourceListener> listener in [_listeners copy]) {
        if ([listener respondsToSelector:@selector(paginatedDataSourceWillChangeContent:)]) {
            [listener paginatedDataSourceWillChangeContent:self];
        }
    }
}

- (void)notifyAnnouncersDidChangeContent
{
    for (id<KUSPaginatedDataSourceListener> listener in [_listeners copy]) {
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
    for (id<KUSPaginatedDataSourceListener> listener in [_listeners copy]) {
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
    for (id<KUSPaginatedDataSourceListener> listener in [_listeners copy]) {
        if ([listener respondsToSelector:@selector(paginatedDataSource:didReceiveError:)]) {
            [listener paginatedDataSource:self didReceiveError:error];
        }
    }
}

- (void)notifyAnnouncersDidLoad
{
    for (id<KUSPaginatedDataSourceListener> listener in [_listeners copy]) {
        if ([listener respondsToSelector:@selector(paginatedDataSourceDidLoad:)]) {
            [listener paginatedDataSourceDidLoad:self];
        }
    }
}

@end
