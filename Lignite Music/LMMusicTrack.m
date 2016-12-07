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

@implementation LMMusicTrack

@synthesize title = _title;
@synthesize artist = _artist;
@synthesize albumTitle = _albumTitle;
@synthesize genre = _genre;
@synthesize composer = _composer;

@synthesize persistentID = _persistentID;
@synthesize albumPersistentID = _albumPersistentID;
@synthesize albumArtistPersistentID = _albumArtistPersistentID;
@synthesize artistPersistentID = _artistPersistentID;
@synthesize composerPersistentID = _composerPersistentID;
@synthesize genrePersistentID = _genrePersistentID;

@synthesize playbackDuration = _playbackDuration;

- (instancetype)initWithMPMediaItem:(MPMediaItem*)item {
	self = [super init];
	if(self) {
		self.sourceTrack = item;
	}
	else{
		NSLog(@"Error creating LMMusicTrack with MPMediaItem %@!", item);
	}
	return self;
}

//- (LMMusicPlayerType)playerType {
//	return [[LMMusicPlayer sharedMusicPlayer] playerType];
//}

- (NSString*)title {
	return [(MPMediaItem*)self.sourceTrack title];
}

- (NSString*)artist {
	return [(MPMediaItem*)self.sourceTrack artist];
}

- (NSString*)albumTitle {
	NSString *sourceTrackAlbumTitle = [(MPMediaItem*)self.sourceTrack albumTitle];
	return [sourceTrackAlbumTitle isEqualToString:@""] ? nil : sourceTrackAlbumTitle;
}

- (NSString*)genre {
	return [(MPMediaItem*)self.sourceTrack genre];
}

- (NSString*)composer {
	return [(MPMediaItem*)self.sourceTrack composer];
}

- (LMMusicTrackPersistentID)persistentID {
	return [(MPMediaItem*)self.sourceTrack persistentID];
}

- (LMMusicTrackPersistentID)albumArtistPersistentID {
	return [(MPMediaItem*)self.sourceTrack albumArtistPersistentID];
}

- (LMMusicTrackPersistentID)albumPersistentID {
	return [(MPMediaItem*)self.sourceTrack albumPersistentID];
}

- (LMMusicTrackPersistentID)artistPersistentID {
	return [(MPMediaItem*)self.sourceTrack artistPersistentID];
}

- (LMMusicTrackPersistentID)composerPersistentID {
	return [(MPMediaItem*)self.sourceTrack composerPersistentID];
}

- (LMMusicTrackPersistentID)genrePersistentID {
	return [(MPMediaItem*)self.sourceTrack genrePersistentID];
}

- (NSTimeInterval)playbackDuration {
	return [(MPMediaItem*)self.sourceTrack playbackDuration];
}

- (UIImage*)albumArt {
	//Get the album artwork
	UIImage *albumArtImage = [self uncorrectedAlbumArt];

	//If that's not found, default back to no album art image
	if(!albumArtImage){
		albumArtImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	
	return albumArtImage;
}

- (UIImage*)uncorrectedAlbumArt {
	LMMusicPlayerType currentPlayerType = [[LMMusicPlayer sharedMusicPlayer] playerType];
	
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer || currentPlayerType == LMMusicPlayerTypeAppleMusic){
		MPMediaItem *mediaItem = self.sourceTrack;
		
		//Get the standard album artwork
		UIImage *albumArtImage = [mediaItem.artwork imageWithSize:CGSizeMake(480, 480)];
		if(!albumArtImage){
			//If not found search the image cache for it
			albumArtImage = [[LMImageManager sharedImageManager] imageForMusicTrack:self withCategory:LMImageManagerCategoryAlbumImages];
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
		
		if(!artistImage) {
			artistImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		}
		
		return artistImage;
	}
	
	NSLog(@"Warning: Artist image not found for track %@.", self.title);
	
	return nil;
}

@end
