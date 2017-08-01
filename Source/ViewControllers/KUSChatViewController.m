//
//  KUSChatViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSChatViewController.h"

#import "KUSAPIClient.h"
#import "KUSChatSession.h"

#import "KUSAvatarTitleView.h"
#import "KUSChatMessagesDataSource.h"
#import "KUSChatMessageTableViewCell.h"
#import "KUSChatSettingsDataSource.h"
#import "KUSInputBar.h"

@interface KUSChatViewController () <KUSInputBarDelegate, KUSObjectDataSourceListener, KUSPaginatedDataSourceListener, UITableViewDataSource, UITableViewDelegate> {
    KUSAPIClient *_apiClient;

    BOOL _forNewChatSession;
    KUSChatSession *_chatSession;
    KUSChatMessagesDataSource *_chatMessagesDataSource;
    KUSChatSettingsDataSource *_chatSettingsDataSource;
    BOOL _didLoadInitialContent;

    CGFloat _keyboardHeight;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) KUSInputBar *inputBarView;

@end

@implementation KUSChatViewController

#pragma mark - Lifecycle methods

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient
{
    self = [super init];
    if (self) {
        _apiClient = apiClient;

        self.navigationItem.titleView = [[KUSAvatarTitleView alloc] init];
    }
    return self;
}

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient forChatSession:(KUSChatSession *)session
{
    self = [self initWithAPIClient:apiClient];
    if (self) {
        _chatSession = session;
    }
    return self;
}

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient forNewSessionWithBackButton:(BOOL)showBackButton
{
    self = [self initWithAPIClient:apiClient];
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

    self.inputBarView = [[KUSInputBar alloc] init];
    self.inputBarView.delegate = self;
    self.inputBarView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:self.inputBarView];

    if (_chatSession) {
        _chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithAPIClient:_apiClient
                                                                           chatSession:_chatSession];
        [_chatMessagesDataSource addListener:self];
        [_chatMessagesDataSource fetchLatest];
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

    _chatSettingsDataSource = [[KUSChatSettingsDataSource alloc] initWithAPIClient:_apiClient];
    [_chatSettingsDataSource fetch];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_chatSettingsDataSource addListener:self];
    [self _updatePromptText];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat inputBarHeight = [self.inputBarView desiredHeight];
    CGFloat inputBarY = self.view.bounds.size.height - MAX(self.bottomLayoutGuide.length, _keyboardHeight) - inputBarHeight;
    self.inputBarView.frame = (CGRect) {
        .origin.y = inputBarY,
        .size.width = self.view.bounds.size.width,
        .size.height = inputBarHeight
    };

    self.tableView.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = self.inputBarView.frame.origin.y
    };

    self.tableView.contentInset = (UIEdgeInsets) {
        .top = 4.0,
        .bottom = self.topLayoutGuide.length + 4.0
    };
    self.tableView.scrollIndicatorInsets = (UIEdgeInsets) {
        .bottom = self.topLayoutGuide.length
    };
}

#pragma mark - Interface element methods

- (void)_dismiss
{
    [self.view endEditing:YES];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal methods

- (void)_updatePromptText
{
    KUSChatSettings *chatSettings = [_chatSettingsDataSource object];
    self.navigationItem.prompt = chatSettings.greeting;
}

#pragma mark - KUSObjectDataSourceListener methods

- (void)objectDataSourceDidLoad:(KUSObjectDataSource *)dataSource
{
    [self _updatePromptText];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    if (!_didLoadInitialContent) {
        [self.tableView reloadData];
        _didLoadInitialContent = YES;
    }
}

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

#pragma mark - NSNotification methods

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];

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
        CGPoint offset = CGPointMake(0.0, scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom);
        [scrollView setContentOffset:offset animated:YES];
    }
    return NO;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _chatMessagesDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kMessageCellIdentifier = @"MessageCell";
    KUSChatMessageTableViewCell *cell = (KUSChatMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kMessageCellIdentifier];
    if (cell == nil) {
        cell = [[KUSChatMessageTableViewCell alloc] initWithReuseIdentifier:kMessageCellIdentifier];
        cell.transform = tableView.transform;
    }

    NSInteger numberOfRows = [tableView numberOfRowsInSection:indexPath.section];
    NSInteger row = indexPath.row;

    KUSChatMessage *chatMessage = [_chatMessagesDataSource objectAtIndex:row];
    [cell setChatMessage:chatMessage];

    KUSChatMessage *previousChatMessage = (row < numberOfRows - 1 ? [_chatMessagesDataSource objectAtIndex:row + 1] : nil);
    BOOL previousMessageDiffSender = ![previousChatMessage.sentById isEqualToString:chatMessage.sentById];
    [cell setShowsAvatar:previousMessageDiffSender];

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KUSChatMessage *chatMessage = [_chatMessagesDataSource objectAtIndex:indexPath.row];
    return [KUSChatMessageTableViewCell heightForChatMessage:chatMessage maxWidth:tableView.bounds.size.width];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Support highlighting/other
    return NO;
}

#pragma mark - KUSInputBarDelegate methods

- (void)inputBar:(KUSInputBar *)inputBar didEnterText:(NSString *)text
{
    NSLog(@"User wants to send message: %@", text);

    if (_forNewChatSession) {
        [_apiClient createChatSessionWithTitle:text completion:^(NSError *error, KUSChatSession *session) {
            if (error) {
                NSLog(@"Error creating chat session: %@", error);
                return;
            }
            NSLog(@"Successfully created chat session: %@", session);

            _forNewChatSession = NO;
            _chatSession = session;
            _chatMessagesDataSource = [[KUSChatMessagesDataSource alloc] initWithAPIClient:_apiClient
                                                                               chatSession:_chatSession];
            [_chatMessagesDataSource addListener:self];

            [_apiClient sendMessage:text toChatSession:session.oid completion:^(NSError *error, KUSChatMessage *message) {
                if (error) {
                    NSLog(@"Error sending message: %@", error);
                    return;
                }
                NSLog(@"Successfully sent message: %@", message);
                [_chatMessagesDataSource fetchLatest];
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

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_chatMessagesDataSource fetchLatest];
        });
    }];
}

- (void)inputBarTextDidChange:(KUSInputBar *)inputBar
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

@end
