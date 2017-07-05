//
//  KUSAPIClient.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSAPIClient.h"

static NSString *kKustomerTrackingTokenHeaderKey = @"x-kustomer-tracking-token";

@interface KUSAPIClient ()

@property (atomic, copy, readonly) NSString *orgName;
@property (atomic, copy, readonly, nullable) NSString *trackingToken;
@property (atomic, copy, readonly) NSString *baseUrlString;
@property (atomic, strong, readonly) NSURLSession *urlSession;

@end

@implementation KUSAPIClient

#pragma mark - Lifecycle methods

- (instancetype)initWithOrgName:(NSString *)orgName
{
    self = [super init];
    if (self) {
        _orgName = orgName;
        _trackingToken = [[NSUserDefaults standardUserDefaults] stringForKey:kKustomerTrackingTokenHeaderKey];

        _baseUrlString = [NSString stringWithFormat:@"https://%@.api.kustomerapp.com/c", _orgName];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [configuration setTimeoutIntervalForRequest:15.0];
        _urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    }
    return self;
}

#pragma mark - Generic methods

- (void)getEndpoint:(NSString *)endpoint completion:(void(^)(NSError *error, NSDictionary *response))completion
{
    NSString *endpointUrlString = [NSString stringWithFormat:@"%@%@", self.baseUrlString, endpoint];
    NSURL *endpointURL = [NSURL URLWithString:endpointUrlString];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:endpointURL];

    [urlRequest setValue:@"kustomer" forHTTPHeaderField:@"X-Kustomer"];
    if (self.trackingToken) {
        [urlRequest setValue:self.trackingToken forHTTPHeaderField:kKustomerTrackingTokenHeaderKey];
    }

    void (^safeComplete)(NSError *, NSDictionary *) = ^void(NSError *error, NSDictionary *response) {
        if (completion) {
            if (error) {
                completion(error, nil);
            } else {
                completion(nil, response);
            }
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

#pragma mark - Specific methods

- (void)getCurrentTrackingToken:(void(^)(NSError *error, KUSTrackingToken *trackingToken))completion
{
    [self getEndpoint:@"/v1/tracking/tokens/current" completion:^(NSError *error, NSDictionary *response) {
        KUSTrackingToken *trackingToken = [[KUSTrackingToken alloc] initWithJSON:response[@"data"]];
        if (trackingToken.token) {
            _trackingToken = trackingToken.token;
            [[NSUserDefaults standardUserDefaults] setObject:_trackingToken forKey:kKustomerTrackingTokenHeaderKey];
        }
        if (completion) {
            completion(error, trackingToken);
        }
    }];
}

- (void)getChatSettings:(void(^)(NSError *error, KUSChatSettings *chatSettings))completion
{
    [self getEndpoint:@"/v1/chat/settings" completion:^(NSError *error, NSDictionary *response) {
        KUSChatSettings *chatSettings = [[KUSChatSettings alloc] initWithJSON:response[@"data"]];
        if (completion) {
            completion(error, chatSettings);
        }
    }];
}

- (void)getChatSessions:(void(^)(NSError *error, NSArray<KUSChatSession *> *chatSessions))completion
{
    [self getEndpoint:@"/v1/chat/sessions" completion:^(NSError *error, NSDictionary *response) {
        // TODO:
    }];
}

@end
