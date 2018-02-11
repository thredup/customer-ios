//
//  KUSClientActivityManager.m
//  Kustomer
//
//  Created by Daniel Amitay on 2/11/18.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSClientActivityManager.h"

@interface KUSClientActivityManager () {
    __weak KUSUserSession *_userSession;
}

@end

@implementation KUSClientActivityManager

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;
    }
    return self;
}

#pragma mark - Public methods

- (void)setCurrentPageName:(NSString *)currentPageName
{
    _currentPageName = [currentPageName copy];
}

@end
