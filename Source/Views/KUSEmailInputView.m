//
//  KUSEmailInputView.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/26/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSEmailInputView.h"

#import "KUSColor.h"
#import "KUSImage.h"

@interface KUSEmailInputView () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation KUSEmailInputView

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [KUSColor lightGrayColor];

        self.infoLabel = [[UILabel alloc] init];
        self.infoLabel.text = @"Don't miss a response! Get notified by email:";
        self.infoLabel.textAlignment = NSTextAlignmentCenter;
        self.infoLabel.textColor = [KUSColor darkGrayColor];
        self.infoLabel.font = [UIFont systemFontOfSize:12.0];
        self.infoLabel.adjustsFontSizeToFitWidth = YES;
        self.infoLabel.minimumScaleFactor = 10.0 / 12.0;
        [self addSubview:self.infoLabel];

        self.textField = [[UITextField alloc] init];
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.delegate = self;
        self.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 0.0)];
        self.textField.leftViewMode = UITextFieldViewModeAlways;
        self.textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 25.0, 0.0)];
        self.textField.rightViewMode = UITextFieldViewModeAlways;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.returnKeyType = UIReturnKeySend;
        self.textField.layer.borderColor = [KUSColor greenColor].CGColor;
        self.textField.layer.borderWidth = 1.0;
        self.textField.layer.masksToBounds = YES;
        self.textField.backgroundColor = [UIColor whiteColor];
        self.textField.placeholder = @"example@domain.com";
        self.textField.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:self.textField];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateSubmitButton)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self.textField];

        self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *submitImage = [KUSImage submitImageWithSize:CGSizeMake(24.0, 24.0) color:[KUSColor greenColor]];
        [self.submitButton setImage:submitImage forState:UIControlStateNormal];
        [self.submitButton addTarget:self
                              action:@selector(_userWantsToSubmit)
                    forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.submitButton];

        self.separatorView = [[UIView alloc] init];
        self.separatorView.backgroundColor = [KUSColor grayColor];
        [self addSubview:self.separatorView];

        [self _updateSubmitButton];
    }
    return self;
}

#pragma mark - View methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat sidePadding = 20.0;
    self.infoLabel.frame = (CGRect) {
        .origin.x = sidePadding,
        .origin.y = sidePadding / 2.0,
        .size.width = self.bounds.size.width - (sidePadding * 2.0),
        .size.height = sidePadding
    };

    self.textField.frame = (CGRect) {
        .origin.x = sidePadding,
        .origin.y = CGRectGetMaxY(self.infoLabel.frame) + 5.0,
        .size.width = self.bounds.size.width - (sidePadding * 2.0),
        .size.height = 30.0
    };
    self.textField.layer.cornerRadius = self.textField.frame.size.height / 2.0;

    self.submitButton.frame = (CGRect) {
        .origin.x = CGRectGetMaxX(self.textField.frame) - 30.0,
        .origin.y = CGRectGetMaxY(self.textField.frame) - 30.0,
        .size.width = 30.0,
        .size.height = 30.0
    };

    self.separatorView.frame = (CGRect) {
        .origin.y = self.bounds.size.height - 0.5,
        .size.width = self.bounds.size.width,
        .size.height = 0.5
    };
}

#pragma mark - Interface element methods

- (void)_userWantsToSubmit
{
    if ([self _isValidEmail]) {
        [self.delegate emailInputView:self didSubmitEmail:[self _sanitizedText]];
        [self.textField resignFirstResponder];
    }
}

- (NSString *)_sanitizedText
{
    return [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)_isValidEmail
{
    NSString *sanitizedText = [self _sanitizedText];
    static NSString *kEmailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", kEmailRegex];
    return sanitizedText.length > 0 && [emailPredicate evaluateWithObject:sanitizedText];
}

- (void)_updateSubmitButton
{
    BOOL isValidEmail = [self _isValidEmail];
    self.submitButton.userInteractionEnabled = isValidEmail;
    self.submitButton.alpha = (isValidEmail ? 1.0 : 0.5);
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self _userWantsToSubmit];
    return NO;
}

@end
