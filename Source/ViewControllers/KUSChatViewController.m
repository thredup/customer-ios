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
#import "KUSInputBar.h"

@interface KUSChatViewController () <KUSInputBarDelegate, KUSPaginatedDataSourceListener, UITableViewDataSource, UITableViewDelegate> {
    KUSAPIClient *_apiClient;

    BOOL _forNewChatSession;
    KUSChatSession *_chatSession;

    KUSChatMessagesDataSource *_chatMessagesDataSource;
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
    self.navigationItem.prompt = @"Questions about Kustomer?";

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = nil;
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
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.tableView.frame = self.view.bounds;

    CGFloat inputBarHeight = 50.0;
    self.inputBarView.frame = (CGRect) {
        .origin.y = self.view.bounds.size.height - self.bottomLayoutGuide.length - inputBarHeight,
        .size.width = self.view.bounds.size.width,
        .size.height = inputBarHeight
    };

    self.tableView.contentInset = (UIEdgeInsets) {
        .top = self.topLayoutGuide.length + 3.0,
        .bottom = self.bottomLayoutGuide.length + inputBarHeight + 3.0
    };
}

#pragma mark - Interface element methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    [self.tableView reloadData];
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
    }

    KUSChatMessage *chatMessage = [_chatMessagesDataSource objectAtIndex:indexPath.row];
    [cell setChatMessage:chatMessage];

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

@end
