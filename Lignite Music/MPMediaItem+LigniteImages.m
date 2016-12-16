//
//  MPMediaItem+LigniteImages.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "MPMediaItem+LigniteImages.h"
#import "LMMusicPlayer.h"
#import "LMImageManager.h"

@implementation MPMediaItem (LigniteImages)

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
		MPMediaItem *mediaItem = self;
		
		//Get the standard album artwork
		UIImage *albumArtImage = [mediaItem.artwork imageWithSize:CGSizeMake(480, 480)];
		if(!albumArtImage){
			//If not found search the image cache for it
			albumArtImage = [[LMImageManager sharedImageManager] imageForMediaItem:self withCategory:LMImageManagerCategoryAlbumImages];
		}
		
		return albumArtImage;
	}
	
	NSLog(@"Warning: Album art image not found for track %@.", self.title);
	
	return nil;
}

- (UIImage*)artistImage {
	LMMusicPlayerType currentPlayerType = [[LMMusicPlayer sharedMusicPlayer] playerType];
	
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer || currentPlayerType == LMMusicPlayerTypeAppleMusic){
		UIImage *artistImage = [[LMImageManager sharedImageManager] imageForMediaItem:self withCategory:LMImageManagerCategoryArtistImages];
		
		if(!artistImage) {
			artistImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		}
		
		return artistImage;
	}
	
	NSLog(@"Warning: Artist image not found for track %@.", self.title);
	
	return nil;
}

@end
