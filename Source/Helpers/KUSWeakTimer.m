//
//  KUSWeakTimer.m
//  Kustomer
//
//  Created by Daniel Amitay on 2/21/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSWeakTimer.h"

@implementation KUSWeakTimer {
    __weak id _target;
    SEL _selector;
}

#pragma mark - Class methods

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        target:(id)target
                                      selector:(SEL)selector
                                       repeats:(BOOL)repeats
{
    KUSWeakTimer *weakTimer = [[self alloc] initWithTimeInterval:interval target:target selector:selector repeats:repeats];
    [[NSRunLoop mainRunLoop] addTimer:weakTimer.timer forMode:NSRunLoopCommonModes];
    return weakTimer;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                              target:(id)target
                            selector:(SEL)selector
                             repeats:(BOOL)repeats
{
    self = [super init];
    if (self) {
        _target = target;
        _selector = selector;
        _timeInterval = interval;

        _timer = [NSTimer timerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(fire)
                                       userInfo:nil
                                        repeats:repeats];
        _timer.tolerance = MIN(interval / 20.0, 2.0);
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
}

#pragma mark - Public methods

- (void)invalidate
{
    [_timer invalidate];
    _timer = nil;
}

@end
