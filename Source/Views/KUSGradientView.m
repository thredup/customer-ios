//
//  KUSGradientView.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/26/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSGradientView.h"

@implementation KUSGradientView

#pragma mark - Class methods

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _topColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        _bottomColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        [self _updateColors];
    }
    return self;
}

#pragma mark - Internal methods

- (void)_updateColors
{
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    gradientLayer.colors = @[(id)[self.topColor CGColor],
                             (id)[self.bottomColor CGColor]];
}

#pragma mark - View methods

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitTest = [super hitTest:point withEvent:event];
    if (hitTest == self) {
        return nil;
    }
    return hitTest;
}

#pragma mark - Property methods

- (void)setTopColor:(UIColor *)topColor
{
    _topColor = topColor;
    [self _updateColors];
}

- (void)setBottomColor:(UIColor *)bottomColor
{
    _bottomColor = bottomColor;
    [self _updateColors];
}

@end
