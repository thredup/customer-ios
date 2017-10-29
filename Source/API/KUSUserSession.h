//
//  KUSUserSession.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KUSChatMessagesDataSource.h"
#import "KUSChatSessionsDataSource.h"
#import "KUSChatSettingsDataSource.h"
#import "KUSDelegateProxy.h"
#import "KUSPushClient.h"
#import "KUSRequestManager.h"
#import "KUSTrackingTokenDataSource.h"
#import "KUSUserDataSource.h"
#import "KUSCustomerDescription.h"

@interface KUSUserSession : NSObject

- (instancetype)initWithOrgName:(NSString *)orgName orgId:(NSString *)orgId reset:(BOOL)reset NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithOrgName:(NSString *)orgName orgId:(NSString *)orgId;
- (instancetype)init NS_UNAVAILABLE;

// Org methods
- (NSString *)orgId;
- (NSString *)orgName;
- (NSString *)organizationName; // User facing

// Datasource objects
- (KUSChatSessionsDataSource *)chatSessionsDataSource;
- (KUSChatSettingsDataSource *)chatSettingsDataSource;
- (KUSTrackingTokenDataSource *)trackingTokenDataSource;

- (KUSChatMessagesDataSource *)chatMessagesDataSourceForSessionId:(NSString *)sessionId;
- (KUSUserDataSource *)userDataSourceForUserId:(NSString *)userId;

// Request manager & Push client & Delegate proxy
- (KUSRequestManager *)requestManager;
- (KUSPushClient *)pushClient;
- (KUSDelegateProxy *)delegateProxy;

// Email info
- (void)submitEmail:(NSString *)emailAddress;
- (BOOL)shouldCaptureEmail;

- (void)describeCustomer:(KUSCustomerDescription *)customerDescription completion:(void(^)(BOOL, NSError *))completion;

@end
