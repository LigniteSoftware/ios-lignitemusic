//
//  MPMediaItemCollection+LigniteInfo.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"
#import "MPMediaItemCollection+LigniteInfo.h"
#import "MPMediaItem+LigniteImages.h"

@implementation MPMediaItemCollection (LigniteInfo)

- (NSString*)titleForMusicType:(uint8_t)musicType {
	if(musicType == LMMusicTypePlaylists){
		return [self valueForProperty:MPMediaPlaylistPropertyName];
	}
	if(musicType == LMMusicTypeGenres) {
		return self.representativeItem.genre;
	}
	if(musicType == LMMusicTypeCompilations){
		return self.representativeItem.albumTitle;
	}
	return @"Unknown Title";
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


@end
