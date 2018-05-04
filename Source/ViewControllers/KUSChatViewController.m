//
//  KUSChatViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatViewController.h"

#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <SafariServices/SafariServices.h>

#import "KUSChatSession.h"
#import "KUSUserSession.h"

#import "KUSColor.h"
#import "KUSChatTableView.h"
#import "KUSAvatarImageView.h"
#import "KUSChatMessagesDataSource.h"
#import "KUSChatMessageTableViewCell.h"
#import "KUSEmailInputView.h"
#import "KUSImage.h"
#import "KUSInputBar.h"
#import "KUSLog.h"
#import "KUSOptionPickerView.h"
#import "KUSTeamsDataSource.h"
#import "KUSText.h"
#import "KUSPermissions.h"
#import "KUSNavigationBarView.h"
#import "KUSNYTChatMessagePhoto.h"
#import "KUSNYTImagePhoto.h"

@interface KUSChatViewController () <KUSEmailInputViewDelegate, KUSInputBarDelegate, KUSOptionPickerViewDelegate,
                                     KUSChatMessagesDataSourceListener, KUSChatMessageTableViewCellDelegate,
                                     NYTPhotosViewControllerDelegate, UITableViewDataSource, UITableViewDelegate,
                                     UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                     KUSNavigationBarViewDelegate> {
    KUSUserSession *_userSession;

    BOOL _showBackButton;
    NSString *_chatSessionId;
    KUSChatMessagesDataSource *_chatMessagesDataSource;

    KUSTeamsDataSource *_teamOptionsDataSource;

    CGFloat _keyboardHeight;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) KUSEmailInputView *emailInputView;
@property (nonatomic, strong) KUSInputBar *inputBarView;
@property (nonatomic, strong) KUSOptionPickerView *optionPickerView;
@property (nonatomic, strong) KUSNavigationBarView *fauxNavigationBar;

@end

