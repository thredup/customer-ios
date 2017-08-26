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
            NSArray<__kindof KUSModel *> *models = [modelClass objectsWithJSON:jsonObject];
            for (__kindof KUSModel *model in [models reverseObjectEnumerator]) {
                [objects addObject:model];
            }
        }
        _objects = objects;

        _selfPath = NSStringFromKeyPath(json, @"links.self");
        _firstPath = NSStringFromKeyPath(json, @"links.first");
        _prevPath = NSStringFromKeyPath(json, @"links.prev");
        _nextPath = NSStringFromKeyPath(json, @"links.next");
    }
    return self;
}

@end
