//
//  KUSTextView.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/24/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSTextView : UITextView

@property (nonatomic, copy) NSString *placeholder;

- (NSUInteger)maxNumberOfLines;
- (NSUInteger)numberOfLines;
- (CGFloat)desiredHeight;

@end
