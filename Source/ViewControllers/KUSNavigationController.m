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

@interface KUSNavigationController () <UIGestureRecognizerDelegate> {
    UIStatusBarStyle _preferredStatusBarStyle;
    UIInterfaceOrientationMask _supportedInterfaceOrientations;
}

@end

@implementation KUSNavigationController

#pragma mark - Lifecycle methods

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithNavigationBarClass:nil toolbarClass:[KUSAttributionToolbar class]];
    if (self) {
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
        _supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;

        [self setNavigationBarHidden:YES];
        [self setToolbarHidden:NO];
        [self pushViewController:rootViewController animated:NO];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.interactivePopGestureRecognizer.delegate = self;
}

#pragma mark - UIViewController orientation & status bar override methods

- (void)setPreferredStatusBarStyle:(UIStatusBarStyle)preferredStatusBarStyle
{
    _preferredStatusBarStyle = preferredStatusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _preferredStatusBarStyle;
}

- (void)setSupportedInterfaceOrientations:(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    _supportedInterfaceOrientations = supportedInterfaceOrientations;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return _supportedInterfaceOrientations;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return self.viewControllers.count > 1;
}

@end
