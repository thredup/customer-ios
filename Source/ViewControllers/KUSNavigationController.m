//
//  KUSNavigationController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSNavigationController.h"

#import "KUSAttributionToolbar.h"

@interface KUSNavigationController ()

@end

@implementation KUSNavigationController

#pragma mark - Lifecycle methods

- (instancetype)init
{
    self = [super initWithNavigationBarClass:nil toolbarClass:[KUSAttributionToolbar class]];
    if (self) {
        self.navigationBar.barTintColor = [UIColor colorWithWhite:237.0/255.0 alpha:1.0];
        self.toolbarHidden = NO;
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [self init];
    if (self) {
        [self pushViewController:rootViewController animated:NO];
    }
    return self;
}

@end
