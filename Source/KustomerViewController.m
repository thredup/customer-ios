//
//  KustomerViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerViewController.h"

#import "Kustomer_Private.h"

#import "KUSSessionsViewController.h"

@interface KustomerViewController ()

@end

@implementation KustomerViewController

- (instancetype)init
{
    KUSAPIClient *apiClient = [Kustomer sharedInstance].apiClient;
    KUSSessionsViewController *sessionsViewController = [[KUSSessionsViewController alloc] initWithAPIClient:apiClient];
    return [super initWithRootViewController:sessionsViewController];
}

@end
