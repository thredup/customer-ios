//
//  KustomerSessionsViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/3/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerSessionsViewController.h"

#import "KustomerSessionTableViewCell.h"

@interface KustomerSessionsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *createSessionButton;

@end

@implementation KustomerSessionsViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 80.0;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:self.tableView];

    // TODO: Encapsulate into class
    self.createSessionButton = [[UIButton alloc] init];
    [self.createSessionButton setTitle:@"New Conversation" forState:UIControlStateNormal];
    self.createSessionButton.titleLabel.textColor = [UIColor whiteColor];
    self.createSessionButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    self.createSessionButton.backgroundColor = [UIColor colorWithRed:66.0/255.0
                                                               green:130.0/255.0
                                                                blue:252.0/255.0
                                                               alpha:1.0];
    self.createSessionButton.layer.cornerRadius = 4.0;
    self.createSessionButton.layer.masksToBounds = YES;
    [self.view addSubview:self.createSessionButton];
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kSessionCellIdentifier = @"SessionCell";
    KustomerSessionTableViewCell *cell = (KustomerSessionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kSessionCellIdentifier];
    if (cell == nil) {
        cell = [[KustomerSessionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSessionCellIdentifier];
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
