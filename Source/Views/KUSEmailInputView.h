//
//  KUSEmailInputView.h
//  Kustomer
//
//  Created by Daniel Amitay on 8/26/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KUSEmailInputViewDelegate;
@interface KUSEmailInputView : UIView

@property (nonatomic, weak) id<KUSEmailInputViewDelegate> delegate;

@end

@protocol KUSEmailInputViewDelegate <NSObject>

- (void)emailInputView:(KUSEmailInputView *)inputView didSubmitEmail:(NSString *)email;

@end
