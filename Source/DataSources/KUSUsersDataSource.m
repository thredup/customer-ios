//
//  KUSUsersDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/18/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUsersDataSource.h"

#import "KUSUserSession.h"

@interface KUSUsersDataSource () {
    __weak KUSUserSession *_userSession;

    NSMutableDictionary<NSString *, KUSUserDataSource *> *_userDataSourcesByUserId;
}

@end

@implementation KUSUsersDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

        _userDataSourcesByUserId = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public methods

- (KUSUserDataSource *)userDataSourceForUserId:(NSString *)userId
{
    if (userId.length == 0 || [userId isEqualToString:@"__team"]) {
        return nil;
    }

    KUSUserDataSource *userDataSource = [_userDataSourcesByUserId objectForKey:userId];
    if (userDataSource == nil) {
        userDataSource = [[KUSUserDataSource alloc] initWithUserSession:_userSession userId:userId];
        [_userDataSourcesByUserId setObject:userDataSource forKey:userId];
    }

    return userDataSource;
}

@end
