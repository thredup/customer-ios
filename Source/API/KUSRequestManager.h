//
//  KUSRequestManager.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KUSRequestType) {
    KUSRequestTypeGet,
    KUSRequestTypePost,
    KUSRequestTypePatch,
    KUSRequestTypePut,
    KUSRequestTypeDelete
};

extern NSString *const kKustomerCORSHeaderKey;
extern NSString *const kKustomerCORSHeaderValue;
extern NSString *const kKustomerTrackingTokenHeaderKey;

typedef void (^KUSRequestCompletion)(NSError *error, NSDictionary *response);

@class KUSUserSession;
@interface KUSRequestManager : NSObject

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;

// URL methods

- (NSURL *)URLForEndpoint:(NSString *)endpoint;

// Request methods

- (void)getEndpoint:(NSString *)endpoint
      authenticated:(BOOL)authenticated
         completion:(KUSRequestCompletion)completion;

- (void)performRequestType:(KUSRequestType)type
                  endpoint:(NSString *)endpoint
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
                completion:(KUSRequestCompletion)completion;

- (void)performRequestType:(KUSRequestType)type
                       URL:(NSURL *)URL
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
                completion:(KUSRequestCompletion)completion;

- (void)performRequestType:(KUSRequestType)type
                       URL:(NSURL *)URL
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
         additionalHeaders:(NSDictionary *)additionalHeaders
                completion:(KUSRequestCompletion)completion;

- (void)performRequestType:(KUSRequestType)type
                       URL:(NSURL *)URL
                    params:(NSDictionary<NSString *, id> *)params
                  bodyData:(NSData *)bodyData
             authenticated:(BOOL)authenticated
         additionalHeaders:(NSDictionary *)additionalHeaders
                completion:(KUSRequestCompletion)completion;

@end
