//
//  KUSChatMessagesDataSource.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/23/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatMessagesDataSource.h"

#import "KUSAudio.h"
#import "KUSLog.h"
#import "KUSPaginatedDataSource_Private.h"
#import "KUSUserSession_Private.h"
#import "KUSDate.h"

#import <SDWebImage/SDImageCache.h>

static const NSTimeInterval KUSChatAutoreplyDelay = 2.0;

@interface KUSChatMessagesDataSource () <KUSChatMessagesDataSourceListener, KUSObjectDataSourceListener> {
    NSString *_Nullable _sessionId;

    NSMutableSet<NSString *> *_delayedChatMessageIds;

    BOOL _submittingForm;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)_initWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _delayedChatMessageIds = [[NSMutableSet alloc] init];

        [self.userSession.chatSettingsDataSource addListener:self];
        [self addListener:self];
    }
    return self;
}

- (instancetype)initForNewConversationWithUserSession:(KUSUserSession *)userSession
{
    self = [self _initWithUserSession:userSession];
    if (self) {
        [self.userSession.formDataSource addListener:self];
        [self.userSession.formDataSource fetch];
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession sessionId:(NSString *)sessionId;
{
    NSAssert(sessionId.length, @"Cannot create messages datasource without valid sessionId");
    self = [self _initWithUserSession:userSession];
    if (self) {
        _sessionId = sessionId;
    }
    return self;
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _insertAutoreplyIfNecessary];
    [self _insertFormMessageIfNecessary];
}

- (void)objectDataSource:(KUSObjectDataSource *)dataSource didReceiveError:(NSError *)error
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [dataSource fetch];
    });
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
    if (_sessionId == nil) {
        return YES;
    }
    return [super didFetch];
}

- (BOOL)didFetchAll
{
    if (_sessionId == nil) {
        return YES;
    }
    return [super didFetchAll];
}

#pragma mark - Public methods

- (NSString *)firstOtherUserId
{
    for (KUSChatMessage *message in self.allObjects) {
        if (!KUSChatMessageSentByUser(message)) {
            return message.sentById;
        }
    }
    return nil;
}

