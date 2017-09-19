//
//  KUSNotificationWindow.m
//  Kustomer
//
//  Created by Daniel Amitay on 9/18/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSNotificationWindow.h"

#import "KUSChatSessionTableViewCell.h"

static const CGFloat KUSNotificationWindowShowDuration = 0.3;
static const CGFloat KUSNotificationWindowHideDuration = 0.2;
static const CGFloat KUSNotificationWindowVisibleDuration = 3.0;

static const CGFloat KUSNotificationWindowMaxWidth = 400.0;

@interface KUSNotificationWindow () {
    KUSChatSessionTableViewCell *_sessionTableViewCell;
    NSTimer *_hideTimer;
}

@end

@implementation KUSNotificationWindow

#pragma mark - Lifecycle methods

+ (KUSNotificationWindow *)sharedInstance
{
    static KUSNotificationWindow *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KUSNotificationWindow alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.windowLevel = UIWindowLevelStatusBar + 1.0;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        self.layer.shadowRadius = 3.0;
        self.layer.shadowOpacity = 0.4;

        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.view.clipsToBounds = YES;
        self.rootViewController = viewController;

        [self _layoutWindow];

        self.alpha = 0.0;
        self.hidden = NO;
        self.transform = CGAffineTransformMakeTranslation(0.0, -KUSChatSessionTableViewCellHeight);
    }
    return self;
}

- (void)_layoutWindow
{
    CGFloat windowWidth = MIN([UIScreen mainScreen].bounds.size.width, KUSNotificationWindowMaxWidth);
    self.bounds = (CGRect) {
        .size.width = windowWidth,
        .size.height = KUSChatSessionTableViewCellHeight
    };
    self.center = (CGPoint) {
        .x = [UIScreen mainScreen].bounds.size.width / 2.0,
        .y = KUSChatSessionTableViewCellHeight / 2.0
    };
}

#pragma mark - Public methods

- (void)showChatSession:(KUSChatSession *)chatSession userSession:(KUSUserSession *)userSession;
{
    [self _layoutWindow];

    [_sessionTableViewCell removeFromSuperview];

    _sessionTableViewCell = [[KUSChatSessionTableViewCell alloc] initWithReuseIdentifier:nil userSession:userSession];
    _sessionTableViewCell.frame = self.bounds;
    _sessionTableViewCell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_sessionTableViewCell setChatSession:chatSession];
    [self addSubview:_sessionTableViewCell];

    [UIView
     animateWithDuration:KUSNotificationWindowShowDuration
     delay:0.0
     options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
     animations:^{
         self.alpha = 1.0;
         self.transform = CGAffineTransformIdentity;
     } completion:nil];

    [_hideTimer invalidate];
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:KUSNotificationWindowShowDuration + KUSNotificationWindowVisibleDuration
                                                  target:self
                                                selector:@selector(hide)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)hide
{
    [_hideTimer invalidate];
    _hideTimer = nil;

    [UIView
     animateWithDuration:KUSNotificationWindowHideDuration
     delay:0.0
     options:UIViewAnimationOptionAllowUserInteraction
     animations:^{
         self.alpha = 0.0;
         self.transform = CGAffineTransformMakeTranslation(0.0, -KUSChatSessionTableViewCellHeight);
     } completion:^(BOOL finished) {
         if (finished) {
             [_sessionTableViewCell removeFromSuperview];
             _sessionTableViewCell = nil;
         }
     }];
}

@end
