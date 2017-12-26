//
//  KUSNavigationBarView.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KUSUserSession;
@interface KUSNavigationBarView : UIView

@property (nonatomic, strong) UIColor *nameColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *nameFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *greetingColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *greetingFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *separatorColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, assign) BOOL showsLabels;
@property (nonatomic, assign) BOOL extraLarge;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (CGFloat)desiredHeightWithTopInset:(CGFloat)topInset;

@end
