//
//  KUSModel.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"

@implementation KUSModel

#pragma mark - Class methods

+ (NSString * _Nullable)modelType
{
    return nil;
}

#pragma mark - Lifecycle methods

- (instancetype _Nullable)initWithJSON:(NSDictionary * _Nonnull)json
{
    // Reject non-dictionary objects
    if (![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    // Reject any objects where the model type doesn't match
    NSString *type = json[@"type"];
    NSString *classType = [[self class] modelType];
    if (![type isEqual:classType]) {
        return nil;
    }

    // Make sure there is an object id
    NSString *objectId = json[@"id"];
    if (objectId == nil) {
        return nil;
    }

    // Actually create the object
    self = [super init];
    if (self) {
        _oid = objectId;

        // Grab relationship identifiers
        _orgId = [json valueForKeyPath:@"relationships.org.data.id"];
        _customerId = [json valueForKeyPath:@"relationships.customer.data.id"];
        _sessionId = [json valueForKeyPath:@"relationships.session.data.id"];
        _sentById = [json valueForKeyPath:@"relationships.sentBy.data.id"];
    }
    return self;
}

@end
