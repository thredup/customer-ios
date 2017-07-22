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

@property (nonatomic, weak) id<KUSInputBarDelegate> delegate;

@end

@protocol KUSInputBarDelegate <NSObject>

@optional

- (void)inputBar:(KUSInputBar *)inputBar didEnterText:(NSString *)text;

@end
