//
//  KUSAvatarImageView.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/15/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSAvatarImageView.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "KUSImage.h"
#import "KUSUserSession.h"

@interface KUSAvatarImageView () <KUSObjectDataSourceListener> {
    __weak KUSUserSession *_userSession;
}

@end

@implementation KUSAvatarImageView

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

        self.contentMode = UIViewContentModeScaleAspectFill;
        self.layer.masksToBounds = YES;
        [self _updateAvatarImage];

        [_userSession.chatSettingsDataSource addListener:self];
    }
    return self;
}

#pragma mark - View methods

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

#pragma mark - Internal methods

- (void)_updateAvatarImage
{
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    NSString *teamName = chatSettings.teamName ?: _userSession.organizationName;
    UIImage *placeholderImage = [KUSImage defaultAvatarImageForName:teamName];
    if (chatSettings.teamIconURL) {
        [self sd_setImageWithURL:chatSettings.teamIconURL
                placeholderImage:placeholderImage
                         options:SDWebImageRefreshCached];
    } else {
        [self setImage:placeholderImage];
    }
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    if (dataSource == _userSession.chatSettingsDataSource) {
        [self _updateAvatarImage];
    }
}

@end
