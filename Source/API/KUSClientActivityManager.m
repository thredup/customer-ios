//
//  KUSClientActivityManager.m
//  Kustomer
//
//  Created by Daniel Amitay on 2/11/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSClientActivityManager.h"

#import <QuartzCore/CABase.h>

#import "KUSClientActivityDataSource.h"
#import "KUSUserSession.h"
#import "KUSWeakTimer.h"

@interface KUSClientActivityManager () <KUSObjectDataSourceListener> {
    __weak KUSUserSession *_userSession;
    NSString *_previousPageName;
    NSTimeInterval _currentPageStartTime;

    NSArray<KUSWeakTimer *> *_timers;
    KUSClientActivityDataSource *_activityDataSource;
}

@end

@implementation KUSClientActivityManager

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;
    }
    return self;
}

#pragma mark - Internal methods

- (void)_cancelTimers
{
    NSArray<KUSWeakTimer *> *timers = [_timers copy];
    _timers = nil;
    for (KUSWeakTimer *timer in timers) {
        [timer invalidate];
    }
}

- (void)_updateTimers
{
    if (_activityDataSource.object == nil) {
        [self _cancelTimers];
        return;
    }

    NSMutableArray<KUSWeakTimer *> *timers = [[NSMutableArray alloc] initWithCapacity:_activityDataSource.intervals.count];
    for (NSNumber *intervalNumber in _activityDataSource.intervals) {
        KUSWeakTimer *timer = [KUSWeakTimer scheduledTimerWithTimeInterval:intervalNumber.doubleValue
                                                                    target:self
                                                                  selector:@selector(_onActivityTimer:)
                                                                   repeats:NO];
        [timers addObject:timer];
    }
    _timers = timers;
}

- (void)_requestClientActivity
{
    [self _requestClientActivityWithCurrentPageSeconds:[self _timeOnCurrentPage]];
}

- (void)_requestClientActivityWithCurrentPageSeconds:(NSTimeInterval)currentPageSeconds
{
    _activityDataSource = [[KUSClientActivityDataSource alloc] initWithUserSession:_userSession
                                                                  previousPageName:_previousPageName
                                                                   currentPageName:_currentPageName
                                                                currentPageSeconds:currentPageSeconds];
    [_activityDataSource addListener:self];
    [_activityDataSource fetch];
}

#pragma mark - Internal helper methods

- (NSTimeInterval)_timeOnCurrentPage
{
    return CACurrentMediaTime() - _currentPageStartTime;
}

#pragma mark - Timer methods

- (void)_onActivityTimer:(KUSWeakTimer *)timer
{
    [self _requestClientActivity];
}

#pragma mark - Public methods

- (void)setCurrentPageName:(NSString *)currentPageName
{
    if (_currentPageName == currentPageName || [_currentPageName isEqualToString:currentPageName]) {
        return;
    }
    _previousPageName = [_currentPageName copy];
    _currentPageName = [currentPageName copy];

    [self _cancelTimers];
    [_activityDataSource cancel];
    _activityDataSource = nil;

    // If we don't have a current page name, stop here.
    if (_currentPageName == nil) {
        return;
    }

    _currentPageStartTime = CACurrentMediaTime();
    [self _requestClientActivityWithCurrentPageSeconds:0];
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    if (dataSource == _activityDataSource) {
        KUSClientActivity *clientActivity = (KUSClientActivity *)_activityDataSource.object;
        if (clientActivity.currentPageSeconds > 0) {
            [_userSession.pushClient onClientActivityTick];
        }
    }
    [self _updateTimers];
}

- (void)objectDataSource:(KUSObjectDataSource *)dataSource didReceiveError:(NSError *)error
{
    if (dataSource == _activityDataSource) {
        __weak KUSClientActivityManager *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf _requestClientActivity];
        });
    }
}

@end
