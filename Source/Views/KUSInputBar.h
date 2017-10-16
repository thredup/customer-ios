//
//  KUSInputBar.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/21/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KUSInputBarDelegate;
@interface KUSInputBar : UIView

@property (nonatomic, strong) UIColor *separatorColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *textColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *textFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, copy) NSString *placeholder UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *placeholderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *sendButtonColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIKeyboardAppearance keyboardAppearance UI_APPEARANCE_SELECTOR;

@property (nonatomic, weak) id<KUSInputBarDelegate> delegate;

- (CGFloat)desiredHeight;

@end

@protocol KUSInputBarDelegate <NSObject>

@optional
- (void)inputBar:(KUSInputBar *)inputBar didEnterText:(NSString *)text;
- (void)inputBarTextDidChange:(KUSInputBar *)inputBar;

@end
