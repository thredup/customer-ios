//
//  KustomerSessionTableViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/3/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerSessionTableViewCell.h"

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
    // TODO: Remove after testing
    NSURL *avatarImageURL = [NSURL URLWithString:@"data:image/png;base64,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"];
    NSData *avatarImageData = [NSData dataWithContentsOfURL:avatarImageURL];
    self.avatarImageView.image = [UIImage imageWithData:avatarImageData];

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
