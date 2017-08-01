//
//  ViewController.m
//  KustomerExample
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "ViewController.h"

#import "Kustomer.h"
#import "KUSImage.h"

@interface ViewController () {
    UIButton *_supportButton;
    UIButton *_resetButton;
}

@end

@implementation ViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    CGFloat buttonRadius = 4.0;
    CGSize size = CGSizeMake(buttonRadius * 2.0, buttonRadius * 2.0);
    UIImage *circularImage = [KUSImage circularImageWithSize:size color:[UIColor colorWithWhite:0.9 alpha:1.0]];
    UIEdgeInsets capInsets = UIEdgeInsetsMake(buttonRadius, buttonRadius, buttonRadius, buttonRadius);
    UIImage *buttonImage = [circularImage resizableImageWithCapInsets:capInsets];

    _resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_resetButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_resetButton setTitle:@"Reset Tracking Token" forState:UIControlStateNormal];
    [_resetButton addTarget:self
                     action:@selector(_resetTracking)
           forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_resetButton];

    _supportButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_supportButton setImage:[KUSImage kustyImage] forState:UIControlStateNormal];
    _supportButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _supportButton.layer.shadowOffset = CGSizeZero;
    _supportButton.layer.shadowRadius = 4.0;
    _supportButton.layer.shadowOpacity = 0.33;
    [_supportButton addTarget:self
                       action:@selector(_openSupport)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_supportButton];

}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _resetButton.frame = (CGRect) {
        .origin.x = 50.0,
        .origin.y = 200.0,
        .size.width = self.view.bounds.size.width - 100.0,
        .size.height = 50.0
    };
    _supportButton.frame = (CGRect) {
        .origin.x = self.view.bounds.size.width - 75.0,
        .origin.y = self.view.bounds.size.height - 75.0,
        .size.width = 50.0,
        .size.height = 50.0
    };
}

#pragma mark - Interface methods

- (void)_openSupport
{
    KustomerViewController *kustomerViewController = [[KustomerViewController alloc] init];
    [self presentViewController:kustomerViewController animated:YES completion:nil];
}

- (void)_resetTracking
{
    [Kustomer resetTracking];
}

@end
