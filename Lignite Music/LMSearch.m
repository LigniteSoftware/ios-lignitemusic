//
//  LMSearch.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSearch.h"
#import "LMMusicPlayer.h"

@implementation LMSearch

MPMediaGrouping associatedMediaTypes[] = {
	MPMediaGroupingArtist,
	MPMediaGroupingAlbum,
	MPMediaGroupingTitle,
	MPMediaGroupingPlaylist,
	MPMediaGroupingComposer,
	MPMediaGroupingGenre
};

+ (NSArray<NSArray<MPMediaItemCollection*>*>*)searchResultsForString:(NSString*)string {
	NSMutableArray<NSArray<MPMediaItemCollection*>*> *searchResults;
	
	for(NSUInteger baseIndex = 0; baseIndex < (6); baseIndex++){
		MPMediaGrouping associatedMediaGrouping = associatedMediaTypes[baseIndex];
		
		MPMediaQuery *baseQuery = [[MPMediaQuery alloc]init];
		baseQuery.groupingType = associatedMediaGrouping;
		
		NSLog(@"Got %d collections for %d.", (int)baseQuery.collections.count, (int)baseIndex);
	}
	
	return [NSArray arrayWithArray:searchResults];
}

@end
