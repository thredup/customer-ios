//
//  KustomerWindow.m
//  Kustomer
//
//  Created by Daniel Amitay on 8/21/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KustomerWindow.h"

#import "KUSColor.h"
#import "KustomerViewController.h"

@interface KUSRootViewController : UIViewController {
    UIVisualEffectView *_blurView;
}

@property (nonatomic, strong) KustomerViewController *viewController;

@end

@implementation KustomerWindow

#pragma mark - Lifecycle methods

+ (KustomerWindow *)sharedInstance
{
    static KustomerWindow *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[KustomerWindow alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.windowLevel = UIWindowLevelNormal + 1.0;
    }
    return self;
}

#pragma mark - Public methods

- (void)showFromPoint:(CGPoint)point
{
    self.alpha = 0.0;
    self.hidden = NO;
    self.rootViewController = [[KUSRootViewController alloc] init];

    UIView *transformView = ((KUSRootViewController *)self.rootViewController).viewController.view;

    CGPoint offset = (CGPoint) {
        .x = point.x - ([UIScreen mainScreen].bounds.size.width / 2.0),
        .y = point.y - ([UIScreen mainScreen].bounds.size.height / 2.0)
    };
    CGAffineTransform transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
    transform = CGAffineTransformScale(transform, 0.1, 0.1);
    transformView.transform = transform;

    [self makeKeyAndVisible];

    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.35
                        options:kNilOptions
                     animations:^{
                         self.alpha = 1.0;
                         transformView.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

- (void)hide
{
    UIView *transformView = ((KUSRootViewController *)self.rootViewController).viewController.view;
    transformView.transform = CGAffineTransformIdentity;

    [UIView animateWithDuration:0.2
                     animations:^{
                         self.alpha = 0.0;
                         transformView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                     } completion:^(BOOL finished) {
                         if (finished) {
                             self.rootViewController = nil;
                             self.hidden = YES;
                         }
                     }];
}

@end

@implementation KUSRootViewController

#pragma mark - View methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.view addSubview:_blurView];

    _viewController = [[KustomerViewController alloc] init];
    [_viewController willMoveToParentViewController:self];
    [self.view addSubview:_viewController.view];
    [self addChildViewController:_viewController];
    [_viewController didMoveToParentViewController:_viewController];

    _viewController.view.layer.cornerRadius = 10.0;
    _viewController.view.layer.borderColor = [KUSColor darkGrayColor].CGColor;
    _viewController.view.layer.borderWidth = 0.5;
    _viewController.view.layer.masksToBounds = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _blurView.frame = self.view.bounds;
    _viewController.view.bounds = (CGRect) {
        .size.width = self.view.bounds.size.width - 14.0,
        .size.height = self.view.bounds.size.height - 20.0
    };
    _viewController.view.center = (CGPoint) {
        .x = self.view.bounds.size.width / 2.0,
        .y = self.view.bounds.size.height / 2.0
    };
}

#pragma mark - View controller methods

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [[KustomerWindow sharedInstance] hide];
}


#pragma mark - Status bar methods

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

@end
