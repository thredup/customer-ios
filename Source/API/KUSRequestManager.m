//
//  KUSRequestManager.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/13/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSRequestManager.h"

#import "KUSUserSession.h"

@interface KUSRequestManager () {
    __weak KUSUserSession *_userSession;
}

@property (nonatomic, strong, readonly) NSString *baseUrlString;
@property (nonatomic, strong, readonly) NSURLSession *urlSession;

@end

@implementation KUSRequestManager

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;

        _baseUrlString = KUSBaseUrlStringFromOrgName(_userSession.orgName);

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [configuration setTimeoutIntervalForRequest:15.0];
        _urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    }
    return self;
}

#pragma mark - URL methods

- (NSURL *)URLForEndpoint:(NSString *)endpoint
{
    NSString *endpointUrlString = [NSString stringWithFormat:@"%@%@", self.baseUrlString, endpoint];
    return [NSURL URLWithString:endpointUrlString];
}

#pragma mark - Request methods

- (void)getEndpoint:(NSString *)endpoint
      authenticated:(BOOL)authenticated
         completion:(KUSRequestCompletion)completion
{
    [self performRequestType:KUSRequestTypeGet
                    endpoint:endpoint
                      params:nil
               authenticated:authenticated
                  completion:completion];
}

- (void)performRequestType:(KUSRequestType)type
                  endpoint:(NSString *)endpoint
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
                completion:(KUSRequestCompletion)completion
{
    [self performRequestType:type
                         URL:[self URLForEndpoint:endpoint]
                      params:params
               authenticated:authenticated
                  completion:completion];
}

- (void)performRequestType:(KUSRequestType)type
                       URL:(NSURL *)URL
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
                completion:(KUSRequestCompletion)completion
{
    [self performRequestType:type
                         URL:URL
                      params:params
               authenticated:authenticated
           additionalHeaders:nil
                  completion:completion];
}

- (void)performRequestType:(KUSRequestType)type
                       URL:(NSURL *)URL
                    params:(NSDictionary<NSString *, id> *)params
             authenticated:(BOOL)authenticated
         additionalHeaders:(NSDictionary *)additionalHeaders
                completion:(KUSRequestCompletion)completion
{
    if (type == KUSRequestTypeGet) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        NSMutableArray<NSURLQueryItem *> *queryItems = [[NSMutableArray alloc] initWithCapacity:params.count];
        for (NSString *key in params) {
            id value = params[key];
            NSString *valueString = nil;
            if ([value isKindOfClass:[NSString class]]) {
                valueString = (NSString *)value;
            } else {
                valueString = [NSString stringWithFormat:@"%@", value];
            }
            NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:valueString];
            [queryItems addObject:queryItem];
        }
        urlComponents.queryItems = queryItems;
        URL = urlComponents.URL;
    }

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:URL];
    [urlRequest setHTTPMethod:KUSRequestTypeToString(type)];

    if (params && type != KUSRequestTypeGet) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:NULL];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)jsonData.length];
        [urlRequest setValue:contentLength forHTTPHeaderField:@"Content-Length"];
        [urlRequest setHTTPBody:jsonData];
    }

    [urlRequest setValue:@"kustomer" forHTTPHeaderField:@"X-Kustomer"];

    /*
    if (authenticated && self.trackingToken) {
        [urlRequest setValue:self.trackingToken forHTTPHeaderField:kKustomerTrackingTokenHeaderKey];
    }
    */

    void (^safeComplete)(NSError *, NSDictionary *) = ^void(NSError *error, NSDictionary *response) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    completion(error, nil);
                } else {
                    completion(nil, response);
                }
            });
        }
    };
    void (^responseBlock)(NSData *, NSURLResponse *, NSError *) = ^void(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            safeComplete(error, nil);
            return;
        }
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        safeComplete(jsonError, json);
    };
    NSURLSessionDataTask *dataTask = [_urlSession dataTaskWithRequest:urlRequest completionHandler:responseBlock];
    [dataTask resume];
}

#pragma mark - Helper methods

static NSString *KUSRequestTypeToString(KUSRequestType type)
{
    switch (type) {
        case KUSRequestTypeGet:
            return @"GET";
        case KUSRequestTypePost:
            return @"POST";
        case KUSRequestTypePatch:
            return @"PATCH";
        case KUSRequestTypePut:
            return @"PUT";
        case KUSRequestTypeDelete:
            return @"DELETE";
    }
}

static NSString *KUSBaseUrlStringFromOrgName(NSString *orgName)
{
    NSDictionary<NSString *, NSString *> *environment = [[NSProcessInfo processInfo] environment];
    NSString *baseDomain = environment[@"KUSTOMER_BASE_DOMAIN"] ?: @"kustomerapp.com";
    return [NSString stringWithFormat:@"https://%@.api.%@", orgName, baseDomain];
}

@end
