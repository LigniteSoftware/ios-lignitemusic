//
//  LMMusicTrack.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMMusicTrack.h"
#import "LMMusicPlayer.h"

@interface LMMusicTrack()

@property UIImage *loadedAlbumArt;

@end

@implementation LMMusicTrack

- (instancetype)initWithMPMediaItem:(MPMediaItem*)item {
	self = [super init];
	if(self) {
		self.title = item.title;
		self.artist = item.artist;
		self.albumTitle = item.albumTitle;
		self.genre = item.genre;
		
		self.persistentID = item.persistentID;
		self.albumArtistPersistentID = item.albumArtistPersistentID;
		self.albumPersistentID = item.albumPersistentID;
		self.artistPersistentID = item.artistPersistentID;
		self.composerPersistentID = item.composerPersistentID;
		self.genrePersistentID = item.genrePersistentID;
		
		self.playbackDuration = item.playbackDuration;
		
		self.sourceTrack = item;
	}
	else{
		NSLog(@"Error creating LMMusicTrack with MPMediaItem %@!", item);
	}
	return self;
}

- (UIImage*)albumArt {
	if(self.loadedAlbumArt){
		return self.loadedAlbumArt;
	}
	
	LMMusicPlayerType currentPlayerType = [LMMusicPlayer savedPlayerType];
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMediaItem *mediaItem = self.sourceTrack;
		
		UIImage *image = [mediaItem.artwork imageWithSize:CGSizeMake(500, 500)];
		self.loadedAlbumArt = image;
		
		return image;
	}
	
	NSLog(@"Warning: Album art image not found for track %@.", self.title);
	
	return nil;
}

@end
