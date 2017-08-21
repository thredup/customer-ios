//
//  KUSFauxNavigationBar.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSUserSession;
@interface KUSFauxNavigationBar : UIView

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, assign) BOOL showsLabels;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (CGFloat)desiredHeightWithTopInset:(CGFloat)topInset;

@end
