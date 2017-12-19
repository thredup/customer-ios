//
//  KUSChatMessage.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSModel.h"
#import "KUSChatAttachment.h"

typedef NS_ENUM(NSInteger, KUSChatMessageDirection) {
    KUSChatMessageDirectionIn,
    KUSChatMessageDirectionOut
};

typedef NS_ENUM(NSInteger, KUSChatMessageType) {
    KUSChatMessageTypeText,
    KUSChatMessageTypeImage
};

typedef NS_ENUM(NSInteger, KUSChatMessageState) {
    KUSChatMessageStateSent,
    KUSChatMessageStateSending,
    KUSChatMessageStateFailed
};

@interface KUSChatMessage : KUSModel

@property (nonatomic, copy, readonly) NSString *trackingId;
@property (nonatomic, copy, readonly) NSString *body;
@property (nonatomic, copy, readonly) NSURL *imageURL;  // Only if type is Image
@property (nonatomic, copy, readonly) NSArray<NSString *> *attachmentIds;

@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, assign, readonly) KUSChatMessageDirection direction;

@property (nonatomic, assign, readonly) KUSChatMessageType type;
@property (nonatomic, assign, readwrite) KUSChatMessageState state;

+ (NSURL *)attachmentURLForMessageId:(NSString *)messageId attachmentId:(NSString *)attachmentId;

@end
