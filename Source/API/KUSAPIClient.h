//
//  KUSAPIClient.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KUSTrackingToken.h"

@interface KUSAPIClient : NSObject

- (instancetype)initWithOrgName:(NSString *)orgName;

- (void)getCurrentTrackingToken:(void(^)(NSError *error, KUSTrackingToken *trackingToken))completion;

- (instancetype)init NS_UNAVAILABLE;

@end
