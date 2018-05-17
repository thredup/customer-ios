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
#import "KUSCustomerDescription.h"

FOUNDATION_EXPORT double KustomerVersionNumber;
FOUNDATION_EXPORT const unsigned char KustomerVersionString[];

@protocol KustomerDelegate;
@interface Kustomer : NSObject

+ (void)initializeWithAPIKey:(NSString *)apiKey;
+ (void)setDelegate:(__weak id<KustomerDelegate>)delegate;

+ (void)describeConversation:(NSDictionary<NSString *, NSObject *> *)customAttributes;
+ (void)describeCustomer:(KUSCustomerDescription *)customerDescription;
+ (void)identify:(NSString *)externalToken;
+ (void)resetTracking;

+ (void)setCurrentPageName:(NSString *)currentPageName;

// Returns the current count of unread messages. It might not be immediately available.
+ (NSUInteger)unreadMessageCount;

// Get status asynchronously about current chat is available or not.
+ (void)isChatAvailable:(void (^)(BOOL success, BOOL enabled))block;

// A convenience method that will present the support interface on the topmost view controller
+ (void)presentSupport;

// A convenience method that will present the knowledgebase interface on the topmost view controller
+ (void)presentKnowledgeBase;

// A convenience method that will present the custom web page interface on the topmost view controller
+ (void)presentCustomWebPage:(NSString*)url;

// The current SDK version
+ (NSString *)sdkVersion;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@protocol KustomerDelegate <NSObject>

@optional

// Implement this method to allow or disallow Kustomer from showing in-app notifications
// (for example if the user is currently viewing a screen that should be un-interrupted)
// If unimplemented, will default to YES
- (BOOL)kustomerShouldDisplayInAppNotification;

// Implement to perform custom handling and presentation of the support user interface
// If unimplemented, Kustomer will present the support interface on the topmost view controller
- (void)kustomerDidTapOnInAppNotification;

@end
