//
//  KUSChatMessagesDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessagesDataSource.h"

#import "KUSLog.h"
#import "KUSPaginatedDataSource_Private.h"
#import "KUSUserSession_Private.h"
#import "KUSDate.h"

#import <SDWebImage/SDImageCache.h>

@interface KUSChatMessagesDataSource () {
    NSString *_sessionId;
    BOOL _createdLocally;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)initForNewConversationWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _createdLocally = YES;
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession sessionId:(NSString *)sessionId;
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _sessionId = sessionId;
    }
    return self;
}

#pragma mark - KUSPaginatedDataSource methods

- (void)addListener:(id<KUSChatMessagesDataSourceListener>)listener
{
    [super addListener:listener];
}

- (NSURL *)firstURL
{
    if (_sessionId) {
        NSString *endpoint = [NSString stringWithFormat:@"/c/v1/chat/sessions/%@/messages", _sessionId];
        return [self.userSession.requestManager URLForEndpoint:endpoint];
    }
    return nil;
}

- (Class)modelClass
{
    return [KUSChatMessage class];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors
{
    return @[
        [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO],
        [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:NO]
    ];
}

- (BOOL)didFetch
{
    if (_createdLocally) {
        return YES;
    }
    return [super didFetch];
}

- (BOOL)didFetchAll
{
    if (_createdLocally) {
        return YES;
    }
    return [super didFetchAll];
}

#pragma mark - Public methods

- (NSString *)firstOtherUserId
{
    for (KUSChatMessage *message in self.allObjects) {
        BOOL currentUser = message.direction == KUSChatMessageDirectionIn;
        if (!currentUser) {
            return message.sentById;
        }
    }
    return nil;
}

- (NSUInteger)unreadCountAfterDate:(NSDate *)date
{
    NSUInteger count = 0;
    for (KUSChatMessage *message in self.allObjects) {
        BOOL currentUser = message.direction == KUSChatMessageDirectionIn;
        if (currentUser) {
            return count;
        }
        if (message.createdAt) {
            if ([message.createdAt compare:date] == NSOrderedAscending) {
                return count;
            }
            count++;
        }
    }
    return count;
}

- (void)upsertNewMessages:(NSArray<KUSChatMessage *> *)chatMessages
{
    if (chatMessages.count == 1) {
        [self upsertObjects:chatMessages];
    } else if (chatMessages.count > 1) {
        NSMutableArray<KUSChatMessage *> *reversedMessages = [[NSMutableArray alloc] initWithCapacity:chatMessages.count];
        for (KUSChatMessage *chatMessage in chatMessages.reverseObjectEnumerator) {
            [reversedMessages addObject:chatMessage];
        }
        [self upsertObjects:reversedMessages];
    }
}

- (void)sendMessageWithText:(NSString *)text attachments:(NSArray<UIImage *> *)attachments
{
    NSString *tempMessageId = [[NSUUID UUID] UUIDString];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *attachmentObjects = [[NSMutableArray alloc] initWithCapacity:attachments.count];
    NSMutableArray<NSString *> *cachedImageKeys = [[NSMutableArray alloc] initWithCapacity:attachments.count];
    for (UIImage *attachment in attachments) {
        NSString *attachmentId = [[NSUUID UUID] UUIDString];
        NSURL *attachmentURL = [KUSChatMessage attachmentURLForMessageId:tempMessageId attachmentId:attachmentId];
        NSString *imageKey = attachmentURL.absoluteString;
        [[SDImageCache sharedImageCache] storeImage:attachment
                                             forKey:imageKey
                                             toDisk:NO
                                         completion:nil];
        [attachmentObjects addObject:@{ @"id": attachmentId }];
        [cachedImageKeys addObject:imageKey];
    }

    NSDictionary *json = @{
        @"type": @"chat_message",
        @"id": tempMessageId,
        @"attributes": @{
            @"body": text,
            @"direction": @"in",
            @"createdAt": [KUSDate stringFromDate:[NSDate date]]
        },
        @"relationships": @{
            @"attachments" : @{
                @"data": attachmentObjects
            }
        }
    };

    NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage objectsWithJSON:json];
    for (KUSChatMessage *message in temporaryMessages) {
        message.state = KUSChatMessageStateSending;
    }
    [self upsertNewMessages:temporaryMessages];

    // Logic to handle a chat session error or a message send error
    void(^handleError)(void) = ^void() {
        [self removeObjects:temporaryMessages];

        for (KUSChatMessage *message in temporaryMessages) {
            message.state = KUSChatMessageStateSending;
        }
        [self upsertNewMessages:temporaryMessages];
    };

    // Logic to handle a successful message send
    void(^handleMessageSend)(NSDictionary *) = ^void(NSDictionary *response) {
        [self removeObjects:temporaryMessages];

        NSArray<KUSChatMessage *> *finalMessages = [KUSChatMessage objectsWithJSON:response[@"data"]];

        KUSChatMessage *firstMessage = finalMessages.firstObject;
        for (NSUInteger i = 0; i < firstMessage.attachmentIds.count; i++) {
            UIImage *attachment = [attachments objectAtIndex:i];
            NSString *attachmentId = [firstMessage.attachmentIds objectAtIndex:i];
            NSURL *attachmentURL = [KUSChatMessage attachmentURLForMessageId:firstMessage.oid attachmentId:attachmentId];
            [[SDImageCache sharedImageCache] storeImage:attachment
                                                 forKey:attachmentURL.absoluteString
                                                 toDisk:YES
                                             completion:nil];
        }

        [self upsertNewMessages:finalMessages];

        // Remove the temporary images from the cache
        for (NSString *imageKey in cachedImageKeys) {
            [[SDImageCache sharedImageCache] removeImageForKey:imageKey fromDisk:NO withCompletion:nil];
        }
    };

    // Logic to actually send a message
    void (^sendMessage)(void) = ^void() {
        [self
         _uploadImages:attachments
         completion:^(NSError *error, NSArray<NSString *> *attachmentIds) {
             if (error) {
                 KUSLogError(@"Error uploading attachments: %@", error);
                 handleError();
                 return;
             }

             [self.userSession.requestManager
              performRequestType:KUSRequestTypePost
              endpoint:@"/c/v1/chat/messages"
              params:@{ @"body": text, @"session": _sessionId, @"attachments": attachmentIds }
              authenticated:YES
              completion:^(NSError *error, NSDictionary *response) {
                  if (error) {
                      KUSLogError(@"Error sending message: %@", error);
                      handleError();
                      return;
                  }

                  handleMessageSend(response);
              }];
         }];
    };

    if (_sessionId) {
        sendMessage();
    } else {
        [self.userSession.chatSessionsDataSource
         createSessionWithTitle:text
         completion:^(NSError *error, KUSChatSession *session) {
             if (error) {
                 KUSLogError(@"Error creating session: %@", error);
                 handleError();
                 return;
             }

             // Grab the session id
             _sessionId = session.oid;

             // Insert the current messages data source into the userSession's lookup table
             [self.userSession.chatMessagesDataSources setObject:self forKey:session.oid];

             // Notify listeners
             for (id<KUSChatMessagesDataSourceListener> listener in [self.listeners copy]) {
                 if ([listener respondsToSelector:@selector(chatMessagesDataSource:didCreateSessionId:)]) {
                     [listener chatMessagesDataSource:self didCreateSessionId:session.oid];
                 }
             }

             sendMessage();
         }];
    }
}

