//
//  KUSChatViewController.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSBaseViewController.h"

@class KUSAPIClient;
@class KUSChatSession;
@interface KUSChatViewController : KUSBaseViewController

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient forChatSession:(KUSChatSession *)session;
- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient forNewSessionWithBackButton:(BOOL)showBackButton;
- (instancetype)init NS_UNAVAILABLE;

@end
