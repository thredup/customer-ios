//
//  KUSSessionsViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSSessionsViewController.h"

#import "KUSAPIClient.h"
#import "KUSChatViewController.h"
#import "KustomerPlaceholderTableViewCell.h"
#import "KustomerSessionTableViewCell.h"

#import "KUSAvatarTitleView.h"
#import "KUSImage.h"

@interface KUSSessionsViewController () <UITableViewDataSource, UITableViewDelegate> {
    KUSAPIClient *_apiClient;

    NSArray<KUSChatSession *> *_chatSessions;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *createSessionButton;

@end

@implementation KUSSessionsViewController

#pragma mark - Lifecycle methods

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient
{
    self = [super init];
    if (self) {
        _apiClient = apiClient;
    }
    return self;
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                   target:self
                                                                                   action:@selector(_dismiss)];
    barButtonItem.style = UIBarButtonItemStyleDone;
    self.navigationItem.rightBarButtonItem = barButtonItem;

    self.navigationItem.titleView = [[KUSAvatarTitleView alloc] init];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 88.0;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:self.tableView];

    UIColor *blueColor = [UIColor colorWithRed:66.0/255.0
                                         green:130.0/255.0
                                          blue:252.0/255.0
                                         alpha:1.0];
    CGFloat buttonRadius = 4.0;
    CGSize size = CGSizeMake(buttonRadius * 2.0, buttonRadius * 2.0);
    UIImage *circularImage = [KUSImage circularImageWithSize:size color:blueColor];
    UIEdgeInsets capInsets = UIEdgeInsetsMake(buttonRadius, buttonRadius, buttonRadius, buttonRadius);
    UIImage *buttonImage = [circularImage resizableImageWithCapInsets:capInsets];

    // TODO: Encapsulate into class
    self.createSessionButton = [[UIButton alloc] init];
    self.createSessionButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin
                                                 | UIViewAutoresizingFlexibleLeftMargin
                                                 | UIViewAutoresizingFlexibleRightMargin);
    [self.createSessionButton setTitle:@"New Conversation" forState:UIControlStateNormal];
    self.createSessionButton.titleLabel.textColor = [UIColor whiteColor];
    self.createSessionButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [self.createSessionButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    self.createSessionButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.createSessionButton.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.createSessionButton.layer.shadowRadius = 1.0;
    self.createSessionButton.layer.shadowOpacity = 0.5;
    [self.createSessionButton addTarget:self
                                 action:@selector(_createSession)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createSessionButton];

    self.tableView.hidden = YES;
    self.createSessionButton.hidden = YES;
    [self _fetchLatestChatSessions];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.tableView.frame = self.view.bounds;

    // TODO: Extract layout constants
    CGSize createSessionButtonSize = CGSizeMake(182.0, 44.0);
    self.createSessionButton.frame = (CGRect) {
        .origin.x = (self.view.bounds.size.width - createSessionButtonSize.width) / 2.0,
        .origin.y = self.view.bounds.size.height - createSessionButtonSize.height - 23.0,
        .size = createSessionButtonSize
    };
}

#pragma mark - Interface element methods

- (void)_createSession
{
    KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                     forNewSessionWithBackButton:YES];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal methods

- (void)_fetchLatestChatSessions
{
    __weak KUSSessionsViewController *weakSelf = self;
    [_apiClient getChatSessions:^(NSError *error, KUSPaginatedResponse *chatSessions) {
        [weakSelf _handleChatSessionsResponse:chatSessions error:error];
    }];
}

- (void)_handleChatSessionsResponse:(KUSPaginatedResponse *)response error:(NSError *)error
{
    if (response) {
        _chatSessions = response.objects;
        // _chatSessions = @[ [KUSChatSession new] ];
        // _chatSessions = @[ [KUSChatSession new], [KUSChatSession new] ];
        [self.tableView reloadData];

        self.tableView.hidden = NO;
        self.createSessionButton.hidden = NO;

        if (_chatSessions.count == 0) {
            // If there are no existing chat sessions, go directly to new chat screen
            KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                             forNewSessionWithBackButton:NO];
            [self.navigationController pushViewController:chatViewController animated:NO];
        } else if (_chatSessions.count == 1) {
            // If there is exactly one chat session, go directly to it
            KUSChatSession *chatSession = _chatSessions.firstObject;
            KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                                          forChatSession:chatSession];
            [self.navigationController pushViewController:chatViewController animated:NO];
        }
    } else {

    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CGFloat visibleTableHeight = tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom;
    CGFloat rowCountThatFitsHeight = visibleTableHeight / tableView.rowHeight;
    NSUInteger minimumRowCount = (NSUInteger)floor(rowCountThatFitsHeight);
    return MAX(_chatSessions.count, minimumRowCount);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSessionRow = indexPath.row < _chatSessions.count;
    if (isSessionRow) {
        static NSString *kSessionCellIdentifier = @"SessionCell";
        KustomerSessionTableViewCell *cell = (KustomerSessionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kSessionCellIdentifier];
        if (cell == nil) {
            cell = [[KustomerSessionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSessionCellIdentifier];
        }
        return cell;
    }

    static NSString *kPlaceholderCellIdentifier = @"PlaceholderCell";
    KustomerPlaceholderTableViewCell *cell = (KustomerPlaceholderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kPlaceholderCellIdentifier];
    if (cell == nil) {
        cell = [[KustomerPlaceholderTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlaceholderCellIdentifier];
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    KUSChatSession *chatSession = [_chatSessions objectAtIndex:indexPath.row];
    KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient forChatSession:chatSession];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSessionRow = indexPath.row < _chatSessions.count;
    return isSessionRow;
}

@end
