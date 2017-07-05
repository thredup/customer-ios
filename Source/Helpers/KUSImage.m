//
//  KUSImage.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSImage.h"

@implementation KUSImage

+ (UIImage *)kustomerTeamIcon
{
    static UIImage *kustomerTeamIcon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *imageURL = [NSURL URLWithString:@"data:image/png;base64,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"];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        kustomerTeamIcon = [UIImage imageWithData:imageData];;
    });
    return kustomerTeamIcon;
}

+ (UIImage *)circularImageWithSize:(CGSize)size color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, (CGRect) { .size = size });
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
