//
//  KUSText.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/30/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KUSText : NSObject

+ (NSAttributedString *)attributedStringFromText:(NSString *)text fontSize:(CGFloat)fontSize;

@end