- (NSUInteger)unreadCountAfterDate:(NSDate *)date
{
    NSUInteger count = 0;
    for (KUSChatMessage *message in self.allObjects) {
        if (KUSChatMessageSentByUser(message)) {
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

- (BOOL)shouldPreventSendingMessage
{
    // If we haven't loaded the chat settings data source, prevent input
    if (!self.userSession.chatSettingsDataSource.didFetch) {
        return YES;
    }

    // If we are about to insert an artificial message, prevent input
    if (_delayedChatMessageIds.count > 0) {
        return YES;
    }

    // When submitting the form, prevent sending more responses
    if (_submittingForm) {
        return YES;
    }

    // If the user sent their first message and it is not yet sent, prevent input
    KUSChatMessage *firstMessage = self.allObjects.lastObject;
    if (_sessionId == nil
        && [self count] == 1
        && firstMessage.state != KUSChatMessageStateSent) {
        return YES;
    }

    return NO;
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
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    if (_sessionId == nil && chatSettings.activeFormId) {

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
        [self upsertNewMessages:temporaryMessages];

        return;
    }

    [self _actuallySendMessageWithText:text attachments:attachments];
}

- (void)_actuallySendMessageWithText:(NSString *)text attachments:(NSArray<UIImage *> *)attachments
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

#pragma mark - KUSChatMessagesDataSourceListener methods

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    [self _insertAutoreplyIfNecessary];
    [self _insertFormMessageIfNecessary];
}

- (void)chatMessagesDataSource:(KUSChatMessagesDataSource *)dataSource didCreateSessionId:(NSString *)sessionId
{
    [self _insertAutoreplyIfNecessary];
}

- (BOOL)_shouldShowAutoreply
{
    KUSChatMessage *firstMessage = self.allObjects.lastObject;
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    return (chatSettings.activeFormId.length == 0
            && chatSettings.autoreply.length > 0
            && [self count] > 0
            && self.didFetchAll
            && _sessionId.length > 0
            && firstMessage.state == KUSChatMessageStateSent);
}

- (void)_insertAutoreplyIfNecessary
{
    if ([self _shouldShowAutoreply]) {
        NSString *autoreplyId = [NSString stringWithFormat:@"_autoreply_%@", _sessionId];
        // Early escape if we already have an autoreply
        if ([self objectWithId:autoreplyId]) {
            return;
        }

        KUSChatMessage *firstMessage = self.allObjects.lastObject;
        KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
        NSDate *createdAt = [firstMessage.createdAt dateByAddingTimeInterval:KUSChatAutoreplyDelay];
        NSDictionary *json = @{
            @"type": @"chat_message",
            @"id": autoreplyId,
            @"attributes": @{
                @"body": chatSettings.autoreply,
                @"direction": @"out",
                @"createdAt": [KUSDate stringFromDate:createdAt]
            }
        };
        KUSChatMessage *autoreplyMessage = [[KUSChatMessage alloc] initWithJSON:json];
        [self _insertDelayedMessage:autoreplyMessage];
    }
}

- (void)_insertFormMessageIfNecessary
{
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    if (chatSettings.activeFormId == nil) {
        return;
    }
    if ([self count] == 0) {
        return;
    }
    if (_sessionId) {
        return;
    }
    KUSForm *form = self.userSession.formDataSource.object;
    if (form == nil) {
        return;
    }

    NSMutableArray<KUSChatMessage *> *userMessages = [[NSMutableArray alloc] init];
    for (KUSChatMessage *message in self.allObjects.reverseObjectEnumerator) {
        if (KUSChatMessageSentByUser(message)) {
            [userMessages addObject:message];
        }
    }

    NSMutableArray<NSArray *> *groupedFormQuestions = [[NSMutableArray alloc] init];

    NSMutableArray<KUSFormQuestion *> *currentGroup = nil;
    for (KUSFormQuestion *question in form.questions) {
        if (question.type == KUSFormQuestionTypeUnknown) {
            continue;
        }
        if (currentGroup == nil) {
            currentGroup = [[NSMutableArray alloc] init];
        }
        [currentGroup addObject:question];

        if (KUSFormQuestionRequiresResponse(question)) {
            [groupedFormQuestions addObject:currentGroup];
            currentGroup = nil;
        }
    }

    if (userMessages.count == groupedFormQuestions.count + 1) {
        [self _submitFormResponses];
        return;
    }

    NSUInteger questionIndex = userMessages.count - 1;
    if (questionIndex >= groupedFormQuestions.count) {
        return;
    }

    NSArray<KUSFormQuestion *> *questionsToInsert = groupedFormQuestions[questionIndex];
    KUSChatMessage *lastUserMessage = userMessages.lastObject;
    NSTimeInterval additionalDelay = 0;
    for (KUSFormQuestion *question in questionsToInsert) {
        NSDate *createdAt = [lastUserMessage.createdAt dateByAddingTimeInterval:KUSChatAutoreplyDelay + additionalDelay];
        NSString *questionId = [NSString stringWithFormat:@"_question_%@", question.oid];

        NSDictionary *json = @{
            @"type": @"chat_message",
            @"id": questionId,
            @"attributes": @{
                @"body": question.prompt,
                @"direction": @"out",
                @"createdAt": [KUSDate stringFromDate:createdAt]
            }
        };
        KUSChatMessage *formMessage = [[KUSChatMessage alloc] initWithJSON:json];
        [self _insertDelayedMessage:formMessage];
        additionalDelay += KUSChatAutoreplyDelay;
    }
}

- (void)_submitFormResponses
{
    NSMutableArray<NSDictionary *> *messagesJSON = [[NSMutableArray alloc] init];

    NSUInteger currentMessageIndex = self.count - 1;
    KUSChatMessage *firstUserMessage = [self objectAtIndex:currentMessageIndex];
    currentMessageIndex--;

    [messagesJSON addObject:@{
        @"input": firstUserMessage.body,
        @"inputAt": [KUSDate stringFromDate:firstUserMessage.createdAt]
    }];

    KUSForm *form = self.userSession.formDataSource.object;
    for (KUSFormQuestion *question in form.questions) {
        NSMutableDictionary<NSString *, NSObject *> *formMessage = [[NSMutableDictionary alloc] init];

        KUSChatMessage *questionMessage = [self objectAtIndex:currentMessageIndex];
        currentMessageIndex--;

        [formMessage setObject:question.oid forKey:@"id"];
        [formMessage setObject:question.prompt forKey:@"prompt"];
        [formMessage setObject:[KUSDate stringFromDate:questionMessage.createdAt] forKey:@"promptAt"];

        if (KUSFormQuestionRequiresResponse(question)) {
            KUSChatMessage *responseMessage = [self objectAtIndex:currentMessageIndex];
            currentMessageIndex--;

            [formMessage setObject:responseMessage.body forKey:@"input"];
            [formMessage setObject:[KUSDate stringFromDate:responseMessage.createdAt] forKey:@"inputAt"];
        }
        [messagesJSON addObject:formMessage];
    }

    _submittingForm = YES;

    [self.userSession.chatSessionsDataSource
     submitFormMessages:messagesJSON
     formId:form.oid
     completion:^(NSError *error, KUSChatSession *session, NSArray<KUSChatMessage *> *messages) {
         if (error) {
             KUSLogError(@"Error submitting form: %@", error);
             return;
         }

         // Grab the session id
         _sessionId = session.oid;
         _submittingForm = NO;

         [self removeObjects:self.allObjects];
         [self upsertNewMessages:messages];

         // Insert the current messages data source into the userSession's lookup table
         [self.userSession.chatMessagesDataSources setObject:self forKey:_sessionId];

         // Notify listeners
         for (id<KUSChatMessagesDataSourceListener> listener in [self.listeners copy]) {
             if ([listener respondsToSelector:@selector(chatMessagesDataSource:didCreateSessionId:)]) {
                 [listener chatMessagesDataSource:self didCreateSessionId:_sessionId];
             }
         }
     }];
}

- (void)_insertDelayedMessage:(KUSChatMessage *)chatMessage
{
    // Sanity check
    if (chatMessage.oid.length == 0) {
        return;
    }

    // Only insert the message if it doesn't exist already
    if ([self objectWithId:chatMessage.oid]) {
        return;
    }

    // Get the desired delay
    NSTimeInterval delay = [chatMessage.createdAt timeIntervalSinceNow];

    // Immediately add it if desired
    if (delay <= 0.0) {
        [self upsertObjects:@[ chatMessage ]];
        return;
    }

    [_delayedChatMessageIds addObject:chatMessage.oid];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_delayedChatMessageIds removeObject:chatMessage.oid];
        BOOL doesNotAlreadyContainMessage = ![self objectWithId:chatMessage.oid];
        [self upsertObjects:@[ chatMessage ]];
        if (doesNotAlreadyContainMessage) {
            [KUSAudio playMessageReceivedSound];
        }
    });
}

#pragma mark - Helper methods

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
