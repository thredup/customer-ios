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
        return _AgoTextWithCountAndUnit(count, NSLocalizedString(@"week", nil));
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour * kHoursPerDay) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour * kHoursPerDay);
        return _AgoTextWithCountAndUnit(count, NSLocalizedString(@"day", nil));
    } else if (timeAgo >= kSecondsPerMinute * kMinutesPerHour) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute * kMinutesPerHour);
        return _AgoTextWithCountAndUnit(count, NSLocalizedString(@"hour", nil));
    } else if (timeAgo >= kSecondsPerMinute) {
        NSTimeInterval count = timeAgo / (kSecondsPerMinute);
        return _AgoTextWithCountAndUnit(count, NSLocalizedString(@"minute", nil));
    } else {
        return NSLocalizedString(@"Just now", nil);
    }
}

+ (NSString *)messageTimestampTextFromDate:(NSDate *)date
{
    return [_ShortRelativeDateFormatter() stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)string
{
    return (string.length ? [_ISO8601DateFormatterFromString() dateFromString:string] : nil);
}

+ (NSString *)stringFromDate:(NSDate *)date
{
    return (date ? [_ISO8601DateFormatterFromDate() stringFromDate:date] : nil);
}

#pragma mark - Helper logic

static NSDateFormatter *_ShortRelativeDateFormatter(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.doesRelativeDateFormatting = YES;
    });
    return _dateFormatter;
}

static NSString *_AgoTextWithCountAndUnit(NSTimeInterval unitCount, NSString *unit)
{
    int integerUnit = (int)round(unitCount);
    return [NSString stringWithFormat:@"%i %@%@ ago", integerUnit, unit, (integerUnit > 1 ? @"s": @"")];
}

static NSDateFormatter *_ISO8601DateFormatterFromDate(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    return _dateFormatter;
}

static NSDateFormatter *_ISO8601DateFormatterFromString(void)
{
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return _dateFormatter;
}

@end
