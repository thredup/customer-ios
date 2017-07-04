//
//  KUSModel.h
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KUSModel : NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *oid;

// Relationships
@property (nonatomic, copy, readonly, nullable) NSString *orgId;
@property (nonatomic, copy, readonly, nullable) NSString *customerId;
@property (nonatomic, copy, readonly, nullable) NSString *sessionId;
@property (nonatomic, copy, readonly, nullable) NSString *sentById;

+ (NSString * _Nullable)modelType;

- (instancetype _Nullable)initWithJSON:(NSDictionary * _Nonnull)json;

@end