@implementation KUSChatViewController

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession forChatSession:(KUSChatSession *)session
{
    self = [super init];
    if (self) {
        _userSession = userSession;
        _chatSessionId = session.oid;
        _chatMessagesDataSource = [_userSession chatMessagesDataSourceForSessionId:_chatSessionId];
        _showBackButton = YES;
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession forNewSessionWithBackButton:(BOOL)showBackButton
{
    self = [super init];
    if (self) {
        _userSession = userSession;
        _chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initForNewConversationWithUserSession:_userSession];
        _showBackButton = showBackButton;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeTop;

    self.tableView = [[KUSChatTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.tableView.scrollsToTop = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.transform = CGAffineTransformMakeScale(1.0, -1.0);
    [self.view addSubview:self.tableView];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(ios 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
#else
    self.automaticallyAdjustsScrollViewInsets = NO;
#endif

    self.navigationController.interactivePopGestureRecognizer.enabled = _showBackButton;
    self.fauxNavigationBar = [[KUSNavigationBarView alloc] initWithUserSession:_userSession];
    self.fauxNavigationBar.delegate = self;
    [self.fauxNavigationBar setSessionId:_chatSessionId];
    [self.fauxNavigationBar setShowsLabels:YES];
    [self.fauxNavigationBar setShowsBackButton:_showBackButton];
    [self.fauxNavigationBar setShowsDismissButton:YES];
    [self.view addSubview:self.fauxNavigationBar];

    self.inputBarView = [[KUSInputBar alloc] init];
    self.inputBarView.delegate = self;
    self.inputBarView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    self.inputBarView.allowsAttachments = _chatSessionId != nil;
    [self.view addSubview:self.inputBarView];

    [_chatMessagesDataSource addListener:self];
    [_chatMessagesDataSource fetchLatest];
    if (!_chatMessagesDataSource.didFetch) {
        [self showLoadingIndicator];
    }

    NSArray<NSString *> *keyboardNotificationNames = @[
        UIKeyboardWillShowNotification,
        UIKeyboardWillChangeFrameNotification,
        UIKeyboardWillHideNotification,
        UIKeyboardDidChangeFrameNotification
    ];
    for (NSString *notificationName in keyboardNotificationNames) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:notificationName
                                                   object:nil];
    }

    [self _checkShouldShowEmailInput];

    // Force layout so that animated presentations start from the right state
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_inputBarView setNeedsLayout];
    [self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Only bring up the keyboard if the chat is being presented/pushed
    if (self.isBeingPresented || self.isMovingToParentViewController) {
        if (!_inputBarView.hidden) {
            [_inputBarView becomeFirstResponder];
        }
    }

    [_userSession.chatSessionsDataSource updateLastSeenAtForSessionId:_chatSessionId completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_inputBarView resignFirstResponder];

    [_userSession.chatSessionsDataSource updateLastSeenAtForSessionId:_chatSessionId completion:nil];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    [self.fauxNavigationBar setExtraLarge:_chatMessagesDataSource.count == 0];
    self.fauxNavigationBar.topInset = self.edgeInsets.top;
    CGFloat navigationBarHeight = [self.fauxNavigationBar desiredHeight];

    CGFloat inputBarHeight = [self.inputBarView desiredHeight];
    CGFloat inputBarY = self.view.bounds.size.height - MAX(self.edgeInsets.bottom, _keyboardHeight) - inputBarHeight;
    self.inputBarView.frame = (CGRect) {
        .origin.y = inputBarY,
        .size.width = self.view.bounds.size.width,
        .size.height = inputBarHeight
    };

    CGFloat optionPickerHeight = [self.optionPickerView desiredHeight];
    CGFloat optionPickerY = self.view.bounds.size.height - MAX(self.edgeInsets.bottom, _keyboardHeight) - optionPickerHeight;
    self.optionPickerView.frame = (CGRect) {
        .origin.y = optionPickerY,
        .size.width = self.view.bounds.size.width,
        .size.height = optionPickerHeight
    };

    self.fauxNavigationBar.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = navigationBarHeight
    };

    // Hide the email input view in landscape to save space on iPhones
    BOOL isIphone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGFloat emailInputHeight = (isIphone && isLandscape ? 0.0 : 80.0);
    self.emailInputView.frame = (CGRect) {
        .origin.y = self.fauxNavigationBar.frame.size.height,
        .size.width = self.view.bounds.size.width,
        .size.height = emailInputHeight
    };

    self.tableView.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = MIN(inputBarY, optionPickerY)
    };

    self.tableView.contentInset = (UIEdgeInsets) {
        .top = 4.0,
        .bottom = navigationBarHeight + self.emailInputView.frame.size.height + 4.0
    };
    self.tableView.scrollIndicatorInsets = (UIEdgeInsets) {
        .bottom = navigationBarHeight + self.emailInputView.frame.size.height
    };
}

#pragma mark - Internal logic methods

- (void)_checkShouldShowEmailInput
{
    BOOL shouldShowEmailInput = [_userSession shouldCaptureEmail] && _chatSessionId != nil;
    if (shouldShowEmailInput) {
        if (self.emailInputView == nil) {
            self.emailInputView = [[KUSEmailInputView alloc] init];
            self.emailInputView.delegate = self;
            [self.view addSubview:self.emailInputView];
            [self.view setNeedsLayout];
        }
    } else {
        [self.emailInputView removeFromSuperview];
        self.emailInputView = nil;
        [self.view setNeedsLayout];
    }
}

- (void)_checkShouldShowOptionPicker
{
    KUSFormQuestion *currentQuestion = _chatMessagesDataSource.currentQuestion;
    BOOL wantsOptionPicker = (currentQuestion
                              && currentQuestion.property == KUSFormQuestionPropertyConversationTeam
                              && currentQuestion.values.count > 0);
    BOOL teamOptionsDidFail = _teamOptionsDataSource.error || (_teamOptionsDataSource.didFetch && _teamOptionsDataSource.count == 0);
    if (wantsOptionPicker && !teamOptionsDidFail) {
        self.inputBarView.hidden = YES;
        if ([self.inputBarView isFirstResponder]) {
            [self.inputBarView resignFirstResponder];
        }

        NSArray<NSString *> *teamIds = currentQuestion.values;
        if (_teamOptionsDataSource == nil || ![_teamOptionsDataSource.teamIds isEqual:teamIds]) {
            _teamOptionsDataSource = [[KUSTeamsDataSource alloc] initWithUserSession:_userSession teamIds:teamIds];
            [_teamOptionsDataSource addListener:self];
            [_teamOptionsDataSource fetchLatest];
        }

        if (self.optionPickerView == nil) {
            self.optionPickerView = [[KUSOptionPickerView alloc] init];
            self.optionPickerView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
            self.optionPickerView.delegate = self;
            [self.view addSubview:self.optionPickerView];
            [self _updateOptionsPickerOptions];
        }
    } else {
        _teamOptionsDataSource = nil;

        self.inputBarView.hidden = NO;
        [self.optionPickerView removeFromSuperview];
        self.optionPickerView = nil;
        [self.view setNeedsLayout];
    }
}

- (void)_updateOptionsPickerOptions
{
    NSMutableArray<NSString *> *options = [[NSMutableArray alloc] init];
    for (KUSTeam *team in _teamOptionsDataSource.allObjects) {
        [options addObject:team.fullDisplay];
    }
    [self.optionPickerView setOptions:options];

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - KUSChatMessagesDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    if (dataSource == _chatMessagesDataSource) {
        [self hideLoadingIndicator];
    }
}

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (dataSource == _chatMessagesDataSource) {
        [self _checkShouldShowOptionPicker];

        if (dataSource.count == 1) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }];
        } else {
            [self.view setNeedsLayout];
        }
        [self.tableView reloadData];
    } else if (dataSource == _teamOptionsDataSource) {
        [self _checkShouldShowOptionPicker];
        [self _updateOptionsPickerOptions];
    }
}

