//
//  KUSWeakTimer.m
//  Kustomer
//
//  Created by Daniel Amitay on 2/21/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSWeakTimer.h"

@interface KUSWeakTarget : NSObject

- (instancetype)initWithTarget:(id)target selector:(SEL)selector timer:(KUSWeakTimer *)timer;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)fire;

@end

@implementation KUSWeakTimer {
    __weak KUSWeakTarget *_target;
}

#pragma mark - Class methods

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector repeats:(BOOL)repeats
{
    KUSWeakTimer *weakTimer = [[self alloc] initWithTimeInterval:interval target:target selector:selector repeats:repeats];
    [[NSRunLoop mainRunLoop] addTimer:weakTimer.timer forMode:NSRunLoopCommonModes];
    return weakTimer;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector repeats:(BOOL)repeats
{
    self = [super init];
    if (self) {
        KUSWeakTarget *weakTarget = [[KUSWeakTarget alloc] initWithTarget:target selector:selector timer:self];
        _timer = [NSTimer timerWithTimeInterval:interval target:weakTarget selector:@selector(fire) userInfo:nil repeats:repeats];
        _timer.tolerance = MIN(interval / 20.0, 1.0);
        _target = weakTarget;
    }
    return self;
}

- (void)dealloc
{
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - Internal methods

- (void)fire
{
    [_target fire];
}

#pragma mark - Public methods

- (void)invalidate
{
    [_timer invalidate];
    _timer = nil;
}

- (NSTimeInterval)timeInterval
{
    return _timer.timeInterval;
}

@end

@implementation KUSWeakTarget {
    __weak id _target;
    SEL _selector;
    __weak KUSWeakTimer *_timer;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector timer:(KUSWeakTimer *)timer
{
    self = [super init];
    if (self) {
        _target = target;
        _selector = selector;
        _timer = timer;
    }
    return self;
}

- (void)fire
{

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:_timer];
#pragma clang diagnostic pop
}

@end
