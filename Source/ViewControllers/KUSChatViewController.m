//
//  KUSChatViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatViewController.h"

#import "KUSChatSession.h"
#import "KUSUserSession.h"

#import "KUSColor.h"
#import "KUSAvatarImageView.h"
#import "KUSChatMessagesDataSource.h"
#import "KUSChatMessageTableViewCell.h"
#import "KUSChatSettingsDataSource.h"
#import "KUSInputBar.h"
#import "KUSFauxNavigationBar.h"

@interface KUSChatViewController () <KUSInputBarDelegate, KUSObjectDataSourceListener, KUSPaginatedDataSourceListener, UITableViewDataSource, UITableViewDelegate> {
    KUSUserSession *_userSession;

    BOOL _forNewChatSession;
    KUSChatSession *_chatSession;
    KUSChatMessagesDataSource *_chatMessagesDataSource;
    BOOL _didLoadInitialContent;

    CGFloat _keyboardHeight;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) KUSInputBar *inputBarView;
@property (nonatomic, strong) KUSFauxNavigationBar *fauxNavigationBar;
@property (nonatomic, strong) KUSAvatarImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *greetingLabel;

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

    // self.navigationItem.title = @"Kustomer";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.tableView.scrollsToTop = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = nil;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.transform = CGAffineTransformMakeScale(1.0, -1.0);
    [self.view addSubview:self.tableView];

    self.fauxNavigationBar = [[KUSFauxNavigationBar alloc] init];
    [self.view addSubview:self.fauxNavigationBar];

    self.avatarImageView = [[KUSAvatarImageView alloc] initWithUserSession:_userSession];
    [self.fauxNavigationBar addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:13.0];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.textColor = [UIColor darkGrayColor];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.nameLabel.numberOfLines = 1;
    [self.fauxNavigationBar addSubview:self.nameLabel];

    self.greetingLabel = [[UILabel alloc] init];
    self.greetingLabel.font = [UIFont systemFontOfSize:11.0];
    self.greetingLabel.textAlignment = NSTextAlignmentCenter;
    self.greetingLabel.textColor = [KUSColor darkGrayColor];
    self.greetingLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.greetingLabel.numberOfLines = 1;
    self.greetingLabel.adjustsFontSizeToFitWidth = YES;
    self.greetingLabel.minimumScaleFactor = 0.9;
    [self.fauxNavigationBar addSubview:self.greetingLabel];

    self.inputBarView = [[KUSInputBar alloc] init];
    self.inputBarView.delegate = self;
    self.inputBarView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:self.inputBarView];

    if (_chatSession) {
        _chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithUserSession:_userSession
                                                                           chatSession:_chatSession];
        [_chatMessagesDataSource addListener:self];
        [_chatMessagesDataSource fetchLatest];
        [self showLoadingIndicator];
    }

    NSArray<NSString *> *keyboardNotificationNames = @[
        UIKeyboardWillShowNotification,
        UIKeyboardWillChangeFrameNotification,
        UIKeyboardWillHideNotification
    ];
    for (NSString *notificationName in keyboardNotificationNames) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:notificationName
                                                   object:nil];
    }

    [_userSession.chatSettingsDataSource addListener:self];

    [self _updateTextLabels];

    // Force layout so that animated presentations start from the right state
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_inputBarView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_inputBarView resignFirstResponder];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat avatarSize = 30.0;
    CGFloat labelSidePad = 10.0;
    CGFloat statusBarHeight = 20.0;
    CGFloat extraNavigationBarHeight = (_forNewChatSession ? 146.0 : 36.0);
    CGFloat navigationBarHeight = self.topLayoutGuide.length + extraNavigationBarHeight;

    CGFloat inputBarHeight = [self.inputBarView desiredHeight];
    CGFloat inputBarY = self.view.bounds.size.height - MAX(self.bottomLayoutGuide.length, _keyboardHeight) - inputBarHeight;
    self.inputBarView.frame = (CGRect) {
        .origin.y = inputBarY,
        .size.width = self.view.bounds.size.width,
        .size.height = inputBarHeight
    };

    self.fauxNavigationBar.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = navigationBarHeight
    };

    if (_forNewChatSession) {
        self.nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
        self.greetingLabel.font = [UIFont systemFontOfSize:13.0];

        self.avatarImageView.frame = (CGRect) {
            .origin.x = (self.fauxNavigationBar.bounds.size.width - avatarSize) / 2.0,
            .origin.y = (self.fauxNavigationBar.bounds.size.height / 2.0) - avatarSize,
            .size.width = avatarSize,
            .size.height = avatarSize
        };
        self.nameLabel.frame = (CGRect) {
            .origin.x = labelSidePad,
            .origin.y = self.avatarImageView.frame.origin.y + self.avatarImageView.frame.size.height + 8.0,
            .size.width = self.fauxNavigationBar.bounds.size.width - labelSidePad * 2.0,
            .size.height = 20.0
        };
        self.greetingLabel.frame = (CGRect) {
            .origin.x = labelSidePad,
            .origin.y = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 8.0,
            .size.width = self.fauxNavigationBar.bounds.size.width - labelSidePad * 2.0,
            .size.height = 16.0
        };
    } else {
        self.nameLabel.font = [UIFont boldSystemFontOfSize:13.0];
        self.greetingLabel.font = [UIFont systemFontOfSize:11.0];

        self.avatarImageView.frame = (CGRect) {
            .origin.x = (self.fauxNavigationBar.bounds.size.width - avatarSize) / 2.0,
            .origin.y = (self.fauxNavigationBar.bounds.size.height - extraNavigationBarHeight - avatarSize - statusBarHeight) / 2.0 + statusBarHeight,
            .size.width = avatarSize,
            .size.height = avatarSize
        };
        self.nameLabel.frame = (CGRect) {
            .origin.x = labelSidePad,
            .origin.y = self.avatarImageView.frame.origin.y + self.avatarImageView.frame.size.height + 4.0,
            .size.width = self.fauxNavigationBar.bounds.size.width - labelSidePad * 2.0,
            .size.height = 16.0
        };
        self.greetingLabel.frame = (CGRect) {
            .origin.x = labelSidePad,
            .origin.y = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 2.0,
            .size.width = self.fauxNavigationBar.bounds.size.width - labelSidePad * 2.0,
            .size.height = 13.0
        };
    }

    self.tableView.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = self.inputBarView.frame.origin.y
    };

    self.tableView.contentInset = (UIEdgeInsets) {
        .top = 4.0,
        .bottom = navigationBarHeight + 4.0
    };
    self.tableView.scrollIndicatorInsets = (UIEdgeInsets) {
        .bottom = navigationBarHeight
    };
}

