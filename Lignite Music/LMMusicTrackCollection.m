//
//  LMMusicTrackCollection.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicTrackCollection.h"

@implementation LMMusicTrackCollection

@synthesize numberOfAlbums = _numberOfAlbums;
@synthesize variousArtists = _variousArtists;
@synthesize variousGenres = _variousGenres;
@synthesize representativeItem = _representativeItem;
@synthesize persistentID = _persistentID;

- (instancetype)initWithItems:(NSArray<LMMusicTrack *> *)items basedOnSourceCollection:(id)sourceCollection {
	self = [super init];
	if(self) {
		self.items = items;
		self.count = items.count;
		self.title = @"Unknown Error";
		self.sourceCollection = sourceCollection;
	}
	else{
		NSLog(@"Error creating LMMusicTrackCollection with items %@", items);
	}
	return self;
}

- (NSUInteger)numberOfAlbums {
	NSMutableArray *albumsArray = [NSMutableArray new];
	
	for(int i = 0; i < self.count; i++){
		LMMusicTrack *musicTrack = [self.items objectAtIndex:i];
		NSString *arrayKey = [NSString stringWithFormat:@"album_%llu", musicTrack.albumPersistentID];
		
		if(![albumsArray containsObject:arrayKey]){
			[albumsArray addObject:arrayKey];
		}
	}
	
	return albumsArray.count;
}

- (BOOL)variousArtists {
	LMMusicTrack *representativeTrack = self.representativeItem;
	
	for(NSUInteger i = 0; i < self.items.count; i++){
		LMMusicTrack *track = [self.items objectAtIndex:i];
		
		//Determine whether there are various artists in this collection.
		if(![representativeTrack.artist isEqualToString:track.artist]){
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)variousGenres {
	LMMusicTrack *representativeTrack = self.representativeItem;
	
	for(NSUInteger i = 0; i < self.items.count; i++){
		LMMusicTrack *track = [self.items objectAtIndex:i];
		
		//Determine whether there are various genres in this collection.
		if(![representativeTrack.genre isEqualToString:track.genre] && track.genre != nil){
			return YES;
		}
	}
	
	return NO;
}

- (LMMusicTrack*)representativeItem {
	if(self.items.count > 0){
		return [self.items objectAtIndex:0];
	}
	
	return nil;
}

- (LMMusicTrackPersistentID)persistentID {
	return [self.sourceCollection persistentID];
}

@end
