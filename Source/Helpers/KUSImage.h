//
//  KUSImage.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSImage : NSObject

+ (UIImage *)kustomerTeamIcon;
+ (UIImage *)kustyImage;
+ (UIImage *)sendArrowImage;
+ (UIImage *)pencilImage;

+ (UIImage *)sendImageWithSize:(CGSize)size color:(UIColor *)color;
+ (UIImage *)circularImageWithSize:(CGSize)size color:(UIColor *)color;

@end
