//
//  KUSImageAttachmentCollectionViewCell.m
//  Kustomer
//
//  Created by Daniel Amitay on 12/30/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSImageAttachmentCollectionViewCell.h"

#import "KUSColor.h"
#import "KUSImage.h"

static const CGSize kKUSImageAttachmentRemoveButtonSize = { 20.0, 20.0 };

@implementation KUSImageAttachmentCollectionViewCell {
    UIImageView *_imageView;
    UIButton *_removeButton;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.layer.cornerRadius = 10.0;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        self.contentView.layer.borderColor = [[KUSColor grayColor] colorWithAlphaComponent:0.25].CGColor;

        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];

        _removeButton = [[UIButton alloc] init];
        _removeButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        _removeButton.layer.shadowColor = [UIColor blackColor].CGColor;
        _removeButton.layer.shadowRadius = 2.0;
        _removeButton.layer.shadowOpacity = 0.6;
        [_removeButton setImage:[KUSImage checkmarkImage] forState:UIControlStateNormal];
        [_removeButton addTarget:self action:@selector(_onRemovePressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_removeButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _imageView.frame = self.bounds;
    _removeButton.frame = (CGRect) {
        .origin.x = self.bounds.size.width - kKUSImageAttachmentRemoveButtonSize.width,
        .origin.y = 0.0,
        .size = kKUSImageAttachmentRemoveButtonSize
    };
}

#pragma mark - Public methods

- (void)setImage:(UIImage *)image
{
    _image = image;
    [_imageView setImage:image];
}

#pragma mark - Internal methods

- (void)_onRemovePressed:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(imageAttachmentCollectionViewCellDidTapRemove:)]) {
        [self.delegate imageAttachmentCollectionViewCellDidTapRemove:self];
    }
}

@end
