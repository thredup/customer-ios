//
//  Kustomer_Private.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/2/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

@interface Kustomer (Private)

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, copy, readonly) NSString *orgId;
@property (nonatomic, copy, readonly) NSString *orgName;

+ (instancetype)sharedInstance;

@end
