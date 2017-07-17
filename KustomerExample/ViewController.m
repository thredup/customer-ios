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
}

@end

@implementation ViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

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

@end
