//
//  KUSNewSessionButton.m
//  Kustomer
//
//  Created by Daniel Amitay on 9/5/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSNewSessionButton.h"

#import "KUSColor.h"
#import "KUSImage.h"

static const CGFloat kMinimumSessionButtonWidth = 180.0;
static const CGFloat kSessionButtonEdgePadding = 20.0;
static const CGFloat kSessionButtonHeight = 44.0;

@implementation KUSNewSessionButton

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat buttonRadius = 4.0;
        CGSize size = CGSizeMake(buttonRadius * 2.0, buttonRadius * 2.0);
        UIImage *circularImage = [KUSImage circularImageWithSize:size color:[KUSColor blueColor]];
        UIEdgeInsets capInsets = UIEdgeInsetsMake(buttonRadius, buttonRadius, buttonRadius, buttonRadius);
        UIImage *buttonImage = [circularImage resizableImageWithCapInsets:capInsets];

        UIImage *pencilImage = [KUSImage pencilImage];
        [self setImage:pencilImage forState:UIControlStateNormal];
        [self setImage:pencilImage forState:UIControlStateHighlighted];
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
        [self setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];

        [self setTitle:@"New Conversation" forState:UIControlStateNormal];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
        self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1.0, 1.0);
        self.layer.shadowRadius = 1.0;
        self.layer.shadowOpacity = 0.5;
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize maxSize = CGSizeMake(self.window.bounds.size.width - kSessionButtonEdgePadding * 2.0, kSessionButtonHeight);
    CGSize sizeThatFits = [self sizeThatFits:maxSize];
    CGFloat buttonWidth = MAX(ceil(sizeThatFits.width) + kSessionButtonEdgePadding * 2.0, kMinimumSessionButtonWidth);
    return CGSizeMake(buttonWidth, kSessionButtonHeight);
}

@end
