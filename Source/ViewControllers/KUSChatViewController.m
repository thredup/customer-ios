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
#import "KUSChatSettingsDataSource.h"
#import "KUSEmailInputView.h"
#import "KUSImage.h"
#import "KUSInputBar.h"
#import "KUSLog.h"
#import "KUSPermissions.h"
#import "KUSNavigationBarView.h"
#import "KUSNYTChatMessagePhoto.h"

@interface KUSChatViewController () <KUSEmailInputViewDelegate, KUSInputBarDelegate, KUSObjectDataSourceListener,
                                     KUSPaginatedDataSourceListener, KUSChatMessageTableViewCellDelegate,
                                     NYTPhotosViewControllerDelegate, UITableViewDataSource, UITableViewDelegate,
                                     UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    KUSUserSession *_userSession;

    BOOL _forNewChatSession;
    KUSChatSession *_chatSession;
    KUSChatMessagesDataSource *_chatMessagesDataSource;

    CGFloat _keyboardHeight;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) KUSEmailInputView *emailInputView;
@property (nonatomic, strong) KUSInputBar *inputBarView;
@property (nonatomic, strong) KUSNavigationBarView *fauxNavigationBar;

@end

@implementation KUSChatViewController

#pragma mark - Lifecycle methods

- (instancetype)initWithUserSession:(KUSUserSession *)userSession
{
    self = [super init];
    if (self) {
        _userSession = userSession;
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession forChatSession:(KUSChatSession *)session
{
    self = [self initWithUserSession:userSession];
    if (self) {
        _chatSession = session;
    }
    return self;
}

- (instancetype)initWithUserSession:(KUSUserSession *)userSession forNewSessionWithBackButton:(BOOL)showBackButton
{
    self = [self initWithUserSession:userSession];
    if (self) {
        _forNewChatSession = YES;

        [self.navigationItem setHidesBackButton:!showBackButton animated:NO];
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

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                   target:self
                                                                                   action:@selector(_dismiss)];
    barButtonItem.style = UIBarButtonItemStyleDone;
    self.navigationItem.rightBarButtonItem = barButtonItem;

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

    self.fauxNavigationBar = [[KUSNavigationBarView alloc] initWithUserSession:_userSession];
    [self.fauxNavigationBar setSessionId:_chatSession.oid];
    [self.fauxNavigationBar setShowsLabels:YES];
    [self.view addSubview:self.fauxNavigationBar];

    self.inputBarView = [[KUSInputBar alloc] init];
    self.inputBarView.delegate = self;
    self.inputBarView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:self.inputBarView];

    if (_chatSession) {
        _chatMessagesDataSource = [_userSession chatMessagesDataSourceForSessionId:_chatSession.oid];
        [_chatMessagesDataSource addListener:self];
        [_chatMessagesDataSource fetchLatest];
        if (!_chatMessagesDataSource.didFetch) {
            [self showLoadingIndicator];
        }
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

    [_userSession.chatSettingsDataSource addListener:self];

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
        [_inputBarView becomeFirstResponder];
    }

    [_userSession.chatSessionsDataSource updateLastSeenAtForSessionId:_chatSession.oid completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_inputBarView resignFirstResponder];

    [_userSession.chatSessionsDataSource updateLastSeenAtForSessionId:_chatSession.oid completion:nil];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat extraNavigationBarHeight = (_forNewChatSession ? 146.0 : 36.0);
    CGFloat navigationBarHeight = self.edgeInsets.top + extraNavigationBarHeight;

    CGFloat inputBarHeight = [self.inputBarView desiredHeight];
    CGFloat inputBarY = self.view.bounds.size.height - MAX(self.edgeInsets.bottom, _keyboardHeight) - inputBarHeight;
    self.inputBarView.frame = (CGRect) {
        .origin.y = inputBarY,
        .size.width = self.view.bounds.size.width,
        .size.height = inputBarHeight
    };

    self.fauxNavigationBar.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = [self.fauxNavigationBar desiredHeightWithTopInset:self.edgeInsets.top]
    };

    self.emailInputView.frame = (CGRect) {
        .origin.y = self.fauxNavigationBar.frame.size.height,
        .size.width = self.view.bounds.size.width,
        .size.height = 80.0
    };

    self.tableView.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = self.inputBarView.frame.origin.y
    };

    self.tableView.contentInset = (UIEdgeInsets) {
        .top = 4.0,
        .bottom = navigationBarHeight + self.emailInputView.frame.size.height + 4.0
    };
    self.tableView.scrollIndicatorInsets = (UIEdgeInsets) {
        .bottom = navigationBarHeight + self.emailInputView.frame.size.height
    };
}

#pragma mark - Interface element methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal logic methods

- (void)_checkShouldShowEmailInput
{
    BOOL shouldShowEmailInput = [_userSession shouldCaptureEmail] && _chatSession != nil;
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

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self.tableView reloadData];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    [self hideLoadingIndicator];
}

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    [self.tableView reloadData];
}