#pragma mark - Interface element methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal methods

- (void)_updateTextLabels
{
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    NSString *teamName = chatSettings.teamName.length ? chatSettings.teamName : _userSession.organizationName;
    self.nameLabel.text = teamName;

    self.greetingLabel.text = chatSettings.greeting;
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _updateTextLabels];
    [self.tableView reloadData];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    [self hideLoadingIndicator];

    if (!_didLoadInitialContent) {
        [self.tableView reloadData];
        _didLoadInitialContent = YES;
    } else {
        [self.tableView reloadData];
    }

    __weak KUSChatMessagesDataSource *weakDataSource = _chatMessagesDataSource;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakDataSource fetchLatest];
    });
}

/*
- (void)paginatedDataSourceWillChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (!_didLoadInitialContent) {
        return;
    }

    [self.tableView beginUpdates];
}

- (void)paginatedDataSource:(KUSPaginatedDataSource *)dataSource
            didChangeObject:(__kindof KUSModel *)object
                    atIndex:(NSUInteger)oldIndex
              forChangeType:(KUSPaginatedDataSourceChangeType)type
                   newIndex:(NSUInteger)newIndex
{
    if (!_didLoadInitialContent) {
        return;
    }

    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldIndex inSection:0];
    UITableView *tableView = self.tableView;

    switch(type) {
        case KUSPaginatedDataSourceChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
            break;
        case KUSPaginatedDataSourceChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
            break;
        case KUSPaginatedDataSourceChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case KUSPaginatedDataSourceChangeMove:
            [tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)paginatedDataSourceDidChangeContent:(KUSPaginatedDataSource *)dataSource
{
    if (!_didLoadInitialContent) {
        return;
    }

    [self.tableView endUpdates];
}
*/

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
    static NSString *kMessageCellIdentifier = @"MessageCell";
    KUSChatMessageTableViewCell *cell = (KUSChatMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kMessageCellIdentifier];
    if (cell == nil) {
        cell = [[KUSChatMessageTableViewCell alloc] initWithReuseIdentifier:kMessageCellIdentifier userSession:_userSession];
        cell.transform = tableView.transform;
    }

    KUSChatMessage *chatMessage = [self messageForRow:indexPath.row];
    [cell setChatMessage:chatMessage];

    KUSChatMessage *previousChatMessage = [self messageBeforeRow:indexPath.row];
    BOOL previousMessageDiffSender = ![previousChatMessage.sentById isEqualToString:chatMessage.sentById];
    [cell setShowsAvatar:previousMessageDiffSender];

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
    // TODO: Support highlighting/other
    return NO;
}

#pragma mark - UITableView high-level helpers

- (BOOL)_shouldShowAutoreply
{
    NSUInteger count = [_chatMessagesDataSource count];
    KUSChatSettings *chatSettings = _userSession.chatSettingsDataSource.object;
    BOOL shouldShowAutoreply = chatSettings.autoreply.length > 0 && count > 0;
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
        NSString *autoreplyText = chatSettings.autoreply;
        chatMessage = [[KUSChatMessage alloc] initWithAutoreply:autoreplyText];
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
        return [self messageBeforeRow:row + 1];
    } else {
        return nil;
    }
}

#pragma mark - KUSInputBarDelegate methods

- (void)inputBar:(KUSInputBar *)inputBar didEnterText:(NSString *)text
{
    NSLog(@"User wants to send message: %@", text);

    // TODO: Re-implement message sending
    /*
    if (_forNewChatSession) {
        [_apiClient createChatSessionWithTitle:text completion:^(NSError *error, KUSChatSession *session) {
            if (error) {
                NSLog(@"Error creating chat session: %@", error);
                return;
            }
            NSLog(@"Successfully created chat session: %@", session);

            _forNewChatSession = NO;
            _chatSession = session;
            [self.view setNeedsLayout];

            _chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithAPIClient:_apiClient
                                                                               chatSession:_chatSession];
            [_chatMessagesDataSource addListener:self];
            [_chatMessagesDataSource fetchLatest];

            [_apiClient sendMessage:text toChatSession:session.oid completion:^(NSError *error, KUSChatMessage *message) {
                if (error) {
                    NSLog(@"Error sending message: %@", error);
                    return;
                }
                NSLog(@"Successfully sent message: %@", message);
            }];
        }];

        return;
    }

    [_apiClient sendMessage:text toChatSession:_chatSession.oid completion:^(NSError *error, KUSChatMessage *message) {
        if (error) {
            NSLog(@"Error sending message: %@", error);
            return;
        }
        NSLog(@"Successfully sent message: %@", message);
    }];
    */
}

- (void)inputBarTextDidChange:(KUSInputBar *)inputBar
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

@end
