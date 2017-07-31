//
//  KUSChatMessageTableViewCell.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSChatMessage;
@interface KUSChatMessageTableViewCell : UITableViewCell

+ (CGFloat)heightForChatMessage:(KUSChatMessage *)chatMessage maxWidth:(CGFloat)maxWidth;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)setChatMessage:(KUSChatMessage *)chatMessage;
- (void)setShowsAvatar:(BOOL)showsAvatar;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end