- (void)paginatedDataSource:(KUSPaginatedDataSource *)dataSource didReceiveError:(NSError *)error
{
    if (dataSource == _chatMessagesDataSource && !_chatMessagesDataSource.didFetch) {
        __weak KUSChatViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong KUSChatViewController *strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf->_chatMessagesDataSource fetchLatest];
            }
        });
    } else if (dataSource == _teamOptionsDataSource) {
        [self _checkShouldShowOptionPicker];
    }
}

- (void)chatMessagesDataSource:(KUSChatMessagesDataSource *)dataSource didCreateSessionId:(NSString *)sessionId
{
    _chatSessionId = sessionId;
    self.inputBarView.allowsAttachments = YES;
    [self.fauxNavigationBar setSessionId:_chatSessionId];
    _showBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = _showBackButton;
    [self.fauxNavigationBar setShowsBackButton:YES];
    [self _checkShouldShowEmailInput];
    [self.view setNeedsLayout];
}

#pragma mark - NSNotification methods

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrameWindow];

    double keyboardTransitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];

    UIViewAnimationCurve keyboardTransitionAnimationCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];

    CGRect keyboardEndFrameView = [self.view convertRect:keyboardEndFrameWindow fromView:nil];
    _keyboardHeight = self.view.frame.size.height - keyboardEndFrameView.origin.y;

    UIViewAnimationOptions options = keyboardTransitionAnimationCurve << 16 | UIViewAnimationOptionBeginFromCurrentState;

    BOOL shouldAnimate = keyboardTransitionDuration > 0.0 && self.optionPickerView == nil;
    if (shouldAnimate) {
        [UIView animateWithDuration:keyboardTransitionDuration
                              delay:0.0
                            options:options
                         animations:^{
                             [self.view setNeedsLayout];
                             [self.view layoutIfNeeded];
                         }
                         completion:nil];
    } else {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}


