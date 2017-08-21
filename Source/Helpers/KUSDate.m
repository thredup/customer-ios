//
//  KUSDate.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/20/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSDate.h"

const NSTimeInterval kSecondsPerMinute = 60.0;
const NSTimeInterval kMinutesPerHour = 60.0;
const NSTimeInterval kHoursPerDay = 24.0;
const NSTimeInterval kDaysPerWeek = 7.0;

@implementation KUSDate

+ (NSString *)humanReadableTextFromDate:(NSDate *)date
{
    if (date == nil) {
        return nil;
    }

    NSTimeInterval timeAgo = -[date timeIntervalSinceNow];
    if (timeAgo >= kSecondsPerMinute * kMinutesPerHour * kHoursPerDay * kDaysPerWeek) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour * kHoursPerDay * kDaysPerWeek);
        return _AgoTextWithCountAndUnit(count, @"week");
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour * kHoursPerDay) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour * kHoursPerDay);
        return _AgoTextWithCountAndUnit(count, @"day");
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour);
        return _AgoTextWithCountAndUnit(count, @"hour");
    } else if (timeAgo >= kSecondsPerMinute) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute);
        return _AgoTextWithCountAndUnit(count, @"minute");
    } else {
        return @"Just now";
    }
}

static NSString *_AgoTextWithCountAndUnit(NSTimeInterval unitCount, NSString *unit)
{
    int integerUnit = (int)round(unitCount);
    return [NSString stringWithFormat:@"%i %@%@ ago", integerUnit, unit, (integerUnit > 1 ? @"s": @"")];
}

@end
