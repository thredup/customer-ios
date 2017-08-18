//
//  KUSAvatarImageView.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/15/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSUserSession;
@interface KUSAvatarImageView : UIImageView

@property (nonatomic, copy) NSString *userId;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithImage:(UIImage *)image NS_UNAVAILABLE;

@end
