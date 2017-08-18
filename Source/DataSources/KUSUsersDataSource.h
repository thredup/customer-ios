//
//  KUSUsersDataSource.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/18/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KUSUserDataSource.h"

@class KUSUserSession;
@interface KUSUsersDataSource : NSObject

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;

- (KUSUserDataSource *)userDataSourceForUserId:(NSString *)userId;

@end
