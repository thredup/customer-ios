//
//  KustomerAPI.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/2/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerAPI.h"

#import "Kustomer_Private.h"

static NSString *kKustomerBaseUrlStringFormat = @"https://%@.api.kustomerapp.com/c/v1/";

@interface KustomerAPI () {
    NSURLSession *_urlSession;
}

@property (atomic, copy) NSURL *baseURL;

@end

@implementation KustomerAPI

#pragma mark - Lifecycle methods

+ (instancetype)sharedInstance
{
    static KustomerAPI *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *orgName = [Kustomer sharedInstance].orgName;
        NSString *baseUrlString = [NSString stringWithFormat:kKustomerBaseUrlStringFormat, orgName];
        self.baseURL = [NSURL URLWithString:baseUrlString];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 15.0;
        _urlSession = [NSURLSession sessionWithConfiguration:configuration
                                                    delegate:nil
                                               delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

#pragma mark - Public methods

- (void)getCurrentTokens:(void(^)(NSError *error, NSDictionary *response))completion
{
    NSURL *endpointURL = [NSURL URLWithString:@"tracking/tokens/current" relativeToURL:self.baseURL];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:endpointURL];
    [urlRequest setValue:@"kustomer" forHTTPHeaderField:@"X-Kustomer:"];

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

@end
