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

@interface KUSNavigationController () {
    UIStatusBarStyle _preferredStatusBarStyle;
}

@end

@implementation KUSNavigationController

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSNavigationController class]) {
        UINavigationBar *appearance = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[self]];

        UIImage *transparentImage = [UIImage new];
        appearance.tintColor = [KUSColor darkGrayColor];
        appearance.shadowImage = transparentImage;
        appearance.translucent = YES;
        [appearance setBackgroundImage:transparentImage forBarMetrics:UIBarMetricsDefault];
    }
}

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
    self.toolbarHidden = NO;
    _preferredStatusBarStyle = UIStatusBarStyleDefault;
}

#pragma mark - Status bar appearance methods

- (void)setPreferredStatusBarStyle:(UIStatusBarStyle)preferredStatusBarStyle
{
    _preferredStatusBarStyle = preferredStatusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _preferredStatusBarStyle;
}

@end
