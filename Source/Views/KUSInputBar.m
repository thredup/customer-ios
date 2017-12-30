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
#import "KUSPermissions.h"
#import "KUSTextView.h"
#import "KUSImageAttachmentCollectionViewCell.h"

static const CGFloat kKUSInputBarMinimumHeight = 50.0;
static const CGFloat kKUSInputBarPadding = 3.0;
static const CGFloat kKUSInputBarButtonSize = 50.0;

static const CGFloat kKUSInputBarAttachmentsHeight = 90.0;
static const CGFloat kKUSInputBarAttachmentsPadding = 6.0;
static const CGSize kKUSInputBarImageAttachmentSize = {
    kKUSInputBarAttachmentsHeight - kKUSInputBarAttachmentsPadding * 2.0,
    kKUSInputBarAttachmentsHeight - kKUSInputBarAttachmentsPadding * 2.0
};

// To limit the maximum size of uploaded images
static const CGFloat kKUSMaximumImagePixelCount = 1000000.0;

static NSString *kCellIdentifier = @"ImageAttachment";

@interface KUSInputBar () <KUSImageAttachmentCollectionViewCellDelegate, KUSTextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
    CGFloat _lastDesiredHeight;
    NSMutableArray<UIImage *> *_imageAttachments;
}

@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UICollectionView *imageCollectionView;
@property (nonatomic, strong, readwrite) UIButton *attachmentButton;
@property (nonatomic, strong, readwrite) KUSTextView *textView;
@property (nonatomic, strong, readwrite) UIButton *sendButton;

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
        [appearance setPlaceholder:NSLocalizedString(@"Type a message...", nil)];
        [appearance setPlaceholderColor:[UIColor lightGrayColor]];
        [appearance setSendButtonColor:[KUSColor blueColor]];
        [appearance setKeyboardAppearance:UIKeyboardAppearanceDefault];
    }
}

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageAttachments = [[NSMutableArray alloc] init];

        _separatorView = [[UIView alloc] init];
        _separatorView.userInteractionEnabled = NO;
        [self addSubview:_separatorView];

        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.itemSize = kKUSInputBarImageAttachmentSize;
        collectionViewLayout.minimumInteritemSpacing = kKUSInputBarAttachmentsPadding + kKUSInputBarPadding;
        collectionViewLayout.minimumLineSpacing = kKUSInputBarAttachmentsPadding + kKUSInputBarPadding;
        _imageCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
        _imageCollectionView.alwaysBounceHorizontal = YES;
        _imageCollectionView.backgroundColor = [UIColor clearColor];
        _imageCollectionView.showsHorizontalScrollIndicator = NO;
        _imageCollectionView.dataSource = self;
        _imageCollectionView.delegate = self;
        [_imageCollectionView registerClass:[KUSImageAttachmentCollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
        [self addSubview:_imageCollectionView];

        _attachmentButton = [[UIButton alloc] init];
        [_attachmentButton addTarget:self action:@selector(_pressAttach) forControlEvents:UIControlEventTouchUpInside];
        _attachmentButton.hidden = YES;
        [self addSubview:_attachmentButton];

        _textView = [[KUSTextView alloc] init];
        _textView.delegate = self;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        }
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
    self.attachmentButton.frame = (CGRect) {
        .origin.y = self.bounds.size.height - kKUSInputBarButtonSize,
        .size.width = (self.attachmentButton.hidden ? 0.0 : kKUSInputBarButtonSize),
        .size.height = kKUSInputBarButtonSize
    };

    self.sendButton.frame = (CGRect) {
        .origin.x = self.bounds.size.width - kKUSInputBarButtonSize,
        .origin.y = self.bounds.size.height - kKUSInputBarButtonSize,
        .size.width = kKUSInputBarButtonSize,
        .size.height = kKUSInputBarButtonSize
    };

    self.imageCollectionView.hidden = self.imageAttachments.count == 0;
    self.imageCollectionView.frame = (CGRect) {
        .origin.x = kKUSInputBarPadding + kKUSInputBarAttachmentsPadding,
        .origin.y = kKUSInputBarPadding,
        .size.width = self.bounds.size.width - (kKUSInputBarPadding + kKUSInputBarAttachmentsPadding) * 2.0,
        .size.height = kKUSInputBarAttachmentsHeight
    };

    CGFloat imageAttachmentsOffset = (self.imageCollectionView.hidden ? 0.0 : kKUSInputBarAttachmentsHeight);
    CGFloat desiredTextHeight = [self.textView desiredHeight];
    self.textView.frame = (CGRect) {
        .origin.x = MAX(CGRectGetWidth(self.attachmentButton.frame), 10.0),
        .origin.y = (self.bounds.size.height - imageAttachmentsOffset - desiredTextHeight) / 2.0 + imageAttachmentsOffset,
        .size.width = self.bounds.size.width - CGRectGetWidth(self.sendButton.frame) - MAX(CGRectGetWidth(self.attachmentButton.frame), 10.0),
        .size.height = desiredTextHeight
    };
}

#pragma mark - Public methods

