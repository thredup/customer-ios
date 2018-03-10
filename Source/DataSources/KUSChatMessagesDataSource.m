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
#import "KUSUpload.h"

#import <SDWebImage/SDImageCache.h>

static const NSTimeInterval KUSChatAutoreplyDelay = 2.0;

@interface KUSChatMessagesDataSource () <KUSChatMessagesDataSourceListener, KUSObjectDataSourceListener> {
    NSString *_Nullable _sessionId;
    BOOL _createdLocally;

    NSMutableSet<NSString *> *_delayedChatMessageIds;

    KUSForm *_form;
    NSInteger _questionIndex;
    KUSFormQuestion *_formQuestion;
    BOOL _submittingForm;
    BOOL _creatingSession;

    NSMutableArray<void(^)(BOOL success, NSError *error)> *_onSessionCreationCallbacks;
    NSMutableDictionary<NSString *, void(^)(void)> *_messageRetryBlocksById;
}

@end

@implementation KUSChatMessagesDataSource

#pragma mark - Lifecycle methods

- (instancetype)_initWithUserSession:(KUSUserSession *)userSession
{
    self = [super initWithUserSession:userSession];
    if (self) {
        _questionIndex = -1;
        _delayedChatMessageIds = [[NSMutableSet alloc] init];
        _messageRetryBlocksById = [[NSMutableDictionary alloc] init];

        [self.userSession.chatSettingsDataSource addListener:self];
        [self addListener:self];
    }
    return self;
}

