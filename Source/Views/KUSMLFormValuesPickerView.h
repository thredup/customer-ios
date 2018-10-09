//
//  KUSMLFormValuesPickerView.h
//  Kustomer
//
//  Created by BrainX Technologies on 03/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KUSMLNode.h"

@class KUSMLFormValuesPickerView;
@protocol KUSMLFormValuesPickerViewDelegate <NSObject>

@optional
- (void)mlOptionPickerView:(KUSMLFormValuesPickerView *)pickerView didSelect:(NSString *)option with:(NSString *)optionId;
- (void)viewHeightDidChange;

@end

@interface KUSMLFormValuesPickerView : UIView

@property (nonatomic, strong) UIColor *horizontalSeparatorColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *verticalSeparatorColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *viewBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *selectedOptionsTextColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *highlightedSelectedOptionTextColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *textFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *sendButtonColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, weak) id<KUSMLFormValuesPickerViewDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *sendButton;

- (CGFloat)desiredHeight;
- (void)setMLFormValuesPicker:(NSArray<KUSMLNode *> *)valueTree with:(BOOL)lastNodeRequired;

@end
