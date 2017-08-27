//
//  KUSChatMessageTableViewCell.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSChatMessage;
@class KUSUserSession;
@protocol KUSChatMessageTableViewCellDelegate;
@interface KUSChatMessageTableViewCell : UITableViewCell

@property (nonatomic, weak) id<KUSChatMessageTableViewCellDelegate> delegate;

+ (CGFloat)heightForChatMessage:(KUSChatMessage *)chatMessage maxWidth:(CGFloat)maxWidth;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier userSession:(KUSUserSession *)userSession;

- (void)setChatMessage:(KUSChatMessage *)chatMessage;
- (void)setShowsAvatar:(BOOL)showsAvatar;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

@protocol KUSChatMessageTableViewCellDelegate <NSObject>

@optional

- (void)chatMessageTableViewCell:(KUSChatMessageTableViewCell *)cell didTapLink:(NSURL *)URL;
- (void)chatMessageTableViewCellDidTapImage:(KUSChatMessageTableViewCell *)cell forMessage:(KUSChatMessage *)message;

@end
