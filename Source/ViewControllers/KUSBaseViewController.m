//
//  KUSBaseViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSBaseViewController.h"

@interface KUSBaseViewController ()

@property (nonatomic, strong, null_resettable) UIActivityIndicatorView *loadingIndicatorView;

@end

@implementation KUSBaseViewController

#pragma mark - View layout methods

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _loadingIndicatorView.center = (CGPoint) {
        .x = self.view.bounds.size.width / 2.0,
        .y = self.view.bounds.size.height / 2.5
    };
}

#pragma mark - Public methods

- (void)showLoadingIndicator
{
    [self.loadingIndicatorView startAnimating];
}

- (void)hideLoadingIndicator
{
    [_loadingIndicatorView stopAnimating];
}

#pragma mark - Property methods

- (UIActivityIndicatorView *)loadingIndicatorView
{
    if (_loadingIndicatorView == nil) {
        _loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingIndicatorView.hidesWhenStopped = YES;
        _loadingIndicatorView.layer.zPosition = 1.0;
        [self.view addSubview:_loadingIndicatorView];
    }
    return _loadingIndicatorView;
}

@end
