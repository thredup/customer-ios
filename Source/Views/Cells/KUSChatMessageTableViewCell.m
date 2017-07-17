//
//  KUSChatMessageTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessageTableViewCell.h"

#import "KUSChatMessage.h"
#import "KUSImage.h"

static const CGFloat kBubbleTopPadding = 10.0;
static const CGFloat kBubbleSidePadding = 12.0;

static const CGFloat kRowTopPadding = 5.0;

static const CGFloat kMaxBubbleWidth = 250.0;
static const CGFloat kMinBubbleHeight = 38.0;

@interface KUSChatMessageTableViewCell () {
    KUSChatMessage *_chatMessage;
    BOOL _currentUser;

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

+ (UIFont *)messageFont
{
    return [UIFont systemFontOfSize:14.0];
}

+ (CGSize)boundingSizeForText:(NSString *)text maxWidth:(CGFloat)maxWidth
{
    CGFloat actualMaxWidth = MIN(kMaxBubbleWidth - kBubbleSidePadding * 2.0, maxWidth);

    NSDictionary<NSString *, id> *attributes = @{
        NSFontAttributeName: [self messageFont]
    };
    CGSize maxSize = CGSizeMake(actualMaxWidth, 1000.0);
    CGRect boundingRect = [text boundingRectWithSize:maxSize
                                             options:(NSStringDrawingUsesLineFragmentOrigin
                                                      | NSStringDrawingUsesFontLeading)
                                          attributes:attributes
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

    _imageView.hidden = _currentUser;
    _imageView.frame = (CGRect) {
        .origin.x = 15.0,
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
        .origin.x = _currentUser ? self.contentView.bounds.size.width - bubbleViewSize.width - 20.0 : 64.0,
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

- (void)setChatMessage:(KUSChatMessage *)chatMessage currentUser:(BOOL)currentUser
{
    _chatMessage = chatMessage;
    _currentUser = currentUser;

    UIColor *bubbleColor = (_currentUser
                            ? [UIColor colorWithRed:58.0/255.0
                                              green:129.0/255.0
                                               blue:250.0/255.0
                                              alpha:1.0]
                            : [UIColor colorWithWhite:240.0/255.0
                                                alpha:1.0]);
    UIColor *textColor = (_currentUser
                          ? [UIColor whiteColor]
                          : [UIColor blackColor]);

    _bubbleView.backgroundColor = bubbleColor;
    _labelView.backgroundColor = bubbleColor;
    _labelView.textColor = textColor;

    _labelView.text = _chatMessage.body;

    [self setNeedsLayout];
}

@end
