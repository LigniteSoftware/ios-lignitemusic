//
//  LMMusicTrackCollection.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicTrackCollection.h"

@implementation LMMusicTrackCollection

- (instancetype)initWithItems:(NSArray<LMMusicTrack *> *)items {
	self = [super init];
	if(self) {
		self.items = items;
		self.count = items.count;
		if(self.items.count > 0){
			self.representativeItem = [items objectAtIndex:0];
			
			for(NSUInteger i = 0; i < self.items.count; i++){
				LMMusicTrack *track = [self.items objectAtIndex:i];
				//Determine whether there are various artists in this collection.
				if(![self.representativeItem.artist isEqualToString:track.artist] && !self.variousArtists){
					self.variousArtists = YES;
				}
				//Determine whether there are various genres in this collection.
				if(![self.representativeItem.genre isEqualToString:track.genre] && !self.variousArtists && track.genre != nil){
					self.variousGenres = YES;
				}
			}
		}
		else{
			NSLog(@"Warning: There are 0 items in this LMMusicTrackCollection.");
		}
	}
	else{
		NSLog(@"Error creating LMMusicTrackCollection with items %@", items);
	}
	return self;
}

@end
