//
//  ViewController.m
//  KustomerExample
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "ViewController.h"

#import "KustomerChatViewController.h"

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
    _supportButton.backgroundColor = [UIColor lightGrayColor];
    [_supportButton setTitle:@"Open Support" forState:UIControlStateNormal];
    [_supportButton addTarget:self
                       action:@selector(_openSupport)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_supportButton];

}

- (void)viewWillLayoutSubviews
{
    _supportButton.frame = (CGRect) {
        .origin.x = (self.view.bounds.size.width - 250.0) / 2.0,
        .origin.y = 200.0,
        .size.width = 250.0,
        .size.height = 50.0
    };
}

#pragma mark - Interface methods

- (void)_openSupport
{
    KustomerChatViewController *chatViewController = [[KustomerChatViewController alloc] init];
    [self presentViewController:chatViewController animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [chatViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

@end
