//
//  KUSFormQuestion.m
//  Kustomer
//
//  Created by Daniel Amitay on 12/19/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSFormQuestion.h"

@implementation KUSFormQuestion

#pragma mark - Class methods

+ (NSString * _Nullable)modelType
{
    return nil;
}

+ (BOOL)enforcesModelType
{
    return NO;
}

#pragma mark - Lifecycle methods

- (instancetype)initWithJSON:(NSDictionary *)json
{
    self = [super initWithJSON:json];
    if (self) {
        _name = NSStringFromKeyPath(json, @"name");
        _prompt = NSStringFromKeyPath(json, @"prompt");
        _skipIfSatisfied = BOOLFromKeyPath(json, @"skipIfSatisfied");
        _type = KUSFormQuestionTypeFromString(NSStringFromKeyPath(json, @"type"));
        _property = KUSFormQuestionPropertyFromString(NSStringFromKeyPath(json, @"property"));
        _values = NSArrayFromKeyPath(json, @"values");
    }
    return self;
}

static KUSFormQuestionType KUSFormQuestionTypeFromString(NSString *string)
{
    if ([string isEqualToString:@"message"]) {
        return KUSFormQuestionTypeMessage;
    } else if ([string isEqualToString:@"property"]) {
        return KUSFormQuestionTypeProperty;
    }
    return KUSFormQuestionTypeUnknown;
}

static KUSFormQuestionProperty KUSFormQuestionPropertyFromString(NSString *string)
{
    if ([string isEqualToString:@"customer_name"]) {
        return KUSFormQuestionPropertyCustomerName;
    } else if ([string isEqualToString:@"customer_email"]) {
        return KUSFormQuestionPropertyCustomerEmail;
    } else if ([string isEqualToString:@"conversation_team"]) {
        return KUSFormQuestionPropertyConversationTeam;
    }
    return KUSFormQuestionPropertyUnknown;
}

@end
