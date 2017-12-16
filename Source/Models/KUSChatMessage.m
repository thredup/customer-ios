//
//  KUSChatMessage.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessage.h"

#import "KUSUserSession.h"
#import "Kustomer_Private.h"

@implementation KUSChatMessage

static KUSChatMessageDirection KUSChatMessageDirectionFromString(NSString *string)
{
    return [string isEqualToString:@"in"] ? KUSChatMessageDirectionIn : KUSChatMessageDirectionOut;
}

static NSString *KUSUnescapeBackslashesFromString(NSString *string)
{
    NSMutableString *mutableString = [[NSMutableString alloc] init];

    NSUInteger startingIndex = 0;
    for (NSUInteger i = 0; i < string.length; i++) {
        NSString *character = [string substringWithRange:NSMakeRange(i, 1)];
        if ([character isEqualToString:@"\\"]) {
            NSString *lastString = [string substringWithRange:NSMakeRange(startingIndex, i - startingIndex)];
            [mutableString appendString:lastString];

            i++;
            startingIndex = i;
        }
    }

    NSString *endingString = [string substringFromIndex:startingIndex];
    [mutableString appendString:endingString];

    return mutableString;
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
    NSString *imagePattern = @"!\\[.*\\]\\(.*\\)";

    NSMutableArray<KUSChatMessage *> *chatMessages = [[NSMutableArray alloc] init];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:imagePattern options:kNilOptions error:NULL];

    __block NSUInteger lastId = 0;
    __block NSUInteger lastLocation = 0;

    [regex
     enumerateMatchesInString:body
     options:kNilOptions
     range:NSMakeRange(0, body.length)
     usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
         NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
         NSArray<NSTextCheckingResult *> *linkMatches = [detector matchesInString:body
                                                                          options:kNilOptions
                                                                            range:match.range];
         NSTextCheckingResult *linkMatch = linkMatches.firstObject;
         if (linkMatch) {
             NSString *matchedText = KUSUnescapeBackslashesFromString([body substringWithRange:linkMatch.range]);
             NSURL *matchedURL = [NSURL URLWithString:matchedText];
             if (matchedURL) {
                 NSMutableDictionary *mutablePreviousJSON = [json mutableCopy];
                 [mutablePreviousJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, (unsigned long)lastId] forKey:@"id"];
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
                 [mutableImageJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, (unsigned long)lastId] forKey:@"id"];
                 KUSChatMessage *imageMessage = [[KUSChatMessage alloc] initWithJSON:mutableImageJSON
                                                                               type:KUSChatMessageTypeImage
                                                                           imageURL:matchedURL];
                 imageMessage->_body = matchedText;
                 [chatMessages addObject:imageMessage];
                 lastLocation = match.range.location + match.range.length;
             }
         }
     }];

    if (chatMessages.count == 0) {
        [chatMessages addObject:standardChatMessage];
    } else {
        NSMutableDictionary *mutablePreviousJSON = [json mutableCopy];
        [mutablePreviousJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, (unsigned long)lastId] forKey:@"id"];
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

    for (NSString *attachmentId in standardChatMessage.attachmentIds) {
        NSString *imageUrlString = [NSString stringWithFormat:@"https://%@.api.%@/c/v1/chat/messages/%@/attachments/%@?redirect=true",
                                    [Kustomer sharedInstance].userSession.orgName, [Kustomer hostDomain], standardChatMessage.oid, attachmentId];
        NSURL *imageURL = [NSURL URLWithString:imageUrlString];

        NSMutableDictionary *mutableImageJSON = [json mutableCopy];
        [mutableImageJSON setObject:[NSString stringWithFormat:@"%@_%lu", standardChatMessage.oid, (unsigned long)lastId] forKey:@"id"];
        KUSChatMessage *imageMessage = [[KUSChatMessage alloc] initWithJSON:mutableImageJSON
                                                                       type:KUSChatMessageTypeImage
                                                                   imageURL:imageURL];
        imageMessage->_body = NSLocalizedString(@"Attachment", nil);
        [chatMessages addObject:imageMessage];
        lastId++;
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
        _attachmentIds = [json valueForKeyPath:@"relationships.attachments.data.@unionOfObjects.id"];

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
    if (autoreply.length == 0) {
        return nil;
    }
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

- (instancetype)initFailedWithText:(NSString *)text
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
        self->_state = KUSChatMessageStateFailed;
    }
    return self;
}

+ (NSArray<KUSChatMessage *> *)messagesWithSendingText:(NSString *)sendingText
{
    NSDictionary *json = @{
        @"type": @"chat_message",
        @"id": [[NSUUID UUID] UUIDString],
        @"attributes": @{
            @"body": sendingText,
            @"direction": @"in"
        }
    };
    NSArray<KUSChatMessage *> *messages = [self objectsWithJSON:json];
    for (KUSChatMessage *message in messages) {
        message->_state = KUSChatMessageStateSending;
        message->_sendingDate = [NSDate date];
    }
    return messages;
}

#pragma mark - NSObject methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: oid: %@; body: %@>",
            NSStringFromClass([self class]), self, self.oid, self.body];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    KUSChatMessage *chatMessage = (KUSChatMessage *)object;

    if (chatMessage.state != self.state) {
        return NO;
    }
    if (chatMessage.direction != self.direction) {
        return NO;
    }
    if (chatMessage.type != self.type) {
        return NO;
    }
    if ((chatMessage.attachmentIds || self.attachmentIds) && ![chatMessage.attachmentIds isEqual:self.attachmentIds]) {
        return NO;
    }
    if (![chatMessage.oid isEqual:self.oid]) {
        return NO;
    }
    if (![chatMessage.createdAt isEqual:self.createdAt]) {
        return NO;
    }
    if (![chatMessage.body isEqual:self.body]) {
        return NO;
    }

    return YES;
}

@end