#pragma mark - UIScrollViewDelegate Methods

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        CGPoint offset = CGPointMake(0.0,
                                     scrollView.contentSize.height
                                     - scrollView.bounds.size.height
                                     + scrollView.contentInset.bottom);
        [scrollView setContentOffset:offset animated:YES];
    }
    return NO;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_chatMessagesDataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KUSChatMessage *chatMessage = [self messageForRow:indexPath.row];
    KUSChatMessage *previousChatMessage = [self messageBeforeRow:indexPath.row];
    KUSChatMessage *nextChatMessage = [self messageAfterRow:indexPath.row];
    BOOL currentUser = KUSChatMessageSentByUser(chatMessage);

    NSString *messageCellIdentifier = (currentUser ? @"CurrentUserMessageCell" : @"OtherUserMessageCell");
    KUSChatMessageTableViewCell *cell = (KUSChatMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:messageCellIdentifier];
    if (cell == nil) {
        cell = [[KUSChatMessageTableViewCell alloc] initWithReuseIdentifier:messageCellIdentifier userSession:_userSession];
        cell.transform = tableView.transform;
        cell.delegate = self;
    }

    [cell setChatMessage:chatMessage];

    BOOL previousMessageDiffSender = !KUSChatMessagesSameSender(previousChatMessage, chatMessage);
    BOOL nextMessageOlderThan5Min = nextChatMessage == nil || [nextChatMessage.createdAt timeIntervalSinceDate:chatMessage.createdAt] > 5.0 * 60.0;
    [cell setShowsAvatar:previousMessageDiffSender];
    [cell setShowsTimestamp:nextMessageOlderThan5Min];

    // Make sure that we've fetched all of the latest messages by loading the next page
    static NSUInteger kPrefetchPadding = 20;
    if (!_chatMessagesDataSource.didFetchAll && indexPath.row >= _chatMessagesDataSource.count - 1 - kPrefetchPadding) {
        [_chatMessagesDataSource fetchNext];
    }

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KUSChatMessage *chatMessage = [self messageForRow:indexPath.row];
    KUSChatMessage *nextChatMessage = [self messageAfterRow:indexPath.row];
    BOOL nextMessageOlderThan5Min = nextChatMessage == nil || [nextChatMessage.createdAt timeIntervalSinceDate:chatMessage.createdAt] > 5.0 * 60.0;
    CGFloat messageHeight = [KUSChatMessageTableViewCell heightForChatMessage:chatMessage maxWidth:tableView.bounds.size.width];
    if (nextMessageOlderThan5Min) {
        return messageHeight + [KUSChatMessageTableViewCell heightForTimestamp];
    } else {
        return messageHeight;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView high-level helpers

- (KUSChatMessage *)messageForRow:(NSInteger)row
{
    return [_chatMessagesDataSource objectAtIndex:row];
}

- (KUSChatMessage *)messageBeforeRow:(NSInteger)row
{
    if (row < [_chatMessagesDataSource count] - 1 && row >= 0) {
        return [self messageForRow:row + 1];
    } else {
        return nil;
    }
}

- (KUSChatMessage *)messageAfterRow:(NSInteger)row
{
    if (row > 0 && row < [_chatMessagesDataSource count]) {
        return [self messageForRow:row - 1];
    } else {
        return nil;
    }
}

#pragma mark - KUSChatMessageTableViewCellDelegate methods

- (void)chatMessageTableViewCell:(KUSChatMessageTableViewCell *)cell didTapLink:(NSURL *)URL
{
    if ([URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"]) {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
        [self presentViewController:safariViewController animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:URL];
    }
}

- (void)chatMessageTableViewCellDidTapError:(KUSChatMessageTableViewCell *)cell forMessage:(KUSChatMessage *)message
{
    [_chatMessagesDataSource resendMessage:message];
}

- (void)chatMessageTableViewCellDidTapImage:(KUSChatMessageTableViewCell *)cell forMessage:(KUSChatMessage *)message
{
    id<NYTPhoto> initialPhoto = nil;
    NSMutableArray<id<NYTPhoto>> *photos = [[NSMutableArray alloc] init];

    for (KUSChatMessage *chatMessage in [_chatMessagesDataSource.allObjects reverseObjectEnumerator]) {
        if (chatMessage.type == KUSChatMessageTypeImage) {
            KUSNYTChatMessagePhoto *messagePhoto = [[KUSNYTChatMessagePhoto alloc] initWithChatMessage:chatMessage];
            [photos addObject:messagePhoto];

            if ([chatMessage.oid isEqualToString:message.oid]) {
                initialPhoto = messagePhoto;
            }
        }
    }

    [_inputBarView resignFirstResponder];

    NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:photos initialPhoto:initialPhoto];
    photosViewController.delegate = self;
    [self presentViewController:photosViewController animated:YES completion:nil];
}

#pragma mark - KUSNavigationBarViewDelegate methods

- (void)navigationBarViewDidTapBack:(KUSNavigationBarView *)navigationBarView
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationBarViewDidTapDismiss:(KUSNavigationBarView *)navigationBarView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KUSEmailInputViewDelegate methods

- (void)emailInputView:(KUSEmailInputView *)inputView didSubmitEmail:(NSString *)email
{
    [_userSession submitEmail:email];
    [self _checkShouldShowEmailInput];
}

#pragma mark - KUSOptionPickerViewDelegate methods

- (void)optionPickerView:(KUSOptionPickerView *)pickerView didSelectOption:(NSString *)option
{
    NSString *value = nil;
    KUSTeam *team = nil;
    NSUInteger optionIndex = [pickerView.options indexOfObject:option];
    KUSFormQuestion *currentQuestion = _chatMessagesDataSource.currentQuestion;
    if (optionIndex != NSNotFound && optionIndex < currentQuestion.values.count) {
        value = currentQuestion.values[optionIndex];
    }
    if (optionIndex != NSNotFound && optionIndex < _teamOptionsDataSource.count) {
        team = [_teamOptionsDataSource objectAtIndex:optionIndex];
    }
    [_chatMessagesDataSource sendMessageWithText:team.displayName ?: option attachments:nil value:value ?: team.oid];
}

#pragma mark - KUSInputBarDelegate methods

- (BOOL)inputBarShouldEnableSend:(KUSInputBar *)inputBar
{
    KUSFormQuestion *currentQuestion = _chatMessagesDataSource.currentQuestion;
    if (currentQuestion && currentQuestion.property == KUSFormQuestionPropertyCustomerEmail) {
        return [KUSText isValidEmail:inputBar.text];
    }
    return inputBar.text.length > 0;
}

- (void)inputBarDidPressSend:(KUSInputBar *)inputBar
{
    // Disallow message sending while autoreply/form messages are being delayed
    if ([_chatMessagesDataSource shouldPreventSendingMessage]) {
        return;
    }

    [_chatMessagesDataSource sendMessageWithText:inputBar.text attachments:inputBar.imageAttachments];
    [_inputBarView setText:nil];
    [_inputBarView setImageAttachments:nil];
}

- (void)inputBarDidTapAttachment:(KUSInputBar *)inputBar
{
    [self.view endEditing:YES];

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    if ([KUSPermissions cameraAccessIsAvailable]) {
        
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:[[KUSLocalizationManager sharedInstance] localizedString:@"Camera"]
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self _presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
                                                             }];
        [actionController addAction:cameraAction];
    }

    if ([KUSPermissions photoLibraryAccessIsAvailable]) {
        UIAlertAction *photoAction = [UIAlertAction actionWithTitle:[[KUSLocalizationManager sharedInstance]
                                                                     localizedString:@"Photo Library"]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self _presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                                                            }];
        [actionController addAction:photoAction];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[[KUSLocalizationManager sharedInstance] localizedString:@"Cancel"]
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

