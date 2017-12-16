//
//  KUSModel.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"

#import "KUSDate.h"

@implementation KUSModel

#pragma mark - Class methods

+ (NSString * _Nullable)modelType
{
    return nil;
}

#pragma mark - Lifecycle methods

+ (NSArray<__kindof KUSModel *> *_Nullable)objectsWithJSON:(NSDictionary * _Nonnull)json
{
    KUSModel *model = [[self alloc] initWithJSON:json];
    return (model ? @[ model ] : nil);
}

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
        _orgId = NSStringFromKeyPath(json, @"relationships.org.data.id");
        _customerId = NSStringFromKeyPath(json, @"relationships.customer.data.id");
        _sessionId = NSStringFromKeyPath(json, @"relationships.session.data.id");
        _sentById = NSStringFromKeyPath(json, @"relationships.sentBy.data.id");
    }
    return self;
}

#pragma mark - NSObject methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: oid: %@>",
            NSStringFromClass([self class]), self, self.oid];
}

- (NSUInteger)hash
{
    return [self.oid hash];
}

#pragma mark - Helper methods

NSURL *_Nullable NSURLFromKeyPath(NSDictionary * _Nullable dict, NSString * _Nonnull keyPath)
{
    NSString *value = NSStringFromKeyPath(dict, keyPath);
    return value ? [NSURL URLWithString:value] : nil;
}

NSString *_Nullable NSStringFromKeyPath(NSDictionary * _Nullable dict, NSString * _Nonnull keyPath)
{
    NSString *value = [dict valueForKeyPath:keyPath];
    return ([value isKindOfClass:[NSString class]] ? value : nil);
}

BOOL BOOLFromKeyPath(NSDictionary * _Nullable dict, NSString * _Nonnull keyPath)
{
    id value = [dict valueForKeyPath:keyPath];
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return NO;
}

NSInteger IntegerFromKeyPath(NSDictionary * _Nullable dict, NSString * _Nonnull keyPath)
{
    id value = [dict valueForKeyPath:keyPath];
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return 0;
}

NSDate *DateFromKeyPath(NSDictionary * _Nullable dict, NSString * _Nonnull keyPath)
{
    NSString *value = NSStringFromKeyPath(dict, keyPath);
    return (value ? [KUSDate dateFromString:value] : nil);
}

@end
