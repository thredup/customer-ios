//
//  KUSChatMessageTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessageTableViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "KUSChatMessage.h"
#import "KUSColor.h"
#import "KUSImage.h"
#import "KUSText.h"
#import "KUSUserSession.h"

#import "KUSAvatarImageView.h"

static const CGFloat kBubbleTopPadding = 10.0;
static const CGFloat kBubbleSidePadding = 12.0;

static const CGFloat kRowSidePadding = 11.0;
static const CGFloat kRowTopPadding = 3.0;

static const CGFloat kMaxBubbleWidth = 250.0;
static const CGFloat kMinBubbleHeight = 38.0;

@interface KUSChatMessageTableViewCell () <TTTAttributedLabelDelegate> {
    KUSUserSession *_userSession;
    KUSChatMessage *_chatMessage;
    BOOL _showsAvatar;
    NSTimer *_sendingFadeTimer;

    KUSAvatarImageView *_avatarImageView;
    UIView *_bubbleView;
    TTTAttributedLabel *_labelView;
    UIImageView *_imageView;
    UIButton *_errorButton;
}

@end

@implementation KUSChatMessageTableViewCell

#pragma mark - Class methods

+ (CGFloat)heightForChatMessage:(KUSChatMessage *)chatMessage maxWidth:(CGFloat)maxWidth
{
    CGFloat height = [self boundingSizeForMessage:chatMessage maxWidth:maxWidth].height;
    height += kBubbleTopPadding * 2.0;
    height = MAX(height, kMinBubbleHeight);
    height += kRowTopPadding * 2.0;
    return height;
}

+ (CGFloat)fontSize
{
    return 14.0;
}

+ (UIFont *)messageFont
{
    return [UIFont systemFontOfSize:14.0];
}

+ (CGSize)boundingSizeForMessage:(KUSChatMessage *)message maxWidth:(CGFloat)maxWidth
{
    switch (message.type) {
        default:
        case KUSChatMessageTypeText:
            return [self boundingSizeForText:message.body maxWidth:maxWidth];
        case KUSChatMessageTypeImage:
            return [self boundingSizeForImage:message.imageURL maxWidth:maxWidth];
    }
}

+ (CGSize)boundingSizeForImage:(NSURL *)imageURL maxWidth:(CGFloat)maxWidth
{
    CGFloat actualMaxWidth = MIN(kMaxBubbleWidth - kBubbleSidePadding * 2.0, maxWidth);
    CGFloat size = MIN(ceil([UIScreen mainScreen].bounds.size.width / 2.0), actualMaxWidth);
    return CGSizeMake(size, size);
}

+ (CGSize)boundingSizeForText:(NSString *)text maxWidth:(CGFloat)maxWidth
{
    CGFloat actualMaxWidth = MIN(kMaxBubbleWidth - kBubbleSidePadding * 2.0, maxWidth);

    NSAttributedString *attributedString = [KUSText attributedStringFromText:text fontSize:[self fontSize]];

    CGSize maxSize = CGSizeMake(actualMaxWidth, 1000.0);
    CGRect boundingRect = [attributedString boundingRectWithSize:maxSize
                                                         options:(NSStringDrawingUsesLineFragmentOrigin
                                                                  | NSStringDrawingUsesFontLeading)
                                                         context:nil];

    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize boundingSize = boundingRect.size;
    boundingSize.width = ceil(boundingSize.width * scale) / scale;
    boundingSize.height = ceil(boundingSize.height * scale) / scale;
    return boundingSize;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier userSession:(KUSUserSession *)userSession
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:userSession];
        [self.contentView addSubview:_avatarImageView];

        _bubbleView = [[UIView alloc] init];
        _bubbleView.layer.masksToBounds = YES;
        [self.contentView addSubview:_bubbleView];

        _labelView = [[TTTAttributedLabel alloc] initWithFrame:self.bounds];
        _labelView.delegate = self;
        _labelView.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        _labelView.textAlignment = NSTextAlignmentLeft;
        _labelView.font = [[self class] messageFont];
        _labelView.numberOfLines = 0;
        [_bubbleView addSubview:_labelView];

        NSMutableDictionary *mutableActiveLinkAttributes = [_labelView.linkAttributes mutableCopy];
        [mutableActiveLinkAttributes setObject:@NO forKey:NSUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setObject:[UIColor colorWithWhite:0.0 alpha:0.2] forKey:NSBackgroundColorAttributeName];
        _labelView.activeLinkAttributes = mutableActiveLinkAttributes;

        _imageView = [[UIImageView alloc] init];
        _imageView.userInteractionEnabled = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.layer.cornerRadius = 4.0;
        _imageView.layer.masksToBounds = YES;
        [_bubbleView addSubview:_imageView];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapImage)];
        [_imageView addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

- (void)dealloc
{
    _labelView.delegate = nil;
}

#pragma mark - Layout methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    BOOL currentUser = _chatMessage.direction == KUSChatMessageDirectionIn;

    _avatarImageView.hidden = currentUser || !_showsAvatar;
    _avatarImageView.frame = (CGRect) {
        .origin.x = kRowSidePadding,
        .origin.y = (self.contentView.bounds.size.height - 40.0) / 2.0,
        .size.width = 40.0,
        .size.height = 40.0
    };

    CGSize boundingSizeForContent = [[self class] boundingSizeForMessage:_chatMessage maxWidth:self.contentView.bounds.size.width];

    CGSize bubbleViewSize = (CGSize) {
        .width = boundingSizeForContent.width + kBubbleSidePadding * 2.0,
        .height = self.contentView.bounds.size.height - kRowTopPadding * 2.0
    };
    _bubbleView.frame = (CGRect) {
        .origin.x = currentUser ? self.contentView.bounds.size.width - bubbleViewSize.width - kRowSidePadding : 60.0,
        .origin.y = kRowTopPadding,
        .size = bubbleViewSize
    };
    _bubbleView.layer.cornerRadius = MIN(_bubbleView.frame.size.height / 2.0, 15.0);

    switch (_chatMessage.type) {
        default:
        case KUSChatMessageTypeText: {
            _labelView.frame = (CGRect) {
                .origin.x = (_bubbleView.bounds.size.width - boundingSizeForContent.width) / 2.0,
                .origin.y = (_bubbleView.bounds.size.height - boundingSizeForContent.height) / 2.0,
                .size = boundingSizeForContent
            };
        }   break;
        case KUSChatMessageTypeImage: {
            _imageView.frame = (CGRect) {
                .origin.x = (_bubbleView.bounds.size.width - boundingSizeForContent.width) / 2.0,
                .origin.y = (_bubbleView.bounds.size.height - boundingSizeForContent.height) / 2.0,
                .size = boundingSizeForContent
            };
        }   break;
    }

    _errorButton.frame = (CGRect) {
        .origin.x = _bubbleView.frame.origin.x - kMinBubbleHeight - 5.0,
        .origin.y = _bubbleView.frame.origin.y + (_bubbleView.frame.size.height - kMinBubbleHeight) / 2.0,
        .size.width = kMinBubbleHeight,
        .size.height = kMinBubbleHeight
    };
}

