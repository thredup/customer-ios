//
//  KUSChatPlaceholderTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatPlaceholderTableViewCell.h"

#import "KUSColor.h"

@implementation KUSChatPlaceholderTableViewCell

#pragma mark - Lifecycle methods

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

#pragma mark - UIView methods

- (void)drawRect:(CGRect)rect
{
    UIColor *placeholderColor = [KUSColor lightGrayColor];
    [placeholderColor setFill];

    CGFloat margins = 28.0;
    CGFloat barHeight = 10.0;
    CGFloat barPadding = 8.0;
    CGFloat maxBarWidth = rect.size.width - margins * 2.0;

    CGFloat totalBarHeight = barHeight * 3.0 + barPadding * 2.0;
    CGFloat yOffset = (rect.size.height - totalBarHeight) / 2.0;

    UIRectFill((CGRect) {
        .origin.x = margins,
        .origin.y = yOffset,
        .size.width = maxBarWidth * 0.15,
        .size.height = 10.0
    });

    UIRectFill((CGRect) {
        .origin.x = margins,
        .origin.y = yOffset + barHeight + barPadding,
        .size.width = maxBarWidth * 0.98,
        .size.height = 10.0
    });

    UIRectFill((CGRect) {
        .origin.x = margins,
        .origin.y = yOffset + (barHeight + barPadding) * 2.0,
        .size.width = maxBarWidth * 0.8,
        .size.height = 10.0
    });
}

@end
