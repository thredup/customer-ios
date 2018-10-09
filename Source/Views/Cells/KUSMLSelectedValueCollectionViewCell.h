//
//  KUSMLSelectedValueCollectionViewCell.h
//  Kustomer
//
//  Created by BrainX Technologies on 03/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KUSMLSelectedValueCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UIColor *cellBackgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;
@property (nonatomic, strong) UIColor *verticalSeparatorColor;
@property (nonatomic, strong) NSString *value;

- (void)setCellValue:(NSString *)value withFirsCell:(BOOL)first andLastCell:(BOOL)last;
@end
