//
//
// Copyright (c) 2016 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@protocol FYBURLParametersProvider<NSObject>

@required
- (NSDictionary *)dictionaryWithKeyValueParameters;

@end
