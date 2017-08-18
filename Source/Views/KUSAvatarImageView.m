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
#import "KUSUser.h"
#import "KUSUserSession.h"

@interface KUSAvatarImageView () <KUSObjectDataSourceListener> {
    __weak KUSUserSession *_userSession;

    __weak KUSUserDataSource *_userDataSource;
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

        [_userSession.chatSettingsDataSource addListener:self];

        [self _updateAvatarImage];
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

#pragma mark - Property methods

- (void)setUserId:(NSString *)userId
{
    if (_userId == userId || [_userId isEqualToString:userId]) {
        return;
    }
    [_userDataSource removeListener:self];
    _userId = userId;
    _userDataSource = [_userSession userDataSourceForUserId:_userId];
    [_userDataSource addListener:self];
    [self _updateAvatarImage];
}

#pragma mark - Internal methods

- (void)_updateAvatarImage
{
    KUSUser *user = _userDataSource.object;
    if (_userDataSource && user == nil && !_userDataSource.isFetching) {
        [_userDataSource fetch];
    }
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    if (_userSession.chatSettingsDataSource && chatSettings == nil && !_userSession.chatSettingsDataSource.isFetching) {
        [_userSession.chatSettingsDataSource fetch];
    }

    NSString *name = user.displayName ?: chatSettings.teamName ?: _userSession.organizationName;
    NSURL *iconURL = user.avatarURL ?: chatSettings.teamIconURL;

    UIImage *placeholderImage = [KUSImage defaultAvatarImageForName:name];
    if (iconURL) {
        [self sd_setImageWithURL:iconURL
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
    } else if (dataSource == _userDataSource) {
        [self _updateAvatarImage];
    }
}

@end
