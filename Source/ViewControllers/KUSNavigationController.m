//
//  KUSNavigationController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSNavigationController.h"

#import "KUSAttributionToolbar.h"
#import "KUSColor.h"

@interface KUSNavigationController ()

@end

@implementation KUSNavigationController

#pragma mark - Lifecycle methods

- (instancetype)init
{
    self = [super initWithNavigationBarClass:nil toolbarClass:[KUSAttributionToolbar class]];
    if (self) {
        self.navigationBar.barTintColor = [KUSColor grayColor];
        self.navigationBar.tintColor = [KUSColor darkGrayColor];
        self.toolbarHidden = NO;
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithNavigationBarClass:nil toolbarClass:[KUSAttributionToolbar class]];
    if (self) {
        self.navigationBar.barTintColor = [KUSColor grayColor];
        self.navigationBar.tintColor = [KUSColor darkGrayColor];
        self.toolbarHidden = NO;

        [self pushViewController:rootViewController animated:NO];
    }
    return self;
}

@end
