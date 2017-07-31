//
//  KUSChatSessionTableViewCell.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/22/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSAPIClient;
@class KUSChatSession;
@interface KUSChatSessionTableViewCell : UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier apiClient:(KUSAPIClient *)apiClient;

- (void)setChatSession:(KUSChatSession *)chatSession;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end
