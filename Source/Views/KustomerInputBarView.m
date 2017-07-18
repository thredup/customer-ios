//
//  KustomerInputBarView.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/3/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerInputBarView.h"

#import "KUSColor.h"
#import "KUSImage.h"

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
        _separatorView.backgroundColor = [KUSColor lightGrayColor];
        [self addSubview:_separatorView];

        _textView = [[UITextView alloc] init];
        _textView.text = @"Type a message...";
        _textView.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:_textView];

        UIColor *blueColor = [KUSColor blueColor];
        CGSize size = CGSizeMake(30.0, 30.0);
        UIImage *circularImage = [KUSImage circularImageWithSize:size color:blueColor];

        _sendButton = [[UIButton alloc] init];
        [_sendButton setImage:circularImage forState:UIControlStateNormal];
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
