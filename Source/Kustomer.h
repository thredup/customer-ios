//
//  Kustomer.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KnowledgeBaseViewController.h"
#import "KustomerViewController.h"

FOUNDATION_EXPORT double KustomerVersionNumber;
FOUNDATION_EXPORT const unsigned char KustomerVersionString[];

@interface Kustomer : NSObject

+ (void)initializeWithAPIKey:(NSString *)apiKey;
+ (void)describe:(NSDictionary<NSString *, NSString *> *)data;
+ (void)identify:(NSString *)externalToken;
+ (void)resetTracking;

+ (void)presentSupportWindow;
+ (void)presentSupportWindowFromPoint:(CGPoint)point;
+ (void)hideSupportWindow;

- (instancetype)init NS_UNAVAILABLE;

@end
