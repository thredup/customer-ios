//
//  KUSImage.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSImage.h"

@implementation KUSImage

#pragma mark - UIImage methods

+ (UIImage *)imageNamed:(NSString *)name
{
    NSBundle *kustomerBundle = [NSBundle bundleForClass:[self class]];
    UIImage *image = [UIImage imageNamed:name inBundle:kustomerBundle compatibleWithTraitCollection:nil];
    if (image) {
        return image;
    }
    return [UIImage imageNamed:name];
}

#pragma mark - Public methods

+ (UIImage *)kustomerTeamIcon
{
    return [self imageNamed:@"kustomer_team_icon"];
}

+ (UIImage *)kustyImage
{
    return [self imageNamed:@"kusty"];
}

+ (UIImage *)sendArrowImage
{
    return [self imageNamed:@"up_arrow"];
}

+ (UIImage *)pencilImage
{
    return [self imageNamed:@"pencil_image"];
}

+ (UIImage *)sendImageWithSize:(CGSize)size color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, (CGRect) { .size = size });
    CGSize arrowSize = CGSizeMake(ceil(size.width * 0.45), ceil(size.height * 0.45));
    [[self sendArrowImage] drawInRect:(CGRect) {
        .origin.x = (size.width - arrowSize.width) / 2.0,
        .origin.y = (size.height - arrowSize.height) / 2.0,
        .size = arrowSize
    }];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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
