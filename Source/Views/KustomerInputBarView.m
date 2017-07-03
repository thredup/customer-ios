//
//  KustomerInputBarView.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/3/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerInputBarView.h"

@interface KustomerInputBarView ()

@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation KustomerInputBarView

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _separatorView = [[UIView alloc] init];
        _separatorView.userInteractionEnabled = NO;
        _separatorView.backgroundColor = [UIColor colorWithWhite:237.0/255.0 alpha:1.0];
        [self addSubview:_separatorView];

        _textView = [[UITextView alloc] init];
        _textView.text = @"Type a message...";
        _textView.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_textView];

        _sendButton = [[UIButton alloc] init];
        _sendButton.backgroundColor = [UIColor blueColor];
        [self addSubview:_sendButton];
    }
    return self;
}

#pragma mark - UIView methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.separatorView.frame = (CGRect) {
        .size.width = self.bounds.size.width,
        .size.height = 1.0
    };
    self.sendButton.frame = (CGRect) {
        .origin.x = self.bounds.size.width - self.bounds.size.height,
        .size.width = self.bounds.size.height,
        .size.height = self.bounds.size.height
    };
    self.textView.frame = (CGRect) {
        .origin.x = 10.0,
        .origin.y = 3.0,
        .size.width = self.bounds.size.width - CGRectGetWidth(self.sendButton.frame) - 10.0 * 2.0,
        .size.height = self.bounds.size.height - 3.0 * 2.0
    };
}

@end
