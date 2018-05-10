//
//  KUSLocalizationManager.m
//  Kustomer
//
//  Created by Hunain Shahid on 03/05/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KUSLocalization.h"
#import "KUSLog.h"

@interface KUSLocalization () 
@end

@implementation KUSLocalization

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static KUSLocalization *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Public methods

- (void)printAllKeys
{
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.kustomer.Kustomer"];
    NSString *path = [bundle pathForResource:@"Localizable" ofType:@"strings"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSUInteger count = 0;
    NSString *keys = @"[";
    for (NSString* key in dictionary.allKeys) {
        keys = [keys stringByAppendingString:[NSString stringWithFormat:@"\"%@\"", key]];
        if (count < [dictionary.allKeys count] - 1) {
            keys = [keys stringByAppendingString:@", "];
        }
        count++;
    }
    keys = [keys stringByAppendingString:@"]"];
    KUSLogInfo(@"Localization Keys: %@", keys);
}

- (void)setLocale:(NSLocale *)locale
{
    _locale = locale;
    
    if ([NSLocale characterDirectionForLanguage:[_locale localeIdentifier]] == NSLocaleLanguageDirectionRightToLeft) {
        [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}

- (void)setTable:(NSString *)table
{
    _table = table;
}

- (NSString *)localizedString:(NSString *)key
{
    NSBundle *bundle = NSBundle.mainBundle;
    if (_locale) {
        bundle = [NSBundle bundleWithPath:[bundle pathForResource:[_locale localeIdentifier] ofType:@"lproj"]];
        bundle = bundle ?: NSBundle.mainBundle;
    }
    
    NSString *value = NSLocalizedStringWithDefaultValue(key, _table, bundle, @"~.~", nil);
    if ([value isEqualToString:@"~.~"]) {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.kustomer.Kustomer"];
        if (_locale) {
            bundle = [NSBundle bundleWithPath:[bundle pathForResource:[_locale localeIdentifier] ofType:@"lproj"]];
            bundle = bundle ?: [NSBundle bundleWithIdentifier:@"com.kustomer.Kustomer"];
        }
        return NSLocalizedStringWithDefaultValue(key, nil, bundle, nil, nil);
    }
    return value;
}

- (BOOL)isCurrentLanguageRTL
{
    if (_locale)
        return ([NSLocale characterDirectionForLanguage:[_locale localeIdentifier]] == NSLocaleLanguageDirectionRightToLeft);
    
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    return ([NSLocale characterDirectionForLanguage:language] == NSLocaleLanguageDirectionRightToLeft);
}

- (NSLocale*)currentLocale
{
    if (_locale)
        return _locale;
    return [NSLocale currentLocale];
}

@end
