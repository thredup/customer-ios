//
//  KUSChatMessage.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessage.h"

@implementation KUSChatMessage

static KUSChatMessageDirection KUSChatMessageDirectionFromString(NSString *string)
{
    return [string isEqualToString:@"in"] ? KUSChatMessageDirectionIn : KUSChatMessageDirectionOut;
}

#pragma mark - Class methods

+ (NSString *)modelType
{
    return @"chat_message";
}

#pragma mark - Lifecycle methods

+ (NSArray<__kindof KUSModel *> *_Nullable)objectsWithJSON:(NSDictionary * _Nonnull)json
{
    KUSChatMessage *standardChatMessage = [[KUSChatMessage alloc] initWithJSON:json];
    if (standardChatMessage == nil) {
        return @[];
    }

    NSString *body = standardChatMessage.body;

    // The markdown url pattern we want to detect
    // NSString *imagePattern = @"!\\[.*\\]\\(.*\\)";   // Original regex
    NSString *imagePattern = @"!\\[.*\\]\\((.*)\\)";

    NSMutableArray<KUSChatMessage *> *chatMessages = [[NSMutableArray alloc] init];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:imagePattern options:kNilOptions error:NULL];

    __block NSUInteger lastId = 0;
    __block NSUInteger lastLocation = 0;
    [regex
     enumerateMatchesInString:body
     options:kNilOptions
     range:NSMakeRange(0, body.length)
     usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
         if ([match numberOfRanges] != 2) {
             return;
         }

         NSRange linkRange = [match rangeAtIndex:1];
         NSString *linkText = [body substringWithRange:linkRange];
         NSURL *linkURL = [NSURL URLWithString:linkText];
         if (linkURL) {
             NSMutableDictionary *mutablePreviousJSON = [json mutableCopy];
             [mutablePreviousJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, lastId] forKey:@"id"];
             NSString *previousText = [body substringWithRange:NSMakeRange(lastLocation, match.range.location - lastLocation)];
             previousText = [previousText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             if (previousText.length) {
                 KUSChatMessage *previousChatMessage = [[KUSChatMessage alloc] initWithJSON:mutablePreviousJSON];
                 if (previousChatMessage) {
                     previousChatMessage->_body = previousText;
                     [chatMessages addObject:previousChatMessage];
                     lastId++;
                 }
             }

             NSMutableDictionary *mutableImageJSON = [json mutableCopy];
             [mutableImageJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, lastId] forKey:@"id"];
             KUSChatMessage *imageMessage = [[KUSChatMessage alloc] initWithJSON:mutableImageJSON
                                                                            type:KUSChatMessageTypeImage
                                                                        imageURL:linkURL];
             imageMessage->_body = linkText;
             [chatMessages addObject:imageMessage];
             lastLocation = match.range.location + match.range.length;
         }
     }];
    if (chatMessages.count == 0) {
        [chatMessages addObject:standardChatMessage];
    } else {
        NSMutableDictionary *mutablePreviousJSON = [json mutableCopy];
        [mutablePreviousJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, lastId] forKey:@"id"];
        NSString *previousText = [body substringWithRange:NSMakeRange(lastLocation, body.length - lastLocation)];
        previousText = [previousText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (previousText.length) {
            KUSChatMessage *previousChatMessage = [[KUSChatMessage alloc] initWithJSON:mutablePreviousJSON];
            if (previousChatMessage) {
                previousChatMessage->_body = previousText;
                [chatMessages addObject:previousChatMessage];
                lastId++;
            }
        }
    }
    return chatMessages;
}

- (instancetype)initWithJSON:(NSDictionary *)json type:(KUSChatMessageType)type imageURL:(NSURL *)URL
{
    self = [super initWithJSON:json];
    if (self) {
        _trackingId = NSStringFromKeyPath(json, @"attributes.trackingId");
        _body = NSStringFromKeyPath(json, @"attributes.body");
        _type = type;
        _imageURL = URL;

        _createdAt = DateFromKeyPath(json, @"attributes.createdAt");
        _direction = KUSChatMessageDirectionFromString(NSStringFromKeyPath(json, @"attributes.direction"));
    }
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)json
{
    return [self initWithJSON:json type:KUSChatMessageTypeText imageURL:nil];
}

- (instancetype)initWithAutoreply:(NSString *)autoreply
{
    NSDictionary *json = @{
        @"type": @"chat_message",
        @"id": @"__autoreply",
        @"attributes": @{
            @"body": autoreply,
            @"direction": @"out"
        }
    };
    return [self initWithJSON:json];
}

- (instancetype)initPlaceholderWithText:(NSString *)text
{
    NSDictionary *json = @{
        @"type": @"chat_message",
        @"id": [[NSUUID UUID] UUIDString],
        @"attributes": @{
            @"body": text,
            @"direction": @"in"
        }
    };
    self = [self initWithJSON:json];
    if (self) {
        self->_placeholder = YES;
        self->_placeholderDate = [NSDate date];
    }
    return self;
}

#pragma mark - NSObject methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: oid: %@; body: %@>",
            NSStringFromClass([self class]), self, self.oid, self.body];
}

@end
