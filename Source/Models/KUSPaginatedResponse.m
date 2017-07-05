//
//  KUSPaginatedResponse.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/4/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSPaginatedResponse.h"

#import "KUSModel.h"

@implementation KUSPaginatedResponse

#pragma mark - Lifecycle methods

- (instancetype _Nullable)initWithJSON:(NSDictionary * _Nonnull)json modelClass:(Class _Nonnull)modelClass
{
    // TODO: Assert that modelClass is a subclass of KUSModel

    // There needs to be json to parse
    if (![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    // There needs to be meta, data, and links properties
    if (!json[@"meta"] || !json[@"data"] || !json[@"links"]) {
        return nil;
    }

    // The data needs to be an array
    if (![json[@"data"] isKindOfClass:[NSArray class]]) {
        return nil;
    }

    // Actually create the object
    self = [super init];
    if (self) {
        _page = [[json valueForKeyPath:@"meta.page"] integerValue];
        _pageSize = [[json valueForKeyPath:@"meta.pageSize"] integerValue];

        NSArray<NSDictionary *> *jsonObjects = json[@"data"];
        NSMutableArray<__kindof KUSModel *> *objects = [[NSMutableArray alloc] init];
        for (NSDictionary *jsonObject in jsonObjects) {
            KUSModel *model = [[modelClass alloc] initWithJSON:jsonObject];
            if (model) {
                [objects addObject:model];
            }
        }
        _objects = objects;

        _selfURL = SafeNSURLFromString([json valueForKeyPath:@"links.self"]);
        _firstURL = SafeNSURLFromString([json valueForKeyPath:@"links.first"]);
        _prevURL = SafeNSURLFromString([json valueForKeyPath:@"links.prev"]);
        _nextURL = SafeNSURLFromString([json valueForKeyPath:@"links.next"]);
    }
    return self;
}

NSURL *_Nullable SafeNSURLFromString(NSString * _Nullable string) {
    if ((NSNull *)string == [NSNull null]) {
        return nil;
    }
    if (string.length > 0) {
        return [NSURL URLWithString:string];
    }
    return nil;
}

@end
