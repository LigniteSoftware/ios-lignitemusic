//
//  LMPlaylist.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMPlaylist.h"

@interface LMPlaylist()

@end

@implementation LMPlaylist

@synthesize trackCollection = _trackCollection;

- (LMMusicTrackCollection*)trackCollection {
	if(self.enhanced){
		return [[LMMusicTrackCollection alloc]initWithItems:@[]];
	}
	
	return _trackCollection;
}

- (void)setTrackCollection:(LMMusicTrackCollection *)trackCollection {
	_trackCollection = trackCollection;
}

- (void)regenerateEnhancedPlaylist {
	NSAssert(self.enhanced, @"Attempt to regenerate a playlist that's not enhanced.");
	
	NSLog(@"Regenerate me");
}

@end
