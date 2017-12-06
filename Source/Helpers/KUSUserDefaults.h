//
//  KUSUserDefaults.h
//  Kustomer
//
//  Created by Daniel Amitay on 12/6/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KUSUserSession;
@interface KUSUserDefaults : NSObject

@property (nonatomic, assign) BOOL didCaptureEmail;
@property (nonatomic, copy, nullable) NSString *trackingToken;

- (instancetype)initWithUserSession:(KUSUserSession *)userSession;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)reset;

@end
