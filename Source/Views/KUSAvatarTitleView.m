//
//  KUSAvatarTitleView.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSAvatarTitleView.h"

#import "KUSImage.h"

@interface KUSAvatarTitleView ()

@property (nonatomic, strong) UIImageView *avatarImageView;

@end

@implementation KUSAvatarTitleView

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarImageView.image = [KUSImage kustomerTeamIcon];
        _avatarImageView.layer.masksToBounds = YES;
        [self addSubview:_avatarImageView];
    }
    return self;
}

#pragma mark - UIView methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat avatarHeight = 30.0;
    self.avatarImageView.frame = (CGRect) {
        .origin.x = (self.bounds.size.width - avatarHeight) / 2.0,
        .origin.y = (self.bounds.size.height - avatarHeight) / 2.0,
        .size.width = avatarHeight,
        .size.height = avatarHeight
    };
    self.avatarImageView.layer.cornerRadius = avatarHeight / 2.0;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeZero;
}

@end
