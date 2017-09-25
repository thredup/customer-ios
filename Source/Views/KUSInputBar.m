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

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSInputBar class]) {
        KUSInputBar *appearance = [KUSInputBar appearance];
        [appearance setBackgroundColor:[UIColor whiteColor]];
        [appearance setSeparatorColor:[KUSColor lightGrayColor]];
        [appearance setTextColor:[UIColor blackColor]];
        [appearance setTextFont:[UIFont systemFontOfSize:14.0]];
        [appearance setPlaceholder:@"Type a message..."];
        [appearance setPlaceholderColor:[UIColor lightGrayColor]];
        [appearance setSendButtonColor:[KUSColor blueColor]];
    }
}

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _separatorView = [[UIView alloc] init];
        _separatorView.userInteractionEnabled = NO;
        [self addSubview:_separatorView];

        _textView = [[KUSTextView alloc] init];
        _textView.delegate = self;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        [self addSubview:_textView];

        _sendButton = [[UIButton alloc] init];
        [_sendButton addTarget:self action:@selector(_pressSend) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_sendButton];

        [self _updateSendButton];
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

#pragma mark - UIResponder methods

- (BOOL)isFirstResponder
{
    return [_textView isFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return [_textView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [_textView becomeFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    return [_textView canResignFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [_textView resignFirstResponder];
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

- (void)_updateSendButton
{
    _sendButton.userInteractionEnabled = [self _actualText].length > 0;
    _sendButton.alpha = ([self _actualText].length ? 1.0 : 0.5);
}

#pragma mark - UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        if (_sendButton.userInteractionEnabled) {
            [self _pressSend];
        }
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(inputBarTextDidChange:)]) {
        [self.delegate inputBarTextDidChange:self];
    }
    [self _updateSendButton];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - UIAppearance methods

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    _textView.backgroundColor = self.backgroundColor;
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    _separatorView.backgroundColor = _separatorColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _textView.textColor = _textColor;
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    _textView.font = _textFont;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    _textView.placeholder = _placeholder;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    _textView.placeholderColor = _placeholderColor;
}

- (void)setSendButtonColor:(UIColor *)sendButtonColor
{
    _sendButtonColor = sendButtonColor;
    UIImage *sendButtonImage = [KUSImage sendImageWithSize:CGSizeMake(30.0, 30.0) color:_sendButtonColor];
    [_sendButton setImage:sendButtonImage forState:UIControlStateNormal];
}

@end
