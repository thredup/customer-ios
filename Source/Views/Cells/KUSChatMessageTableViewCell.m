//
//  KUSChatMessageTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessageTableViewCell.h"

#import "KUSChatMessage.h"
#import "KUSColor.h"
#import "KUSImage.h"
#import "KUSText.h"

static const CGFloat kBubbleTopPadding = 10.0;
static const CGFloat kBubbleSidePadding = 12.0;

static const CGFloat kRowSidePadding = 11.0;
static const CGFloat kRowTopPadding = 3.0;

static const CGFloat kMaxBubbleWidth = 250.0;
static const CGFloat kMinBubbleHeight = 38.0;

@interface KUSChatMessageTableViewCell () {
    KUSChatMessage *_chatMessage;
    BOOL _showsAvatar;

    UIImageView *_imageView;
    UIView *_bubbleView;
    UILabel *_labelView;
}

@end

@implementation KUSChatMessageTableViewCell

#pragma mark - Class methods

+ (CGFloat)heightForChatMessage:(KUSChatMessage *)chatMessage maxWidth:(CGFloat)maxWidth
{
    CGSize boundingSizeForText = [self boundingSizeForText:chatMessage.body maxWidth:maxWidth];
    CGFloat height = boundingSizeForText.height;
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

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.image = [KUSImage kustomerTeamIcon];
        _imageView.layer.masksToBounds = YES;
        [self.contentView addSubview:_imageView];

        _bubbleView = [[UIView alloc] init];
        _bubbleView.layer.masksToBounds = YES;
        [self.contentView addSubview:_bubbleView];

        _labelView = [[UILabel alloc] init];
        _labelView.textAlignment = NSTextAlignmentLeft;
        _labelView.font = [[self class] messageFont];
        _labelView.numberOfLines = 0;
        [_bubbleView addSubview:_labelView];
    }
    return self;
}

#pragma mark - Layout methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    BOOL currentUser = _chatMessage.direction == KUSChatMessageDirectionIn;

    _imageView.hidden = currentUser || !_showsAvatar;
    _imageView.frame = (CGRect) {
        .origin.x = kRowSidePadding,
        .origin.y = (self.contentView.bounds.size.height - 40.0) / 2.0,
        .size.width = 40.0,
        .size.height = 40.0
    };
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2.0;

    CGSize boundingSizeForText = [[self class] boundingSizeForText:_chatMessage.body maxWidth:self.contentView.bounds.size.width];

    CGSize bubbleViewSize = (CGSize) {
        .width = boundingSizeForText.width + kBubbleSidePadding * 2.0,
        .height = self.contentView.bounds.size.height - kRowTopPadding * 2.0
    };

    _bubbleView.frame = (CGRect) {
        .origin.x = currentUser ? self.contentView.bounds.size.width - bubbleViewSize.width - kRowSidePadding : 60.0,
        .origin.y = kRowTopPadding,
        .size = bubbleViewSize
    };
    _bubbleView.layer.cornerRadius = MIN(_bubbleView.frame.size.height / 2.0, 15.0);

    _labelView.frame = (CGRect) {
        .origin.x = (_bubbleView.bounds.size.width - boundingSizeForText.width) / 2.0,
        .origin.y = (_bubbleView.bounds.size.height - boundingSizeForText.height) / 2.0,
        .size = boundingSizeForText
    };
}

#pragma mark - Property methods

- (void)setChatMessage:(KUSChatMessage *)chatMessage
{
    _chatMessage = chatMessage;

    BOOL currentUser = _chatMessage.direction == KUSChatMessageDirectionIn;

    UIColor *bubbleColor = (currentUser ? [KUSColor blueColor] : [KUSColor grayColor]);
    UIColor *textColor = (currentUser ? [UIColor whiteColor] : [UIColor blackColor]);

    _bubbleView.backgroundColor = bubbleColor;
    _labelView.backgroundColor = bubbleColor;
    _labelView.textColor = textColor;

    _labelView.attributedText = [KUSText attributedStringFromText:_chatMessage.body fontSize:[[self class] fontSize]];

    [self setNeedsLayout];
}

- (void)setShowsAvatar:(BOOL)showsAvatar
{
    _showsAvatar = showsAvatar;
    [self setNeedsLayout];
}

@end
