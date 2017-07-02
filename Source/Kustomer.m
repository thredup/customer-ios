//
//  Kustomer.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/1/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "Kustomer.h"
#import "Kustomer_Private.h"

#import "KustomerAPI.h"

static NSString *kKustomerOrgIdKey = @"org";
static NSString *kKustomerOrgNameKey = @"orgName";

@interface Kustomer ()

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, copy, readwrite) NSString *orgId;
@property (nonatomic, copy, readwrite) NSString *orgName;

@end

@implementation Kustomer

#pragma mark - Class methods

+ (void)initializeWithAPIKey:(NSString *)apiKey
{
    // TODO: Add an assert on existence of api key

    NSArray<NSString *> *apiKeyParts = [apiKey componentsSeparatedByString:@"."];
    // TODO: Add an assert on number of api key parts

    NSString *base64EncodedTokenJson = paddedBase64String(apiKeyParts[1]);
    NSDictionary *tokenPayload = jsonFromBase64EncodedJsonString(base64EncodedTokenJson);

    // TODO: Add an assert on the existence of orgId and orgName
    [[self sharedInstance] setApiKey:apiKey];
    [[self sharedInstance] setOrgId:tokenPayload[kKustomerOrgIdKey]];
    [[self sharedInstance] setOrgName:tokenPayload[kKustomerOrgNameKey]];

    [[KustomerAPI sharedInstance] getCurrentTokens:^(NSError *error, NSDictionary *response) {
        if (error) {
            NSLog(@"error: %@", error);
            return;
        }

        NSString *trackingId = [response valueForKeyPath:@"data.attributes.trackingId"];
        NSString *trackingToken = [response valueForKeyPath:@"data.attributes.token"];
        NSString *customerId = [response valueForKeyPath:@"data.relationships.customer.data.id"];
        BOOL customerVerified = [[response valueForKeyPath:@"data.attributes.verified"] boolValue];

        NSLog(@"trackingId: %@", trackingId);
        NSLog(@"trackingToken: %@", trackingToken);
        NSLog(@"customerId: %@", customerId);
    }];
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

#pragma mark - Helper functions

static NSString *paddedBase64String(NSString *base64String) {
    NSUInteger paddedLength = base64String.length + (4 - (base64String.length % 4));
    return [base64String stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
}

static NSDictionary *jsonFromBase64EncodedJsonString(NSString *base64EncodedJson) {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64EncodedJson options:kNilOptions];
    return [NSJSONSerialization JSONObjectWithData:decodedData options:kNilOptions error:NULL];
}

@end
