//
//  KUSMLSelectedValueCollectionViewCell.m
//  Kustomer
//
//  Created by BrainX Technologies on 03/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSMLSelectedValueCollectionViewCell.h"
#import "KUSColor.h"

static const CGFloat kKUSVerticalSeparatorWidth = 3.0;
static const CGFloat kKUSVerticalSeparatorPadding = 8.0;

@implementation KUSMLSelectedValueCollectionViewCell {
    UILabel *_valueLabel;
    UIView *_verticalSeparator;
    
    BOOL isSelected;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        isSelected = NO;
        
        _verticalSeparator = [[UIView alloc] init];
        _verticalSeparator.backgroundColor = [KUSColor lightGrayColor];
        [self.contentView addSubview:_verticalSeparator];
        
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.backgroundColor = [UIColor clearColor];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_valueLabel];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    _verticalSeparator.frame = (CGRect) {
        .origin.x = self.bounds.origin.x,
        .origin.y = self.bounds.origin.y + kKUSVerticalSeparatorPadding,
        .size.width = kKUSVerticalSeparatorWidth,
        .size.height = self.bounds.size.height - (kKUSVerticalSeparatorPadding * 2)
    };
    _valueLabel.frame = (CGRect) {
        .origin.x = self.bounds.origin.x + kKUSVerticalSeparatorWidth,
        .origin.y = self.bounds.origin.y,
        .size.width = self.bounds.size.width - kKUSVerticalSeparatorWidth,
        .size.height = self.bounds.size.height
    };
    _valueLabel.textColor = isSelected ? _highlightedTextColor : _textColor;
}

- (void)setValue:(NSString *)value
{
    _value = value;
    _valueLabel.text = value;
}

- (void)setVerticalSeparatorColor:(UIColor *)verticalSeparatorColor
{
    _verticalSeparatorColor = verticalSeparatorColor;
    _verticalSeparator.backgroundColor = verticalSeparatorColor;
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    _valueLabel.font = textFont;
}

- (void)setCellBackgroundColor:(UIColor *)cellBackgroundColor
{
    _cellBackgroundColor = cellBackgroundColor;
    self.backgroundColor = cellBackgroundColor;
    _valueLabel.backgroundColor = cellBackgroundColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _valueLabel.textColor = textColor;
}

- (void)setHighlightedTextColor:(UIColor *)highlightedTextColor
{
    _highlightedTextColor = highlightedTextColor;
}

- (void)setCellValue:(NSString *)value withFirsCell:(BOOL)first andLastCell:(BOOL)last;
{
    [self setValue:value];
    isSelected = last;
    _valueLabel.textColor = last ? _highlightedTextColor : _textColor;
    _verticalSeparator.hidden = first;
}
@end