#pragma mark - Internal logic methods

// If sending messages takes less than 500ms, we don't want to show the loading indicator
static NSTimeInterval kOptimisticSendLoadingDelay = 0.5;

- (void)_updateAlphaForState
{
    [_sendingFadeTimer invalidate];
    _sendingFadeTimer = nil;

    switch(_chatMessage.state) {
        case KUSChatMessageStateSent: {
            _bubbleView.alpha = 1.0;
        }   break;
        case KUSChatMessageStateSending: {
            NSTimeInterval timeElapsed = -[_chatMessage.sendingDate timeIntervalSinceNow];
            if (timeElapsed >= kOptimisticSendLoadingDelay) {
                _bubbleView.alpha = 0.5;
            } else {
                _bubbleView.alpha = 1.0;

                NSTimeInterval timerInterval = kOptimisticSendLoadingDelay - timeElapsed;
                _sendingFadeTimer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
                                                                     target:self
                                                                   selector:_cmd
                                                                   userInfo:nil
                                                                    repeats:NO];
            }
        }   break;
        case KUSChatMessageStateFailed: {
            _bubbleView.alpha = 0.5;
        }   break;
    }
}

#pragma mark - Property methods

- (void)setChatMessage:(KUSChatMessage *)chatMessage
{
    _chatMessage = chatMessage;

    BOOL currentUser = _chatMessage.direction == KUSChatMessageDirectionIn;

    UIColor *bubbleColor = (currentUser ? [KUSColor blueColor] : [KUSColor lightGrayColor]);
    UIColor *textColor = (currentUser ? [UIColor whiteColor] : [UIColor blackColor]);

    _bubbleView.backgroundColor = bubbleColor;
    _imageView.backgroundColor = bubbleColor;
    _labelView.backgroundColor = bubbleColor;
    _labelView.textColor = textColor;

    _labelView.hidden = _chatMessage.type != KUSChatMessageTypeText;
    _imageView.hidden = _chatMessage.type != KUSChatMessageTypeImage;

    switch (_chatMessage.type) {
        case KUSChatMessageTypeText: {
            _labelView.text = [KUSText attributedStringFromText:_chatMessage.body fontSize:[[self class] fontSize] color:textColor];

            _imageView.image = nil;
            [_imageView sd_setImageWithURL:nil];
        }   break;
        case KUSChatMessageTypeImage: {
            _labelView.text = nil;

            [_imageView sd_setShowActivityIndicatorView:YES];
            [_imageView sd_setIndicatorStyle:(currentUser ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray)];
            SDWebImageOptions options = SDWebImageHighPriority | SDWebImageScaleDownLargeImages;
            [_imageView sd_setImageWithURL:_chatMessage.imageURL placeholderImage:nil options:options];
        }   break;
    }

    [_avatarImageView setUserId:(currentUser ? nil : _chatMessage.sentById)];

    if (_chatMessage.state == KUSChatMessageStateFailed) {
        if (_errorButton == nil) {
            _errorButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_errorButton setImage:[KUSImage errorImage] forState:UIControlStateNormal];
            [_errorButton addTarget:self
                             action:@selector(_didTapError)
                   forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:_errorButton];
        }
        _errorButton.hidden = NO;
    } else {
        _errorButton.hidden = YES;
    }

    [self _updateAlphaForState];
    [self setNeedsLayout];
}

- (void)setShowsAvatar:(BOOL)showsAvatar
{
    _showsAvatar = showsAvatar;
    [self setNeedsLayout];
}

#pragma mark - Interface element methods

- (void)_didTapError
{
    if ([self.delegate respondsToSelector:@selector(chatMessageTableViewCellDidTapError:forMessage:)]) {
        [self.delegate chatMessageTableViewCellDidTapError:self forMessage:_chatMessage];
    }
}

#pragma mark - TTTAttributedLabelDelegate methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(chatMessageTableViewCell:didTapLink:)]) {
        [self.delegate chatMessageTableViewCell:self didTapLink:url];
    }
}

#pragma mark - UIGestureRecognizer methods

- (void)_didTapImage
{
    if ([self.delegate respondsToSelector:@selector(chatMessageTableViewCellDidTapImage:forMessage:)]) {
        [self.delegate chatMessageTableViewCellDidTapImage:self forMessage:_chatMessage];
    }
}

@end
