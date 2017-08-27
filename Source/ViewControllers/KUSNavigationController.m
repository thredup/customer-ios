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
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithNavigationBarClass:nil toolbarClass:[KUSAttributionToolbar class]];
    if (self) {
        [self _commonInit];
        [self pushViewController:rootViewController animated:NO];
    }
    return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self _commonInit];
    }
    return self;
}

#pragma mark - Internal methods

- (void)_commonInit
{
    UIImage *transparentImage = [UIImage new];
    self.navigationBar.tintColor = [KUSColor darkGrayColor];
    self.navigationBar.shadowImage = transparentImage;
    self.navigationBar.translucent = YES;
    [self.navigationBar setBackgroundImage:transparentImage forBarMetrics:UIBarMetricsDefault];

    self.toolbarHidden = NO;
}

@end
