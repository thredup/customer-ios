//
//  KUSUserSession.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSUserSession.h"

#import "KUSLog.h"

@interface KUSUserSession ()

@property (nonatomic, copy, readonly) NSString *orgId;
@property (nonatomic, copy, readonly) NSString *orgName;
@property (nonatomic, copy, readonly) NSString *organizationName;  // User-facing (capitalized) version of orgName

// Lazy-loaded methods
@property (nonatomic, strong, null_resettable) KUSChatSessionsDataSource *chatSessionsDataSource;
@property (nonatomic, strong, null_resettable) KUSChatSettingsDataSource *chatSettingsDataSource;
@property (nonatomic, strong, null_resettable) KUSTrackingTokenDataSource *trackingTokenDataSource;

@property (nonatomic, strong, null_resettable) NSMutableDictionary<NSString *, KUSUserDataSource *> *userDataSources;
@property (nonatomic, strong, null_resettable) NSMutableDictionary<NSString *, KUSChatMessagesDataSource *> *chatMessagesDataSources;

@property (nonatomic, strong, null_resettable) KUSRequestManager *requestManager;
@property (nonatomic, strong, null_resettable) KUSPushClient *pushClient;
@property (nonatomic, strong, null_resettable) KUSDelegateProxy *delegateProxy;

@end

@implementation KUSUserSession

#pragma mark - Lifecycle methods

- (instancetype)initWithOrgName:(NSString *)orgName orgId:(NSString *)orgId reset:(BOOL)reset
{
    self = [super init];
    if (self) {
        _orgName = orgName;
        _orgId = orgId;

        if (_orgName.length) {
            NSString *firstLetter = [[_orgName substringToIndex:1] uppercaseString];
            _organizationName = [firstLetter stringByAppendingString:[_orgName substringFromIndex:1]];
        }

        if (reset) {
            [self.trackingTokenDataSource reset];
        }

        [self.chatSettingsDataSource fetch];
        [self pushClient];
    }
    return self;
}

- (instancetype)initWithOrgName:(NSString *)orgName orgId:(NSString *)orgId
{
    return [self initWithOrgName:orgName orgId:orgId reset:NO];
}

#pragma mark - Datasource objects

- (KUSChatSessionsDataSource *)chatSessionsDataSource
{
    if (_chatSessionsDataSource == nil) {
        _chatSessionsDataSource = [[KUSChatSessionsDataSource alloc] initWithUserSession:self];
    }
    return _chatSessionsDataSource;
}

- (KUSChatSettingsDataSource *)chatSettingsDataSource
{
    if (_chatSettingsDataSource == nil) {
        _chatSettingsDataSource = [[KUSChatSettingsDataSource alloc] initWithUserSession:self];
    }
    return _chatSettingsDataSource;
}

- (KUSTrackingTokenDataSource *)trackingTokenDataSource
{
    if (_trackingTokenDataSource == nil) {
        _trackingTokenDataSource = [[KUSTrackingTokenDataSource alloc] initWithUserSession:self];
    }
    return _trackingTokenDataSource;
}

- (NSMutableDictionary<NSString *, KUSUserDataSource *> *)userDataSources
{
    if (_userDataSources == nil) {
        _userDataSources = [[NSMutableDictionary alloc] init];
    }
    return _userDataSources;
}

- (NSMutableDictionary<NSString *, KUSChatMessagesDataSource *> *)chatMessagesDataSources
{
    if (_chatMessagesDataSources == nil) {
        _chatMessagesDataSources = [[NSMutableDictionary alloc] init];
    }
    return _chatMessagesDataSources;
}

- (KUSChatMessagesDataSource *)chatMessagesDataSourceForSessionId:(NSString *)sessionId
{
    if (sessionId.length == 0) {
        return nil;
    }

    KUSChatMessagesDataSource *chatMessagesDataSource = [self.chatMessagesDataSources objectForKey:sessionId];
    if (chatMessagesDataSource == nil) {
        chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithUserSession:self sessionId:sessionId];
        [self.chatMessagesDataSources setObject:chatMessagesDataSource forKey:sessionId];
    }

    return chatMessagesDataSource;
}

- (KUSUserDataSource *)userDataSourceForUserId:(NSString *)userId
{
    if (userId.length == 0 || [userId isEqualToString:@"__team"]) {
        return nil;
    }

    KUSUserDataSource *userDataSource = [self.userDataSources objectForKey:userId];
    if (userDataSource == nil) {
        userDataSource = [[KUSUserDataSource alloc] initWithUserSession:self userId:userId];
        [self.userDataSources setObject:userDataSource forKey:userId];
    }

    return userDataSource;
}

#pragma mark - Request manager & Push client

- (KUSRequestManager *)requestManager
{
    if (_requestManager == nil) {
        _requestManager = [[KUSRequestManager alloc] initWithUserSession:self];
    }
    return _requestManager;
}

- (KUSPushClient *)pushClient
{
    if (_pushClient == nil) {
        _pushClient = [[KUSPushClient alloc] initWithUserSession:self];
    }
    return _pushClient;
}

- (KUSDelegateProxy *)delegateProxy
{
    if (_delegateProxy == nil) {
        _delegateProxy = [[KUSDelegateProxy alloc] init];
    }
    return _delegateProxy;
}

#pragma mark - Email info methods

- (NSString *)_didCaptureEmailKey
{
    KUSTrackingToken *trackingToken = self.trackingTokenDataSource.object;
    if (trackingToken.customerId.length) {
        return [NSString stringWithFormat:@"%@_didCaptureEmail", trackingToken.customerId];
    }
    return nil;
}

- (void)submitEmail:(NSString *)emailAddress
{
    NSString *didCaptureEmailKey = [self _didCaptureEmailKey];
    if (didCaptureEmailKey) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:didCaptureEmailKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    __weak KUSUserSession *weakSelf = self;
    KUSCustomerDescription *customerDescription = [[KUSCustomerDescription alloc] init];
    customerDescription.email = emailAddress;
    [self describeCustomer:customerDescription completion:^(BOOL success, NSError *error) {
        if (error || !success) {
            KUSLogError(@"Error submitting email: %@", error);
            return;
        }
        [weakSelf.trackingTokenDataSource fetch];
    }];
}

- (BOOL)shouldCaptureEmail
{
    KUSTrackingToken *trackingToken = self.trackingTokenDataSource.object;
    if (trackingToken) {
        if (trackingToken.verified) {
            return NO;
        }
        NSString *didCaptureEmailKey = [self _didCaptureEmailKey];
        if (didCaptureEmailKey) {
            return ![[NSUserDefaults standardUserDefaults] boolForKey:didCaptureEmailKey];
        }
    }
    return NO;
}

- (void)describeCustomer:(KUSCustomerDescription *)customerDescription completion:(void(^)(BOOL, NSError *))completion
{
    NSDictionary<NSString *, NSObject *> *formData = [customerDescription formData];
    NSAssert(formData.count, @"Attempted to describe a customer with no attributes set");
    if (formData.count == 0) {
        return;
    }

    [self.requestManager
     performRequestType:KUSRequestTypePatch
     endpoint:@"/c/v1/customers/current"
     params:formData
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (completion) {
             completion(error == nil, error);
         }
     }];
}

@end