- (void)_presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = sourceType;

    UIModalPresentationStyle presentationStyle = (sourceType == UIImagePickerControllerSourceTypeCamera
                                                  ? UIModalPresentationFullScreen
                                                  : UIModalPresentationPopover);
    imagePickerController.modalPresentationStyle = presentationStyle;

    UIPopoverPresentationController *presentationController = imagePickerController.popoverPresentationController;
    presentationController.sourceView = self.inputBarView.attachmentButton;
    presentationController.sourceRect = self.inputBarView.attachmentButton.bounds;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;

    imagePickerController.view.backgroundColor = [UIColor whiteColor];
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)inputBarDesiredHeightDidChange:(KUSInputBar *)inputBar
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)inputBar:(KUSInputBar *)inputBar wantsToPreviewImage:(UIImage *)image
{
    [_inputBarView resignFirstResponder];

    NSMutableArray<id<NYTPhoto>> *photos = [[NSMutableArray alloc] init];
    id<NYTPhoto> initialPhoto = nil;

    for (UIImage *imageAttachment in inputBar.imageAttachments) {
        id<NYTPhoto> photo = [[KUSNYTImagePhoto alloc] initWithImage:imageAttachment];
        [photos addObject:photo];
        if (image == imageAttachment) {
            initialPhoto = photo;
        }
    }

    NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:photos initialPhoto:initialPhoto];
    photosViewController.delegate = self;
    [self presentViewController:photosViewController animated:YES completion:nil];
}

#pragma mark - NYTPhotosViewControllerDelegate methods

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicatorView startAnimating];
    return activityIndicatorView;
}

- (void)photosViewControllerWillDismiss:(NYTPhotosViewController *)photosViewController
{
    [self.view setNeedsLayout];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];

    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *editedImage = [info valueForKey:UIImagePickerControllerEditedImage];
    UIImage *chosenImage = editedImage ?: originalImage;

    [self.inputBarView attachImage:chosenImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
