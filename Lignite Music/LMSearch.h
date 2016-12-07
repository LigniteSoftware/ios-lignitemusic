//
//  LMSearch.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPMediaItemCollection;

@interface LMSearch : NSObject

+ (NSArray<NSArray<MPMediaItemCollection*>*>*)searchResultsForString:(NSString*)string;

@end