- (void)paginatedDataSource:(KUSPaginatedDataSource *)dataSource didReceiveError:(NSError *)error
{
    if (dataSource == _chatMessagesDataSource && !_chatMessagesDataSource.didFetch) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_chatMessagesDataSource fetchLatest];
        });
    }
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
    [UIView animateWithDuration:keyboardTransitionDuration
                          delay:0.0
                        options:options
                     animations:^{
                         [self.view setNeedsLayout];
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
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
    return [self numberOfChatMessages];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KUSChatMessage *chatMessage = [self messageForRow:indexPath.row];
    KUSChatMessage *previousChatMessage = [self messageBeforeRow:indexPath.row];
    BOOL currentUser = chatMessage.direction == KUSChatMessageDirectionIn;

    NSString *messageCellIdentifier = (currentUser ? @"CurrentUserMessageCell" : @"OtherUserMessageCell");
    KUSChatMessageTableViewCell *cell = (KUSChatMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:messageCellIdentifier];
    if (cell == nil) {
        cell = [[KUSChatMessageTableViewCell alloc] initWithReuseIdentifier:messageCellIdentifier userSession:_userSession];
        cell.transform = tableView.transform;
        cell.delegate = self;
    }

    [cell setChatMessage:chatMessage];

    BOOL previousMessageDiffSender = ![previousChatMessage.sentById isEqualToString:chatMessage.sentById];
    [cell setShowsAvatar:previousMessageDiffSender];



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
    return [KUSChatMessageTableViewCell heightForChatMessage:chatMessage maxWidth:tableView.bounds.size.width];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView high-level helpers

- (BOOL)_shouldShowAutoreply
{
    NSUInteger count = [_chatMessagesDataSource count];
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    BOOL shouldShowAutoreply = chatSettings.autoreplyMessage && count > 0 && _chatMessagesDataSource.didFetchAll;
    return shouldShowAutoreply;
}

- (NSUInteger)numberOfChatMessages
{
    NSUInteger count = [_chatMessagesDataSource count];
    if ([self _shouldShowAutoreply]) {
        return count + 1;
    } else {
        return count;
    }
}

- (KUSChatMessage *)messageForRow:(NSInteger)row
{
    NSInteger numberOfRows = [self numberOfChatMessages];
    KUSChatMessage *chatMessage;

    if ([self _shouldShowAutoreply] && row == numberOfRows - 2) {
        KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
        chatMessage = chatSettings.autoreplyMessage;
    } else if ([self _shouldShowAutoreply] && row >= numberOfRows - 1) {
        chatMessage = [_chatMessagesDataSource objectAtIndex:row - 1];
    } else {
        chatMessage = [_chatMessagesDataSource objectAtIndex:row];
    }
    return chatMessage;
}

- (KUSChatMessage *)messageBeforeRow:(NSInteger)row
{
    NSInteger numberOfRows = [self numberOfChatMessages];
    if (row < numberOfRows - 1) {
        return [self messageForRow:row + 1];
    } else {
        return nil;
    }
}

#pragma mark - KUSChatMessageTableViewCellDelegate methods

- (void)chatMessageTableViewCell:(KUSChatMessageTableViewCell *)cell didTapLink:(NSURL *)URL
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
    [self presentViewController:safariViewController animated:YES completion:nil];
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

#pragma mark - KUSEmailInputViewDelegate methods

- (void)emailInputView:(KUSEmailInputView *)inputView didSubmitEmail:(NSString *)email
{
    [_userSession submitEmail:email];
    [self _checkShouldShowEmailInput];
}

#pragma mark - KUSInputBarDelegate methods

- (void)inputBar:(KUSInputBar *)inputBar didEnterText:(NSString *)text
{
    if (_forNewChatSession) {
        [_userSession.chatSessionsDataSource createSessionWithTitle:text completion:^(NSError *error, KUSChatSession *session) {
            if (error) {
                KUSLogError(@"Error creating chat session: %@", error);
                return;
            }

            _forNewChatSession = NO;
            _chatSession = session;
            [self.navigationItem setHidesBackButton:NO animated:YES];
            [self.fauxNavigationBar setSessionId:_chatSession.oid];
            _chatMessagesDataSource = [_userSession chatMessagesDataSourceForSessionId:_chatSession.oid];
            [_chatMessagesDataSource addListener:self];
            [_chatMessagesDataSource fetchLatest];
            [self _checkShouldShowEmailInput];
            [self.view setNeedsLayout];

            [_chatMessagesDataSource sendTextMessage:text];
        }];
    } else {
        [_chatMessagesDataSource sendTextMessage:text];
    }
}

- (void)inputBarDidTapAttachment:(KUSInputBar *)inputBar
{
    [self.view endEditing:YES];

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    if ([KUSPermissions cameraIsAvailable]) {
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self _presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
                                                             }];
        [actionController addAction:cameraAction];
    }

    if ([KUSPermissions photoLibraryIsAvailable]) {
        UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"Photo Library"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self _presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                                                            }];
        [actionController addAction:photoAction];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
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

- (void)inputBarTextDidChange:(KUSInputBar *)inputBar
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - NYTPhotosViewControllerDelegate methods

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicatorView startAnimating];
    return activityIndicatorView;
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];

    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *editedImage = [info valueForKey:UIImagePickerControllerEditedImage];
    UIImage *chosenImage = editedImage ?: originalImage;

    UIImage *resizedImage = [KUSImage resizeImage:chosenImage toFixedPixelCount:1000000.0];
    NSData *data = UIImageJPEGRepresentation(resizedImage, 0.8);
    NSLog(@"data.length: %i", (int)data.length);

    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [NSUUID UUID].UUIDString];
    [_userSession.requestManager
     performRequestType:KUSRequestTypePost
     endpoint:@"/c/v1/chat/attachments"
     params:@{
         @"name": fileName,
         @"contentLength": [NSNumber numberWithUnsignedInteger:data.length],
         @"contentType": @"image/jpeg"
     }
     authenticated:YES
     completion:^(NSError *error, NSDictionary *response) {
         NSLog(@"response: %@", response);
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
