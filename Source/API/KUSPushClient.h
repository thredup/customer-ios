//
//  KUSPushClient.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUSUserSession;
@interface KUSPushClient : NSObject

@property (nonatomic, assign) BOOL supportViewControllerPresented;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;

@end
