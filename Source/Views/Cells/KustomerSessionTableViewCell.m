//
//  KustomerSessionTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/3/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerSessionTableViewCell.h"

#import "KUSImage.h"

@interface KustomerSessionTableViewCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@end

@implementation KustomerSessionTableViewCell

#pragma mark - Lifecycle methods

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarImageView.layer.masksToBounds = YES;
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
        _dateLabel.font = [UIFont systemFontOfSize:12.0];
        [self.contentView addSubview:_dateLabel];

        [self _setupMockData];
    }
    return self;
}

- (void)_setupMockData
{
    self.avatarImageView.image = [KUSImage kustomerTeamIcon];
    self.titleLabel.text = @"Chat with Kustomer";
    self.subtitleLabel.text = @"Ignore this but allow the text to overflow so that I can see what it looks like";
    self.dateLabel.text = @"19 hours ago";
}

#pragma mark - UIView methods

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
    self.avatarImageView.layer.cornerRadius = avatarImageSize.width / 2.0;


    CGFloat textXOffset = CGRectGetMaxX(self.avatarImageView.frame) + 8.0;
    CGFloat rightMargin = 20.0;

    CGFloat titleHeight = ceil(self.titleLabel.font.lineHeight);
    self.titleLabel.frame = (CGRect) {
        .origin.x = textXOffset,
        .origin.y = (self.bounds.size.height / 2.0) - titleHeight - 4.0,
        .size.width = self.bounds.size.width - textXOffset - rightMargin - 80,
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
        .origin.x = self.bounds.size.width - rightMargin - 80.0,
        .origin.y = (self.bounds.size.height / 2.0) - dateHeight - 4.0,
        .size.width = 80.0,
        .size.height = dateHeight
    };
}

@end
