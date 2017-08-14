//
//  KUSUserSession.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUserSession.h"

@interface KUSUserSession ()

@property (nonatomic, copy, readonly) NSString *orgName;
@property (nonatomic, copy, readonly) NSString *organizationName;  // User-facing (capitalized) version of orgName

@end

@implementation KUSUserSession

#pragma mark - Lifecycle methods

- (instancetype)initWithOrgName:(NSString *)orgName
{
    self = [super init];
    if (self) {
        _orgName = orgName;

        if (_orgName.length) {
            NSString *firstLetter = [[_orgName substringToIndex:1] uppercaseString];
            _organizationName = [firstLetter stringByAppendingString:[_orgName substringFromIndex:1]];
        }
    }
    return self;
}

@end
