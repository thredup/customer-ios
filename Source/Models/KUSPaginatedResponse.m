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
        _page = IntegerFromKeyPath(json, @"meta.page");
        _pageSize = IntegerFromKeyPath(json, @"meta.pageSize");

        NSArray<NSDictionary *> *jsonObjects = json[@"data"];
        NSMutableArray<__kindof KUSModel *> *objects = [[NSMutableArray alloc] init];
        for (NSDictionary *jsonObject in jsonObjects) {
            KUSModel *model = [[modelClass alloc] initWithJSON:jsonObject];
            if (model) {
                [objects addObject:model];
            }
        }
        _objects = objects;

        _selfURL = NSURLFromKeyPath(json, @"links.self");
        _firstURL = NSURLFromKeyPath(json, @"links.first");
        _prevURL = NSURLFromKeyPath(json, @"links.prev");
        _nextURL = NSURLFromKeyPath(json, @"links.next");
    }
    return self;
}

@end
