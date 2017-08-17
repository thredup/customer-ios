//
//  KUSFauxNavigationBar.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSFauxNavigationBar.h"

#import "KUSColor.h"

@interface KUSFauxNavigationBar () {
    UIView *_separatorView;
}

@end

@implementation KUSFauxNavigationBar

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [KUSColor lightGrayColor];

        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [KUSColor grayColor];
        [self addSubview:_separatorView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _separatorView.frame = (CGRect) {
        .origin.y = self.bounds.size.height - 0.5,
        .size.width = self.bounds.size.width,
        .size.height = 0.5
    };
}

@end
