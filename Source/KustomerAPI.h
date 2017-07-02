//
//  KustomerAPI.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/2/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KustomerAPI : NSObject

+ (instancetype)sharedInstance;

- (void)getCurrentTokens:(void(^)(NSError *error, NSDictionary *response))completion;

@end
