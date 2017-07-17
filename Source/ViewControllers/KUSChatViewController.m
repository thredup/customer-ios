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

#import "KustomerInputBarView.h"
#import "KUSAvatarTitleView.h"

@interface KUSChatViewController () <UITableViewDataSource, UITableViewDelegate> {
    KUSAPIClient *_apiClient;

    BOOL _forNewChatSession;
    KUSChatSession *_chatSession;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) KustomerInputBarView *inputBarView;

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
    self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;

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
    self.tableView.rowHeight = 88.0;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = nil;
    [self.view addSubview:self.tableView];

    self.inputBarView = [[KustomerInputBarView alloc] init];
    self.inputBarView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:self.inputBarView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.inputBarView.frame = (CGRect) {
        .origin.y = self.view.bounds.size.height - 50.0,
        .size.width = self.view.bounds.size.width,
        .size.height = 50.0
    };

    self.tableView.frame = (CGRect) {
        .size.width = self.view.bounds.size.width,
        .size.height = self.view.bounds.size.height - self.inputBarView.frame.size.height
    };
}

#pragma mark - Interface element methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kMessageCellIdentifier = @"MessageCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:kMessageCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMessageCellIdentifier];
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Support highlighting/other
    return NO;
}

@end
