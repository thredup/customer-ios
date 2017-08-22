//
//  KustomerWindow.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/21/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KustomerWindow : UIWindow

+ (KustomerWindow *)sharedInstance;

- (void)showFromPoint:(CGPoint)point;
- (void)hide;

@end