- (void)_uploadImages:(NSArray<UIImage *> *)images completion:(void(^)(NSError *error, NSArray<NSString *> *attachmentIds))completion
{
    if (images.count == 0) {
        if (completion) {
            completion(nil, @[]);
        }
        return;
    }

    __block BOOL didSendCompletion = NO;
    __block NSUInteger uploadedCount = 0;
    __block NSMutableArray<NSString *> *attachmentIds = [[NSMutableArray alloc] init];

    void(^onUploadComplete)(NSUInteger, NSError *, NSString *) = ^void(NSUInteger index, NSError *error, NSString *attachmentId) {
        if (error) {
            if (completion && !didSendCompletion) {
                didSendCompletion = YES;
                completion(error, nil);
            }
            return;
        }

        uploadedCount++;
        [attachmentIds replaceObjectAtIndex:index withObject:attachmentId];
        if (uploadedCount == images.count) {
            if (completion && !didSendCompletion) {
                didSendCompletion = YES;
                completion(nil, attachmentIds);
            }
            return;
        }
    };

    for (NSUInteger i = 0; i < images.count; i++) {
        [attachmentIds addObject:@""];
        UIImage *image = [images objectAtIndex:i];

        NSUInteger index = i;
        [self
         _uploadImage:image
         completion:^(NSError *error, KUSChatAttachment *attachment) {
             onUploadComplete(index, error, attachment.oid);
         }];
    }
}

- (void)_uploadImage:(UIImage *)image completion:(void(^)(NSError *error, KUSChatAttachment *attachment))completion
{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [NSUUID UUID].UUIDString];
    [self.userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/chat/attachments"
     params:@{
              @"name": fileName,
              @"contentLength": @(imageData.length),
              @"contentType": @"image/jpeg"
              }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         if (error) {
             if (completion) {
                 completion(error, nil);
             }
             return;
         }

         KUSChatAttachment *chatAttachment = [[KUSChatAttachment alloc] initWithJSON:response[@"data"]];
         NSURL *uploadURL = [NSURL URLWithString:[response valueForKeyPath:@"meta.upload.url"]];
         NSDictionary<NSString *, NSString *> *uploadFields = [response valueForKeyPath:@"meta.upload.fields"];

         NSString *boundary = @"----FormBoundary";
         NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
         NSData *bodyData = KUSUploadBodyDataFromImageAndFileNameAndFieldsAndBoundary(imageData, fileName, uploadFields, boundary);

         [self.userSession.requestManager
          performRequestType:KUSRequestTypePost
          URL:uploadURL
          params:nil
          bodyData:bodyData
          authenticated:NO
          additionalHeaders:@{ @"Content-Type" : contentType }
          completion:^(NSError *error, NSDictionary *response) {
              if (completion) {
                  completion(nil, chatAttachment);
              }
          }];
     }];
}

- (void)resendMessage:(KUSChatMessage *)message
{
    if (message) {
        [self removeObjects:@[ message ]];
        // [self sendTextMessage:message.body];
    }
}

static NSData *KUSUploadBodyDataFromImageAndFileNameAndFieldsAndBoundary(NSData *imageData,
                                                                         NSString *fileName,
                                                                         NSDictionary<NSString *, NSString *> *uploadFields,
                                                                         NSString *boundary)
{
    NSMutableData *bodyData = [[NSMutableData alloc] init];

    // Make sure to insert the "key" field first
    NSMutableArray<NSString *> *fieldKeys = [uploadFields.allKeys mutableCopy];
    if ([fieldKeys containsObject:@"key"]) {
        [fieldKeys removeObject:@"key"];
        [fieldKeys insertObject:@"key" atIndex:0];
    }

    [bodyData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *field in fieldKeys) {
        NSString *value = uploadFields[field];
        [bodyData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", field, value] dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [bodyData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[NSData dataWithData:imageData]];
    [bodyData appendData:[[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    return bodyData;
}

@end
