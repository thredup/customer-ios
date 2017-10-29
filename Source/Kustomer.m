//
//  Kustomer.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "Kustomer.h"
#import "Kustomer_Private.h"

#import "KUSLog.h"
#import "KUSUserSession.h"

static NSString *kKustomerOrgIdKey = @"org";
static NSString *kKustomerOrgNameKey = @"orgName";

@interface Kustomer ()

@property (nonatomic, weak) __weak id<KustomerDelegate> delegate;
@property (nonatomic, strong) KUSUserSession *userSession;

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, copy, readwrite) NSString *orgId;
@property (nonatomic, copy, readwrite) NSString *orgName;

@end

@implementation Kustomer

#pragma mark - Class methods

+ (void)initializeWithAPIKey:(NSString *)apiKey
{
    [[self sharedInstance] setApiKey:apiKey];
}

+ (void)setDelegate:(__weak id<KustomerDelegate>)delegate
{
    [[self sharedInstance] setDelegate:delegate];
}

+ (void)describeConversation:(NSDictionary<NSString *, NSObject *> *)customAttributes
{
    [[self sharedInstance] describeConversation:customAttributes];
}

+ (void)describeCustomer:(KUSCustomerDescription *)customerDescription
{
    [[self sharedInstance] describeCustomer:customerDescription];
}

+ (void)identify:(NSString *)externalToken
{
    [[self sharedInstance] identify:externalToken];
}

+ (void)resetTracking
{
    [[self sharedInstance] resetTracking];
}

+ (void)presentSupport
{
    UIViewController *topMostViewController = KUSTopMostViewController();
    if (topMostViewController) {
        KustomerViewController *kustomerViewController = [[KustomerViewController alloc] init];
        [topMostViewController presentViewController:kustomerViewController animated:YES completion:nil];
    } else {
        KUSLogError(@"Could not find view controller to present on top of!");
    }
}

+ (void)presentKnowledgeBase
{
    UIViewController *topMostViewController = KUSTopMostViewController();
    if (topMostViewController) {
        KnowledgeBaseViewController *knowledgeBaseViewController = [[KnowledgeBaseViewController alloc] init];
        [topMostViewController presentViewController:knowledgeBaseViewController animated:YES completion:nil];
    } else {
        KUSLogError(@"Could not find view controller to present on top of!");
    }
}

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static Kustomer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)setApiKey:(NSString *)apiKey
{
    NSAssert(apiKey.length, @"Kustomer requires a valid API key");
    if (apiKey.length == 0) {
        return;
    }

    NSArray<NSString *> *apiKeyParts = [apiKey componentsSeparatedByString:@"."];
    NSAssert(apiKeyParts.count > 2, @"Kustomer API key has unexpected format");
    if (apiKeyParts.count <= 2) {
        return;
    }

    NSString *base64EncodedTokenJson = paddedBase64String(apiKeyParts[1]);
    NSDictionary *tokenPayload = jsonFromBase64EncodedJsonString(base64EncodedTokenJson);

    _apiKey = [apiKey copy];
    self.orgId = tokenPayload[kKustomerOrgIdKey];
    self.orgName = tokenPayload[kKustomerOrgNameKey];
    NSAssert(self.orgName.length > 0, @"Kustomer API key missing expected field: orgName");
    if (self.orgName.length == 0) {
        return;
    }

    KUSLogInfo(@"Kustomer initialized for organization: %@", self.orgName);

    self.userSession = [[KUSUserSession alloc] initWithOrgName:self.orgName orgId:self.orgId];
    [self.userSession.delegateProxy setDelegate:self.delegate];
}

- (void)setDelegate:(__weak id<KustomerDelegate>)delegate
{
    _delegate = delegate;
    [self.userSession.delegateProxy setDelegate:self.delegate];
}

#pragma mark - Private class methods

static NSString *_hostDomainOverride = nil;

+ (NSString *)hostDomain
{
    return _hostDomainOverride ?: @"kustomerapp.com";
}

+ (void)setHostDomain:(NSString *)hostDomain
{
    _hostDomainOverride = [hostDomain copy];
}

static KUSLogOptions _logOptions = KUSLogOptionInfo | KUSLogOptionErrors;

+ (KUSLogOptions)logOptions
{
    return _logOptions;
}

+ (void)setLogOptions:(KUSLogOptions)logOptions
{
    _logOptions = logOptions;
}

#pragma mark - Private methods

- (KUSUserSession *)userSession
{
    NSAssert(_userSession, @"Kustomer needs to be initialized before use");
    return _userSession;
}

#pragma mark - Internal methods

- (void)describeConversation:(NSDictionary<NSString *, NSObject *> *)customAttributes
{
    NSAssert(customAttributes.count, @"Attempted to describe a conversation with no attributes set");
    if (customAttributes.count == 0) {
        return;
    }

    // TODO: Have it wait until there is an active conversation
    NSDictionary<NSString *, NSObject *> *formData = @{ @"custom" : customAttributes };
    NSString *conversationId = nil;
    NSString *endpoint = [NSString stringWithFormat:@"/c/v1/conversations/%@", conversationId];
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePatch
     endpoint:endpoint
     params:formData
     authenticated:YES
     completion:nil];
}

- (void)describeCustomer:(KUSCustomerDescription *)customerDescription
{
    [self.userSession describeCustomer:customerDescription completion:nil];
}

- (void)identify:(NSString *)externalToken
{
    NSAssert(externalToken, @"Kustomer expects externalToken to be non-nil");
    if (externalToken == nil) {
        return;
    }

    __weak KUSUserSession *weakUserSession = self.userSession;
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/identity"
     params:@{ @"externalToken" : externalToken }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         [weakUserSession.trackingTokenDataSource fetch];
     }];
}

- (void)resetTracking
{
    self.userSession = [[KUSUserSession alloc] initWithOrgName:self.orgName orgId:self.orgId reset:YES];
    [self.userSession.delegateProxy setDelegate:self.delegate];
}

#pragma mark - Helper functions

NS_INLINE NSString *paddedBase64String(NSString *base64String) {
    if (base64String.length % 4) {
        NSUInteger paddedLength = base64String.length + (4 - (base64String.length % 4));
        return [base64String stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    }
    return base64String;
}

NS_INLINE NSDictionary *jsonFromBase64EncodedJsonString(NSString *base64EncodedJson) {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64EncodedJson options:kNilOptions];
    return [NSJSONSerialization JSONObjectWithData:decodedData options:kNilOptions error:NULL];
}

NS_INLINE UIViewController *KUSTopMostViewController() {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = keyWindow.rootViewController;
    UIViewController *topMostViewController = rootViewController;
    while (topMostViewController && topMostViewController.presentedViewController) {
        topMostViewController = topMostViewController.presentedViewController;
    }
    return topMostViewController;
}

@end
