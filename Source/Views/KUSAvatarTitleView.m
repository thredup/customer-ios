//
//  KUSAvatarTitleView.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSAvatarTitleView.h"

#import "KUSAvatarImageView.h"
#import "KUSUserSession.h"

@interface KUSAvatarTitleView ()

@property (nonatomic, strong) KUSAvatarImageView *avatarImageView;

@end

@implementation KUSAvatarTitleView

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:userSession];
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
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeZero;
}

@end
