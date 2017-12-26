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

CGFloat KUSChatSessionTableViewCellHeight = 88.0;

@interface KUSChatSessionTableViewCell () <KUSObjectDataSourceListener, KUSChatMessagesDataSourceListener> {
    KUSUserSession *_userSession;

    KUSChatSession *_chatSession;

    KUSChatMessagesDataSource *_chatMessagesDataSource;
    KUSUserDataSource *_userDataSource;
}

@property (nonatomic, strong) KUSAvatarImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *unreadCountLabel;

@end

@implementation KUSChatSessionTableViewCell

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSChatSessionTableViewCell class]) {
        KUSChatSessionTableViewCell *appearance = [KUSChatSessionTableViewCell appearance];
        [appearance setBackgroundColor:[UIColor whiteColor]];
        [appearance setSelectedBackgroundColor:[KUSColor lightGrayColor]];
        [appearance setTitleColor:[UIColor blackColor]];
        [appearance setTitleFont:[UIFont boldSystemFontOfSize:12.0]];
        [appearance setSubtitleColor:[UIColor blackColor]];
        [appearance setSubtitleFont:[UIFont systemFontOfSize:12.0]];
        [appearance setDateColor:[UIColor lightGrayColor]];
        [appearance setDateFont:[UIFont systemFontOfSize:12.0]];
        [appearance setUnreadColor:[UIColor whiteColor]];
        [appearance setUnreadBackgroundColor:[KUSColor redColor]];
        [appearance setUnreadFont:[UIFont systemFontOfSize:10.0]];
    }
}

#pragma mark - Lifecycle methods

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier userSession:(KUSUserSession *)userSession
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _userSession = userSession;

        self.selectedBackgroundView = [[UIView alloc] init];

        _avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:userSession];
        [self.contentView addSubview:_avatarImageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_subtitleLabel];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.adjustsFontSizeToFitWidth = YES;
        _dateLabel.minimumScaleFactor = 10.0 / 12.0;
        [self.contentView addSubview:_dateLabel];

        _unreadCountLabel = [[UILabel alloc] init];
        _unreadCountLabel.textAlignment = NSTextAlignmentCenter;
        _unreadCountLabel.layer.masksToBounds = YES;
        _unreadCountLabel.layer.cornerRadius = 4.0;
        [self.contentView addSubview:_unreadCountLabel];

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
    if (!_chatMessagesDataSource.didFetch && !_chatMessagesDataSource.isFetching) {
        [_chatMessagesDataSource fetchLatest];
    }

    [self _updateAvatar];
    [self _updateLabels];
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
    self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Chat with %@", nil), responderName];

    // Subtitle text (from last message, or preview text)
    KUSChatMessage *latestTextMessage = nil;
    for (KUSChatMessage *message in _chatMessagesDataSource.allObjects) {
        if (message.type == KUSChatMessageTypeText) {
            latestTextMessage = message;
            break;
        }
    }
    NSString *subtitleText = latestTextMessage.body ?: _chatSession.preview;
    self.subtitleLabel.attributedText = [KUSText attributedStringFromText:subtitleText fontSize:12.0];

    // Date text (from last message date, or session created at)
    NSDate *sessionDate = latestTextMessage.createdAt ?: _chatSession.createdAt;
    self.dateLabel.text = [KUSDate humanReadableTextFromDate:sessionDate];

    // Unread count (number of messages > the lastSeenAt)
    NSUInteger unreadCount = [_chatMessagesDataSource unreadCountAfterDate:_chatSession.lastSeenAt];
    if (unreadCount > 0) {
        self.unreadCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)unreadCount];
        self.unreadCountLabel.hidden = NO;
    } else {
        self.unreadCountLabel.hidden = YES;
    }

    [self setNeedsLayout];
}

#pragma mark - Layout methods

- (void)layoutSubviews
{
    [super layoutSubviews];

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

    CGSize unreadSize = [self.unreadCountLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 15.0)];
    unreadSize.height = 15.0;
    unreadSize.width = MAX(ceil(unreadSize.width + 4.0), 15.0);
    self.unreadCountLabel.frame = (CGRect) {
        .origin.x = self.bounds.size.width - rightMargin - unreadSize.width,
        .origin.y = (self.bounds.size.height / 2.0) + 4.0,
        .size = unreadSize
    };

    CGFloat subtitleHeight = ceil(self.subtitleLabel.font.lineHeight);
    self.subtitleLabel.frame = (CGRect) {
        .origin.x = textXOffset,
        .origin.y = (self.bounds.size.height / 2.0) + 4.0,
        .size.width = self.bounds.size.width - textXOffset - rightMargin - (self.unreadCountLabel ? unreadSize.width + 10.0 : 0.0),
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

#pragma mark - Appearance methods

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor
{
    _selectedBackgroundColor = selectedBackgroundColor;
    self.selectedBackgroundView.backgroundColor = _selectedBackgroundColor;
}

- (void)setTitleColor:(UIColor *)titleColor
{
    _titleColor = titleColor;
    _titleLabel.textColor = _titleColor;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    _titleFont = titleFont;
    _titleLabel.font = _titleFont;
}

- (void)setSubtitleColor:(UIColor *)subtitleColor
{
    _subtitleColor = subtitleColor;
    _subtitleLabel.textColor = _subtitleColor;
}

- (void)setSubtitleFont:(UIFont *)subtitleFont
{
    _subtitleFont = subtitleFont;
    _subtitleLabel.font = _subtitleFont;
}

- (void)setDateColor:(UIColor *)dateColor
{
    _dateColor = dateColor;
    _dateLabel.textColor = _dateColor;
}

- (void)setDateFont:(UIFont *)dateFont
{
    _dateFont = dateFont;
    _dateLabel.font = _dateFont;
}

- (void)setUnreadColor:(UIColor *)unreadColor
{
    _unreadColor = unreadColor;
    _unreadCountLabel.textColor = [UIColor whiteColor];
}

- (void)setUnreadBackgroundColor:(UIColor *)unreadBackgroundColor
{
    _unreadBackgroundColor = unreadBackgroundColor;
    _unreadCountLabel.layer.backgroundColor = _unreadBackgroundColor.CGColor;
}

- (void)setUnreadFont:(UIFont *)unreadFont
{
    _unreadFont = unreadFont;
    _unreadCountLabel.font = _unreadFont;
}

@end
