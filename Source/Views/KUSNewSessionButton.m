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
#import "KUSLocalizationManager.h"

static const CGFloat kMinimumSessionButtonWidth = 180.0;
static const CGFloat kSessionButtonEdgePadding = 20.0;
static const CGFloat kSessionButtonHeight = 44.0;

@implementation KUSNewSessionButton

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSNewSessionButton class]) {
        KUSNewSessionButton *appearance = [KUSNewSessionButton appearance];
        [appearance setColor:[KUSColor blueColor]];
        [appearance setImage:[KUSImage pencilImage]];
        [appearance setTextColor:[UIColor whiteColor]];
        [appearance setTextFont:[UIFont systemFontOfSize:14.0]];
        [appearance setHasShadow:YES];
        [appearance setText:[[KUSLocalizationManager sharedInstance] localizedString:@"New Conversation"]];
    }
}

#pragma mark - Lifecycle methods

- (CGSize)intrinsicContentSize
{
    CGSize maxSize = CGSizeMake(self.window.bounds.size.width - kSessionButtonEdgePadding * 2.0, kSessionButtonHeight);
    CGSize sizeThatFits = [self sizeThatFits:maxSize];
    CGFloat buttonWidth = MAX(ceil(sizeThatFits.width) + kSessionButtonEdgePadding * 2.0, kMinimumSessionButtonWidth);
    return CGSizeMake(buttonWidth, kSessionButtonHeight);
}

#pragma mark - UIAppearance methods

- (void)setColor:(UIColor *)color
{
    _color = color;

    CGFloat buttonRadius = 4.0;
    CGSize size = CGSizeMake(buttonRadius * 2.0, buttonRadius * 2.0);
    UIImage *circularImage = [KUSImage circularImageWithSize:size color:_color];
    UIEdgeInsets capInsets = UIEdgeInsetsMake(buttonRadius, buttonRadius, buttonRadius, buttonRadius);
    UIImage *buttonImage = [circularImage resizableImageWithCapInsets:capInsets];
    [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setImage:_image forState:UIControlStateNormal];
    [self setImage:_image forState:UIControlStateHighlighted];
    if ([[KUSLocalizationManager sharedInstance] isCurrentLanguageRTL])
    {
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
        [self setImageEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    }
    else
    {
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
        [self setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self setTitleColor:_textColor forState:UIControlStateNormal];
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    self.titleLabel.font = _textFont;
}

- (void)setHasShadow:(BOOL)hasShadow
{
    _hasShadow = hasShadow;
    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.layer.shadowRadius = (_hasShadow ? 1.0 : 0.0);
    self.layer.shadowOpacity = (_hasShadow ? 0.5 : 0.0);
}

- (void)setText:(NSString *)text
{
    _text = text;
    [self setTitle:_text forState:UIControlStateNormal];
}

@end
