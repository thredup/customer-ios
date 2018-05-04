//
//  KUSLocalizationManager.m
//  Kustomer
//
//  Created by Hunain Shahid on 03/05/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KUSLocalizationManager.h"

@interface KUSLocalizationManager () 
@end

@implementation KUSLocalizationManager

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static KUSLocalizationManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Internal methods

#pragma mark - Internal helper methods

#pragma mark - Public methods

- (void)printAllKeys
{
    // Print all keys used for localization
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Base" ofType:@"lproj"];
    NSURL *url = [[[NSURL alloc] initWithString:path] URLByAppendingPathComponent:@"Localizable.strings"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:url.absoluteString];
    for (NSString* key in dictionary.allKeys)
    {
        NSLog(@"%@", key);
    }
}

- (void)setRegion:(NSString *)region
{
    _region = region;
    if ([NSLocale characterDirectionForLanguage:_region] == NSLocaleLanguageDirectionRightToLeft) {
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
    // Get Localized Key From SDK
    // 1. Check that user has defined that language file or not
    //     Yes -> Find key in that file
    //              Yes  -> return value
    // 2. Check we have that region file
    //     Yes -> Find key in that file
    //              Yes  -> return that value
    // 3. Return key as it is.
    //
    

    NSBundle *bundle = NSBundle.mainBundle;
    if (_region)
    {
        bundle = [NSBundle bundleWithPath:[bundle pathForResource:_region ofType:@"lproj"]];
        bundle = bundle ?: NSBundle.mainBundle;
    }
    
    NSString *value = NSLocalizedStringWithDefaultValue(key, _table, bundle, @"~.~", nil);
    if ([value isEqualToString:@"~.~"])
    {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.kustomer.Kustomer"];
        if (_region)
        {
            bundle = [NSBundle bundleWithPath:[bundle pathForResource:_region ofType:@"lproj"]];
            bundle = bundle ?: [NSBundle bundleWithIdentifier:@"com.kustomer.Kustomer"];
        }
        return NSLocalizedStringWithDefaultValue(key, nil, bundle, nil, nil);
    }
    return value;
}

- (BOOL)isCurrentLanguageRTL
{
    if (_region)
        return ([NSLocale characterDirectionForLanguage:_region] == NSLocaleLanguageDirectionRightToLeft);
    
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    return ([NSLocale characterDirectionForLanguage:language] == NSLocaleLanguageDirectionRightToLeft);
}

- (NSLocale*)currentLocale
{
    if (_region)
        return [[NSLocale alloc] initWithLocaleIdentifier:_region];
    return [NSLocale currentLocale];
}

@end
