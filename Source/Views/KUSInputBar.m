//
//  KUSInputBar.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/21/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSInputBar.h"

#import "KUSColor.h"
#import "KUSImage.h"
#import "KUSTextView.h"

static const CGFloat kKUSInputBarMinimumHeight = 50.0;
static const CGFloat kKUSInputBarButtonSize = 50.0;

@interface KUSInputBar () <UITextViewDelegate>

@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) KUSTextView *textView;
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation KUSInputBar

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];

        _separatorView = [[UIView alloc] init];
        _separatorView.userInteractionEnabled = NO;
        _separatorView.backgroundColor = [KUSColor lightGrayColor];
        [self addSubview:_separatorView];

        _textView = [[KUSTextView alloc] init];
        _textView.backgroundColor = self.backgroundColor;
        _textView.placeholder = @"Type a message...";
        _textView.font = [UIFont systemFontOfSize:14.0];
        _textView.delegate = self;
        [self addSubview:_textView];

        UIColor *blueColor = [KUSColor blueColor];
        CGSize size = CGSizeMake(30.0, 30.0);
        UIImage *circularImage = [KUSImage sendImageWithSize:size color:blueColor];

        _sendButton = [[UIButton alloc] init];
        [_sendButton setImage:circularImage forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(_pressSend) forControlEvents:UIControlEventTouchUpInside];
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
        .origin.x = self.bounds.size.width - kKUSInputBarButtonSize,
        .origin.y = self.bounds.size.height - kKUSInputBarButtonSize,
        .size.width = kKUSInputBarButtonSize,
        .size.height = kKUSInputBarButtonSize
    };

    CGFloat desiredTextHeight = [self.textView desiredHeight];
    self.textView.frame = (CGRect) {
        .origin.x = 10.0,
        .origin.y = (self.bounds.size.height - desiredTextHeight) / 2.0,
        .size.width = self.bounds.size.width - CGRectGetWidth(self.sendButton.frame) - 10.0,
        .size.height = desiredTextHeight
    };
}

#pragma mark - Public methods

- (CGFloat)desiredHeight
{
    CGFloat height = [self.textView desiredHeight] + 3.0 * 2.0;
    return MAX(height, kKUSInputBarMinimumHeight);
}

#pragma mark - Interface element methods

- (NSString *)_actualText
{
    return [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)_pressSend
{
    NSString *actualText = [self _actualText];
    if (actualText.length == 0) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(inputBar:didEnterText:)]) {
        [self.delegate inputBar:self didEnterText:actualText];
    }
    _textView.text = nil;
    [self textViewDidChange:_textView];
}

#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(inputBarTextDidChange:)]) {
        [self.delegate inputBarTextDidChange:self];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
