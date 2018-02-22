//
//  KUSWeakTimer.h
//  Kustomer
//
//  Created by Daniel Amitay on 2/21/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KUSWeakTimer : NSObject

// The underlying NSTimer
@property (nonatomic, strong, readonly) NSTimer *timer;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        target:(id)target
                                      selector:(SEL)selector
                                       repeats:(BOOL)repeats;

- (void)invalidate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
