//
//  KUSBusinessHoursDataSource.m
//  Kustomer
//
//  Created by Hunain Shahid on 15/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSScheduleDataSource.h"
#import "KUSObjectDataSource_Private.h"

@implementation KUSScheduleDataSource

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession userId:(NSString *)userId
{
    self = [super initWithUserSession:userSession];
    if (self) {
    }
    return self;
}

#pragma mark - KUSObjectDataSource subclass methods

- (void)performRequestWithCompletion:(KUSRequestCompletion)completion
{
    NSString *endpoint = [NSString stringWithFormat:@"/c/v1/schedules/default?include=holidays"];
    [self.userSession.requestManager getEndpoint:endpoint
                                   authenticated:YES
                                      completion:completion];
}

- (Class)modelClass
{
    return [KUSSchedule class];
}

@end
