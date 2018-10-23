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

- (BOOL)isActiveBusinessHours
{
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    if (chatSettings.availability == KUSBusinessHoursAvailabilityOnline) {
        return YES;
    }
    
    KUSSchedule *businessHours = [self object];
    if (businessHours.enabled) {
        // Check that current date is not in holiday date and time
        NSDate *now = [NSDate date];
        for (KUSHoliday *holiday in businessHours.holidays) {
            if (holiday.enabled) {
                NSComparisonResult startDateResult = [now compare:holiday.startDate];
                NSComparisonResult endDateResult = [now compare:holiday.endDate];
                if ((startDateResult == NSOrderedDescending || startDateResult == NSOrderedSame) &&
                    (endDateResult == NSOrderedAscending || startDateResult == NSOrderedSame)) {
                    return NO;
                }
            }
        }
        
        // Get Week Day
        NSCalendar* cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday) fromDate:now];
        NSInteger weekday = [components weekday] - 1; // -1 is to make Sunday '0'
        NSInteger minutes = [components hour] * 60 + [components minute];
        
        NSArray<NSArray<NSNumber *> *> *businessHoursOfCurrentDay = businessHours.hours[[NSString stringWithFormat:@"%ld", (long)weekday]];
        if (businessHoursOfCurrentDay != nil && businessHoursOfCurrentDay != (id)[NSNull null]) {
            NSArray<NSNumber *> *businessHoursRange = [businessHoursOfCurrentDay firstObject];
            if (businessHoursRange && businessHoursRange.count == 2 &&
                [businessHoursRange[0] integerValue] <= minutes && [businessHoursRange[1]  integerValue] >= minutes) {
                return YES;
            }
        }
        return NO;
    }
    return YES;
}

@end