- (instancetype)initForNewConversationWithUserSession:(KUSUserSession *)userSession
{
    self = [self _initWithUserSession:userSession];
    if (self) {
        _createdLocally = YES;
        [self.userSession.formDataSource addListener:self];
        if (!self.userSession.formDataSource.didFetch) {
            [self.userSession.formDataSource fetch];
        } else {
            _form = self.userSession.formDataSource.object;
        }
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
    if (_form == nil && [dataSource isKindOfClass:[KUSFormDataSource class]]) {
        _form = dataSource.object;
    }

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

- (NSString *)sessionId
{
    return _sessionId;
}

- (NSString *)firstOtherUserId
{
    for (KUSChatMessage *message in self.allObjects) {
        if (!KUSChatMessageSentByUser(message)) {
            return message.sentById;
        }
    }
    return nil;
}

- (NSArray<NSString *> *)otherUserIds
{
    NSMutableSet<NSString *> *userIdsSet = [[NSMutableSet alloc] init];
    NSMutableArray<NSString *> *otherUserIds = [[NSMutableArray alloc] init];
    for (KUSChatMessage *message in self.allObjects) {
        if (!KUSChatMessageSentByUser(message)) {
            NSString *sentById = message.sentById;
            if (sentById && ![userIdsSet containsObject:sentById]) {
                [userIdsSet addObject:sentById];
                [otherUserIds addObject:sentById];
            }
        }
    }
    return otherUserIds;
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

    // When submitting the form or creating session, prevent sending more responses
    if (_submittingForm || _creatingSession) {
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

- (KUSFormQuestion *)currentQuestion
{
    if (_sessionId) {
        return nil;
    }
    if (KUSChatMessageSentByUser([self latestMessage])) {
        return nil;
    }
    return _formQuestion;
}

- (KUSChatMessage *)latestMessage
{
    if (self.count > 0) {
        return [self objectAtIndex:0];
    }
    return nil;
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
    [self sendMessageWithText:text attachments:attachments value:nil];
}

- (void)sendMessageWithText:(NSString *)text attachments:(NSArray<UIImage *> *)attachments value:(NSString *)value
{
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    if (_sessionId == nil && chatSettings.activeFormId) {
        NSAssert(attachments.count == 0, @"Should not have been able to send attachments without a _sessionId");

        NSDictionary *json = @{
            @"type": @"chat_message",
            @"id": [[NSUUID UUID] UUIDString],
            @"attributes": @{
                @"body": text,
                @"direction": @"in",
                @"createdAt": [KUSDate stringFromDate:[NSDate date]]
            }
        };
        NSArray<KUSChatMessage *> *temporaryMessages = [KUSChatMessage objectsWithJSON:json];
        for (KUSChatMessage *temporaryMessage in temporaryMessages) {
            temporaryMessage.value = value;
        }
        [self upsertNewMessages:temporaryMessages];

        return;
    }

    [self _actuallySendMessageWithText:text attachments:attachments];
}

- (void)_createSessionIfNecessaryWithTitle:(NSString *)title completion:(void(^)(BOOL success, NSError *error))completion
{
    if (_sessionId) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        if (_onSessionCreationCallbacks) {
            if (completion) {
                [_onSessionCreationCallbacks addObject:completion];
            }
        } else {
            _onSessionCreationCallbacks = [[NSMutableArray alloc] initWithObjects:completion, nil];

            _creatingSession = YES;
            [self.userSession.chatSessionsDataSource
             createSessionWithTitle:title
             completion:^(NSError *error, KUSChatSession *session) {
                 NSArray<void(^)(BOOL success, NSError *error)> *callbacks = [_onSessionCreationCallbacks copy];
                 _onSessionCreationCallbacks = nil;

                 if (error || session == nil) {
                     KUSLogError(@"Error creating session: %@", error);
                     for (void(^callback)(BOOL success, NSError *error) in callbacks) {
                         callback(NO, error);
                     }
                     return;
                 }

                 // Grab the session id
                 _sessionId = session.oid;
                 _creatingSession = NO;

                 // Insert the current messages data source into the userSession's lookup table
                 [self.userSession.chatMessagesDataSources setObject:self forKey:session.oid];

                 // Notify listeners
                 for (id<KUSChatMessagesDataSourceListener> listener in [self.listeners copy]) {
                     if ([listener respondsToSelector:@selector(chatMessagesDataSource:didCreateSessionId:)]) {
                         [listener chatMessagesDataSource:self didCreateSessionId:session.oid];
                     }
                 }

                 for (void(^callback)(BOOL success, NSError *error) in callbacks) {
                     callback(YES, nil);
                 }
             }];
        }
    }
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

    // Insert the messages
    void(^insertMessagesWithState)(KUSChatMessageState) = ^void(KUSChatMessageState state) {
        [self removeObjects:temporaryMessages];
        for (KUSChatMessage *message in temporaryMessages) {
            message.state = state;
        }
        [self upsertNewMessages:temporaryMessages];
    };

    // Logic to handle a chat session error or a message send error
    void(^handleError)(void) = ^void() {
        insertMessagesWithState(KUSChatMessageStateFailed);
    };

    // Logic to handle a successful message send
    void(^handleMessageSent)(NSDictionary *) = ^void(NSDictionary *response) {
        NSArray<KUSChatMessage *> *finalMessages = [KUSChatMessage objectsWithJSON:response[@"data"]];

        // Store the local image data in our cache for the remote image urls
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

        // Remove the temporary objects and insert the new/sent objects
        [self removeObjects:temporaryMessages];
        [self upsertNewMessages:finalMessages];

        // Remove the temporary images from the cache
        for (NSString *imageKey in cachedImageKeys) {
            [[SDImageCache sharedImageCache] removeImageForKey:imageKey fromDisk:NO withCompletion:nil];
        }

        // Remove the retry blocks
        for (KUSChatMessage *temporaryMessage in temporaryMessages) {
            [_messageRetryBlocksById removeObjectForKey:temporaryMessage.oid];
        }
    };

    // Logic to actually send a message
    void (^sendMessage)(void) = ^void() {
        [KUSUpload
         uploadImages:attachments
         userSession:self.userSession
         completion:^(NSError *error, NSArray<KUSChatAttachment *> *attachments) {
             if (error) {
                 KUSLogError(@"Error uploading attachments: %@", error);
                 handleError();
                 return;
             }

             NSArray<NSString *> *attachmentIds = [attachments valueForKeyPath:@"@unionOfObjects.oid"];
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

                  handleMessageSent(response);
              }];
         }];
    };

    // Full encapsulating logic for sending the message
    void (^fullySendMessage)(void) = ^void() {
        insertMessagesWithState(KUSChatMessageStateSending);
        [self _createSessionIfNecessaryWithTitle:text completion:^(BOOL success, NSError *error) {
            if (success) {
                sendMessage();
            } else {
                handleError();
            }
        }];
    };

    for (KUSChatMessage *temporaryMessage in temporaryMessages) {
        _messageRetryBlocksById[temporaryMessage.oid] = fullySendMessage;
    }
    fullySendMessage();
}

- (void)resendMessage:(KUSChatMessage *)message
{
    if (message) {
        void(^retryBlock)(void) = _messageRetryBlocksById[message.oid];
        if (retryBlock) {
            retryBlock();
        }
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
    KUSChatMessage *secondMessage = self.count >= 2 ? [self objectAtIndex:self.count - 2] : nil;
    KUSChatSettings *chatSettings = self.userSession.chatSettingsDataSource.object;
    return ((chatSettings.activeFormId.length == 0 || (firstMessage.importedAt == nil && secondMessage && secondMessage.importedAt == nil))
            && chatSettings.autoreply.length > 0
            && [self count] > 0
            && self.didFetchAll
            && _sessionId.length > 0
            && firstMessage.state == KUSChatMessageStateSent
            && KUSChatMessageSentByUser(firstMessage));
}

- (void)_insertAutoreplyIfNecessary
{
    if ([self _shouldShowAutoreply]) {
        NSString *autoreplyId = [NSString stringWithFormat:@"autoreply_%@", _sessionId];
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
    if (_form == nil) {
        return;
    }

    // Make sure we submit the form if we just inserted a non-response question
    if (!_submittingForm && !KUSFormQuestionRequiresResponse(_formQuestion) && _questionIndex == _form.questions.count - 1) {
        [self _submitFormResponses];
    }

    KUSChatMessage *lastMessage = [self latestMessage];
    if (!KUSChatMessageSentByUser(lastMessage)) {
        return;
    }
    if ([self shouldPreventSendingMessage]) {
        return;
    }

    NSTimeInterval additionalInsertDelay = 0;
    NSInteger latestQuestionIndex = _questionIndex;
    NSInteger startingOffset = (_formQuestion ? 1 : 0);
    for (NSInteger i = MAX(_questionIndex + startingOffset, 0); i < _form.questions.count; i++) {
        KUSFormQuestion *question = _form.questions[i];
        if (question.type == KUSFormQuestionTypeUnknown) {
            continue;
        }

        NSDate *createdAt = [lastMessage.createdAt dateByAddingTimeInterval:KUSChatAutoreplyDelay + additionalInsertDelay];
        NSString *questionId = [NSString stringWithFormat:@"question_%@", question.oid];
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
        additionalInsertDelay += KUSChatAutoreplyDelay;

        latestQuestionIndex = i;
        if (KUSFormQuestionRequiresResponse(question)) {
            break;
        }
    }

    if (latestQuestionIndex == _questionIndex) {
        [self _submitFormResponses];
    } else {
        _questionIndex = latestQuestionIndex;
        _formQuestion = _form.questions[_questionIndex];
    }
}

- (void)_submitFormResponses
{
    NSMutableArray<NSDictionary<NSString *, NSObject *> *> *messagesJSON = [[NSMutableArray alloc] init];

    NSUInteger currentMessageIndex = self.count - 1;
    KUSChatMessage *firstUserMessage = [self objectAtIndex:currentMessageIndex];
    currentMessageIndex--;

    [messagesJSON addObject:@{
        @"input": firstUserMessage.body,
        @"inputAt": [KUSDate stringFromDate:firstUserMessage.createdAt]
    }];

    for (KUSFormQuestion *question in _form.questions) {
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
            if (responseMessage.value) {
                [formMessage setObject:responseMessage.value forKey:@"value"];
            }
        }
        [messagesJSON addObject:formMessage];
    }

    _submittingForm = YES;
    KUSChatMessage *lastUserChatMessage = nil;
    for (KUSChatMessage *chatMessage in self.allObjects) {
        if (KUSChatMessageSentByUser(chatMessage)) {
            lastUserChatMessage = chatMessage;
            break;
        }
    }

    // Logic to handle an error
    void(^handleError)(void) = ^void() {
        if (lastUserChatMessage) {
            [self removeObjects:@[ lastUserChatMessage ]];
            lastUserChatMessage.state = KUSChatMessageStateFailed;
            [self upsertObjects:@[ lastUserChatMessage ]];
        }
    };

    void (^actuallySubmitForm)(void) = ^void() {
        [self.userSession.chatSessionsDataSource
         submitFormMessages:messagesJSON
         formId:_form.oid
         completion:^(NSError *error, KUSChatSession *session, NSArray<KUSChatMessage *> *messages) {
             if (error) {
                 handleError();
                 return;
             }

             // If the form contained an email prompt, mark the local session as having submitted email
             if ([_form containsEmailQuestion]) {
                 [self.userSession.userDefaults setDidCaptureEmail:YES];
             }

             // Grab the session id
             _sessionId = session.oid;
             _form = nil;
             _questionIndex = -1;
             _formQuestion = nil;
             _submittingForm = NO;

             // Replace all of the local messages with the new ones
             [self removeObjects:self.allObjects];
             [self upsertNewMessages:messages];
             [_messageRetryBlocksById removeObjectForKey:lastUserChatMessage.oid];

             // Insert the current messages data source into the userSession's lookup table
             [self.userSession.chatMessagesDataSources setObject:self forKey:_sessionId];

             // Notify listeners
             for (id<KUSChatMessagesDataSourceListener> listener in [self.listeners copy]) {
                 if ([listener respondsToSelector:@selector(chatMessagesDataSource:didCreateSessionId:)]) {
                     [listener chatMessagesDataSource:self didCreateSessionId:_sessionId];
                 }
             }
         }];
    };

    void (^retrySubmittingForm)(void) = ^void() {
        if (lastUserChatMessage) {
            [self removeObjects:@[ lastUserChatMessage ]];
            lastUserChatMessage.state = KUSChatMessageStateSending;
            [self upsertObjects:@[ lastUserChatMessage ]];
        }
        actuallySubmitForm();
    };

    if (lastUserChatMessage) {
        _messageRetryBlocksById[lastUserChatMessage.oid] = retrySubmittingForm;
    }
    actuallySubmitForm();
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

    __weak KUSChatMessagesDataSource *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong KUSChatMessagesDataSource *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        [strongSelf->_delayedChatMessageIds removeObject:chatMessage.oid];
        BOOL doesNotAlreadyContainMessage = ![strongSelf objectWithId:chatMessage.oid];
        [strongSelf upsertObjects:@[ chatMessage ]];
        if (doesNotAlreadyContainMessage) {
            [KUSAudio playMessageReceivedSound];
        }
    });
}

@end
