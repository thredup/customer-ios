//
//  KUSDelegateProxy.m
//  Kustomer
//
//  Created by Daniel Amitay on 9/19/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSDelegateProxy.h"

@interface KUSDelegateProxy ()

@property (nonatomic, weak) id<KustomerDelegate> delegate;

@end

@implementation KUSDelegateProxy

- (BOOL)shouldDisplayInAppNotification
{
    if ([self.delegate respondsToSelector:@selector(kustomerShouldDisplayInAppNotification)]) {
        return [self.delegate kustomerShouldDisplayInAppNotification];
    }
    return YES;
}
- (void)didTapOnInAppNotification
{
    if ([self.delegate respondsToSelector:@selector(kustomerDidTapOnInAppNotification)]) {
        [self.delegate kustomerDidTapOnInAppNotification];
    } else {
        UIViewController *topMostViewController = KUSTopMostViewController();
        if (topMostViewController) {
            KustomerViewController *kustomerViewController = [[KustomerViewController alloc] init];
            [topMostViewController presentViewController:kustomerViewController animated:YES completion:nil];
        } else {
            NSLog(@"Kustomer Error: Could not find view controller to present on top of!");
        }
    }
}

#pragma mark - Helper methods

NS_INLINE UIViewController *KUSTopMostViewController() {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = keyWindow.rootViewController;
    UIViewController *topMostViewController = rootViewController;
    while (topMostViewController && topMostViewController.presentedViewController) {
        topMostViewController = topMostViewController.presentedViewController;
    }
    return topMostViewController;
}

@end
