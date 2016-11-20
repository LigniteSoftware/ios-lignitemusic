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
#import "LMImageManager.h"

@interface LMMusicTrack()

@end

@implementation LMMusicTrack

- (instancetype)initWithMPMediaItem:(MPMediaItem*)item {
	self = [super init];
	if(self) {
		self.title = item.title;
		self.artist = item.artist;
		self.albumTitle = [item.albumTitle isEqualToString:@""] ? nil : item.albumTitle;
		self.genre = item.genre;
		
		self.persistentID = item.persistentID;
		self.albumArtistPersistentID = item.albumArtistPersistentID;
		self.albumPersistentID = item.albumPersistentID;
		self.artistPersistentID = item.artistPersistentID;
		self.composerPersistentID = item.composerPersistentID;
		self.genrePersistentID = item.genrePersistentID;
		
		self.playbackDuration = item.playbackDuration;
		
		self.sourceTrack = item;
		
		//NSLog(@"Creating image");
		//[item.artwork imageWithSize:item.artwork.bounds.size];
		//NSLog(@"Created image with size %@", NSStringFromCGRect(item.artwork.bounds));
	}
	else{
		NSLog(@"Error creating LMMusicTrack with MPMediaItem %@!", item);
	}
	return self;
}

- (UIImage*)albumArt {
	LMMusicPlayerType currentPlayerType = [[LMMusicPlayer sharedMusicPlayer] playerType];
	
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer || currentPlayerType == LMMusicPlayerTypeAppleMusic){
		MPMediaItem *mediaItem = self.sourceTrack;
		
		//Get the standard album artwork
		UIImage *albumArtImage = [mediaItem.artwork imageWithSize:CGSizeMake(480, 480)];
		if(!albumArtImage){
			//If not found search the image cache for it
			albumArtImage = [[LMImageManager sharedImageManager] imageForMusicTrack:self withCategory:LMImageManagerCategoryAlbumImages];
			
			//If that's not found too, default back to no album art image
			if(!albumArtImage){
				albumArtImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
			}
		}
		
		return albumArtImage;
	}
	
	NSLog(@"Warning: Album art image not found for track %@.", self.title);
	
	return nil;
}

- (UIImage*)artistImage {
	LMMusicPlayerType currentPlayerType = [[LMMusicPlayer sharedMusicPlayer] playerType];
	
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer || currentPlayerType == LMMusicPlayerTypeAppleMusic){
		UIImage *artistImage = [[LMImageManager sharedImageManager] imageForMusicTrack:self withCategory:LMImageManagerCategoryArtistImages];
			
		if(!artistImage){
//			artistImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
		}
		
		return artistImage;
	}
	
	NSLog(@"Warning: Artist image not found for track %@.", self.title);
	
	return nil;
}

@end
