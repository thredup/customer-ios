//
//  KUSGradientView.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/26/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSGradientView : UIView

@property (nonatomic, strong, nonnull) UIColor *topColor;    // Default: [UIColor colorWithWhite:1.0 alpha:0.0]
@property (nonatomic, strong, nonnull) UIColor *bottomColor; // Default: [UIColor colorWithWhite:1.0 alpha:0.5]

@end
