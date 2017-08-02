//
//  KUSSessionsViewController.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSBaseViewController.h"

@class KUSAPIClient;
@interface KUSSessionsViewController : KUSBaseViewController

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient;
- (instancetype)init NS_UNAVAILABLE;

@end