- (CGFloat)desiredHeight
{
    CGFloat textBarHeight = kKUSInputBarPadding;
    textBarHeight += [self.textView desiredHeight];
    textBarHeight += kKUSInputBarPadding;
    textBarHeight = MAX(textBarHeight, kKUSInputBarMinimumHeight);

    if (self.imageAttachments.count) {
        textBarHeight += kKUSInputBarAttachmentsHeight;
    }

    return textBarHeight;
}

- (void)setText:(NSString *)text
{
    _textView.text = text;
    [self textViewDidChange:_textView];
}

- (NSString *)text
{
    return [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)setAllowsAttachments:(BOOL)allowsAttachments
{
    _allowsAttachments = allowsAttachments;
    if (!_allowsAttachments) {
        _attachmentButton.hidden = YES;
    } else {
        _attachmentButton.hidden = ![KUSPermissions cameraAccessIsAvailable] && ![KUSPermissions photoLibraryAccessIsAvailable];
    }
    [self setNeedsLayout];
}

- (void)setImageAttachments:(NSArray<UIImage *> *)imageAttachments
{
    [_imageAttachments removeAllObjects];
    for (UIImage *image in imageAttachments) {
        UIImage *resizedImage = [KUSImage resizeImage:image toFixedPixelCount:kKUSMaximumImagePixelCount];
        [_imageAttachments addObject:resizedImage];
    }
    [self _checkIfDesiredHeightDidChange];
    [_imageCollectionView reloadData];
    [self setNeedsLayout];
}

- (NSArray<UIImage *> *)imageAttachments
{
    return [_imageAttachments copy];
}

- (void)attachImage:(UIImage *)image
{
    UIImage *resizedImage = [KUSImage resizeImage:image toFixedPixelCount:kKUSMaximumImagePixelCount];
    [_imageAttachments addObject:resizedImage];
    [self _checkIfDesiredHeightDidChange];
    [_imageCollectionView reloadData];
    [self setNeedsLayout];

    dispatch_async(dispatch_get_main_queue(), ^{
        // Scroll the image collection view all the way to the right
        CGPoint rightOffset = CGPointMake(MAX(self.imageCollectionView.contentSize.width - self.imageCollectionView.bounds.size.width, 0.0), 0.0);
        [self.imageCollectionView setContentOffset:rightOffset animated:YES];
    });
}

- (void)_removeImage:(UIImage *)image
{
    [_imageAttachments removeObject:image];
    [self _checkIfDesiredHeightDidChange];
    [_imageCollectionView reloadData];
    [self setNeedsLayout];
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

- (void)_pressAttach
{
    if ([self.delegate respondsToSelector:@selector(inputBarDidTapAttachment:)]) {
        [self.delegate inputBarDidTapAttachment:self];
    }
}

- (void)_pressSend
{
    NSString *text = self.text;
    if (text.length == 0) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(inputBarDidPressSend:)]) {
        [self.delegate inputBarDidPressSend:self];
    }
}

- (void)_updateSendButton
{
    NSString *text = self.text;
    BOOL shouldEnableSend = text.length > 0;
    if (shouldEnableSend && [self.delegate respondsToSelector:@selector(inputBarShouldEnableSend:)]) {
        shouldEnableSend = [self.delegate inputBarShouldEnableSend:self];
    }
    _sendButton.userInteractionEnabled = shouldEnableSend;
    _sendButton.alpha = (shouldEnableSend ? 1.0 : 0.5);
}

#pragma mark - Internal logic methods

- (void)_checkIfDesiredHeightDidChange
{
    CGFloat desiredHeight = [self desiredHeight];
    if (desiredHeight != _lastDesiredHeight) {
        _lastDesiredHeight = desiredHeight;
        if ([self.delegate respondsToSelector:@selector(inputBarDesiredHeightDidChange:)]) {
            [self.delegate inputBarDesiredHeightDidChange:self];
        }
    }
}

#pragma mark - KUSTextViewDelegate methods

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
    [self _checkIfDesiredHeightDidChange];
    [self setNeedsLayout];
}

- (BOOL)textViewCanPasteImage:(KUSTextView *)textView
{
    return _allowsAttachments;
}

- (void)textView:(KUSTextView *)textView didPasteImage:(UIImage *)image
{
    [self attachImage:image];
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _imageAttachments.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KUSImageAttachmentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.image = [_imageAttachments objectAtIndex:indexPath.row];
    cell.delegate = self;
    return cell;
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(inputBar:wantsToPreviewImage:)]) {
        UIImage *image = [_imageAttachments objectAtIndex:indexPath.row];
        [self.delegate inputBar:self wantsToPreviewImage:image];
    }
}

#pragma mark - KUSImageAttachmentCollectionViewCellDelegate methods

- (void)imageAttachmentCollectionViewCellDidTapRemove:(KUSImageAttachmentCollectionViewCell *)cell
{
    [self _removeImage:cell.image];
}

#pragma mark - UIAppearance methods

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    _textView.backgroundColor = self.backgroundColor;

    UIImage *attachmentButtonImage = [KUSImage attachImageWithSize:CGSizeMake(35.0, 35.0) color:self.backgroundColor];
    [_attachmentButton setImage:attachmentButtonImage forState:UIControlStateNormal];
    _attachmentButton.imageView.tintColor = [UIColor redColor];
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

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance
{
    _keyboardAppearance = keyboardAppearance;
    _textView.keyboardAppearance = _keyboardAppearance;
}

@end
