//
//  KUSImage.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSImage : NSObject

+ (UIImage *)kustyImage;
+ (UIImage *)sendArrowImage;
+ (UIImage *)checkmarkImage;
+ (UIImage *)pencilImage;
+ (UIImage *)errorImage;

+ (UIImage *)sendImageWithSize:(CGSize)size color:(UIColor *)color;
+ (UIImage *)submitImageWithSize:(CGSize)size color:(UIColor *)color;
+ (UIImage *)circularImageWithSize:(CGSize)size color:(UIColor *)color;

+ (UIImage *)defaultAvatarImageForName:(NSString *)name;

@end
