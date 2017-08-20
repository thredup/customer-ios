//
//  KUSText.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/30/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSText.h"

#import <TSMarkdownParser/TSMarkdownParser.h>

@implementation KUSText

+ (NSAttributedString *)attributedStringFromText:(NSString *)text fontSize:(CGFloat)fontSize
{
    TSMarkdownParser *parser = [TSMarkdownParser standardParser];

    parser.defaultAttributes = KUSAttributedFontWithSize(parser.defaultAttributes, fontSize);
    parser.imageAttributes = KUSAttributedFontWithSize(parser.imageAttributes, fontSize);
    parser.linkAttributes = KUSAttributedFontWithSize(parser.linkAttributes, fontSize);
    parser.monospaceAttributes = KUSAttributedFontWithSize(parser.monospaceAttributes, fontSize);
    parser.strongAttributes = KUSAttributedFontWithSize(parser.strongAttributes, fontSize);
    parser.emphasisAttributes = KUSAttributedFontWithSize(parser.emphasisAttributes, fontSize);

    return [parser attributedStringFromMarkdown:text];
}

NSDictionary<NSString *, id> *KUSAttributedFontWithSize(NSDictionary<NSString *, id> *attributes, CGFloat fontSize) {
    UIFont *currentFont = [attributes objectForKey:NSFontAttributeName];
    if (currentFont == nil || currentFont.pointSize == fontSize) {
        return attributes;
    }
    NSMutableDictionary<NSString *, id> *mutableAttributes = [attributes mutableCopy];
    UIFont *newFont = [UIFont fontWithName:currentFont.fontName size:fontSize];
    [mutableAttributes setObject:newFont forKey:NSFontAttributeName];
    return mutableAttributes;
};


@end
