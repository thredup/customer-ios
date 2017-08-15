//
//  Kustomer_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/2/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "Kustomer.h"

@class KUSUserSession;
@interface Kustomer (Private)

+ (instancetype)sharedInstance;

- (KUSUserSession *)userSession;

@end
