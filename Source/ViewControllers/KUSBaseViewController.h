//
//  KUSBaseViewController.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSBaseViewController : UIViewController

- (void)showLoadingIndicatorWithText:(NSString *)text;
- (void)showLoadingIndicator;
- (void)hideLoadingIndicator;
- (void)showErrorWithText:(NSString *)text;

// Subclass overridable methods

- (void)userTappedRetryButton;

@end
