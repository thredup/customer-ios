//
//  KUSLocalizationManager.h
//  Kustomer
//
//  Created by Hunain Shahid on 03/05/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUSUserSession;
@interface KUSLocalizationManager : NSObject

@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *table;

+ (instancetype)sharedInstance;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)printAllKeys;
- (NSString *)localizedString:(NSString *)key;
- (BOOL)isCurrentLanguageRTL;
- (NSLocale*)currentLocale;

@end
