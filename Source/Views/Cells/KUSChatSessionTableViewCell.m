//
//  KUSChatSessionTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatSessionTableViewCell.h"

#import "KUSChatSession.h"
#import "KUSColor.h"
#import "KUSDate.h"
#import "KUSText.h"
#import "KUSUserSession.h"

#import "KUSAvatarImageView.h"
#import "KUSChatSettingsDataSource.h"

@interface KUSChatSessionTableViewCell () <KUSObjectDataSourceListener, KUSPaginatedDataSourceListener> {
    KUSUserSession *_userSession;

    KUSChatSession *_chatSession;

    KUSChatMessagesDataSource *_chatMessagesDataSource;
    KUSUserDataSource *_userDataSource;
}

@property (nonatomic, strong) KUSAvatarImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@end

@implementation KUSChatSessionTableViewCell

#pragma mark - Lifecycle methods

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier userSession:(KUSUserSession *)userSession
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _userSession = userSession;

        self.selectedBackgroundView = [[UIView alloc] init];
        self.selectedBackgroundView.backgroundColor = [KUSColor lightGrayColor];

        _avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:userSession];
        [self.contentView addSubview:_avatarImageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor whiteColor];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.backgroundColor = [UIColor whiteColor];
        _subtitleLabel.textColor = [UIColor blackColor];
        _subtitleLabel.textAlignment = NSTextAlignmentLeft;
        _subtitleLabel.font = [UIFont systemFontOfSize:12.0];
        [self.contentView addSubview:_subtitleLabel];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.backgroundColor = [UIColor whiteColor];
        _dateLabel.textColor = [UIColor lightGrayColor];
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.font = [UIFont systemFontOfSize:11.0];
        _dateLabel.adjustsFontSizeToFitWidth = YES;
        _dateLabel.minimumScaleFactor = 10.0 / 11.0;
        [self.contentView addSubview:_dateLabel];

        [_userSession.chatSettingsDataSource addListener:self];
    }
    return self;
}


#pragma mark - Property methods

- (void)setChatSession:(KUSChatSession *)chatSession
{
    _chatSession = chatSession;

    _chatMessagesDataSource = [_userSession chatMessagesDataSourceForSessionId:_chatSession.oid];
    [_chatMessagesDataSource addListener:self];

    [self _updateAvatar];
    [self _updateLabels];

    [self setNeedsLayout];
}

#pragma mark - Internal methods

- (void)_updateAvatar
{
    [self.avatarImageView setUserId:_chatMessagesDataSource.firstOtherUserId];
}

- (void)_updateLabels
{
    [_userDataSource removeListener:self];
    _userDataSource = [_userSession userDataSourceForUserId:_chatMessagesDataSource.firstOtherUserId];
    [_userDataSource addListener:self];

    // Title text (from last responder, chat settings, or organization name)
    KUSUser *firstOtherUser = _userDataSource.object;
    NSString *responderName = firstOtherUser.displayName;
    if (responderName.length == 0) {
        KUSChatSettings *chatSettings = [_userSession.chatSettingsDataSource object];
        responderName = chatSettings.teamName.length ? chatSettings.teamName : _userSession.organizationName;
    }
    self.titleLabel.text = [NSString stringWithFormat:@"Chat with %@", responderName];

    // Subtitle text (from last message, or preview text)
    KUSChatMessage *latestMessage = _chatMessagesDataSource.firstObject;
    NSString *subtitleText = latestMessage.body ?: _chatSession.preview;
    self.subtitleLabel.attributedText = [KUSText attributedStringFromText:subtitleText fontSize:12.0];

    // Date text (from last message date, or session created at)
    NSDate *sessionDate = latestMessage.createdAt ?: _chatSession.createdAt;
    self.dateLabel.text = [KUSDate humanReadableTextFromDate:sessionDate];
}

#pragma mark - Layout methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    // TODO: Extract layout constants
    CGSize avatarImageSize = CGSizeMake(40.0, 40.0);
    self.avatarImageView.frame = (CGRect) {
        .origin.x = 16.0,
        .origin.y = (self.bounds.size.height - avatarImageSize.height) / 2.0,
        .size = avatarImageSize
    };

    CGFloat textXOffset = CGRectGetMaxX(self.avatarImageView.frame) + 8.0;
    CGFloat rightMargin = 20.0;

    CGFloat titleHeight = ceil(self.titleLabel.font.lineHeight);
    self.titleLabel.frame = (CGRect) {
        .origin.x = textXOffset,
        .origin.y = (self.bounds.size.height / 2.0) - titleHeight - 4.0,
        .size.width = self.bounds.size.width - textXOffset - rightMargin - 90.0,
        .size.height = titleHeight
    };

    CGFloat subtitleHeight = ceil(self.subtitleLabel.font.lineHeight);
    self.subtitleLabel.frame = (CGRect) {
        .origin.x = textXOffset,
        .origin.y = (self.bounds.size.height / 2.0) + 4.0,
        .size.width = self.bounds.size.width - textXOffset - rightMargin,
        .size.height = subtitleHeight
    };

    CGFloat dateHeight = ceil(self.dateLabel.font.lineHeight);
    self.dateLabel.frame = (CGRect) {
        .origin.x = self.bounds.size.width - rightMargin - 90.0,
        .origin.y = (self.bounds.size.height / 2.0) - dateHeight - 4.0,
        .size.width = 90.0,
        .size.height = dateHeight
    };
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _updateLabels];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    [self _updateLabels];
    [self _updateAvatar];
}

@end
