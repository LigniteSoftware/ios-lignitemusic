//
//  MPMediaItem+LigniteImages.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "MPMediaItem+LigniteImages.h"



#ifdef SPOTIFY

#import "LMAppIcon.h"

@implementation NSDictionary (LigniteImages)

- (UIImage*)albumArt {
	return [self uncorrectedAlbumArt];
}

- (UIImage*)uncorrectedAlbumArt {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
}

- (UIImage*)artistImage {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
}

- (LMMusicTrackPersistentID)persistentID {
	return 0;
}

- (LMMusicTrackPersistentID)albumPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)artistPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)composerPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)genrePersistentID {
	return 0;
}

- (NSTimeInterval)playbackDuration {
	return [[self objectForKey:@"duration_ms"] integerValue]/1000;
}

- (NSString*)title {
	return [self objectForKey:@"name"];
}

- (NSString*)artist {
	NSArray *artists = [self objectForKey:@"artists"];
	NSMutableString *artistsString = [NSMutableString stringWithFormat:@""];
	
	for(NSDictionary *artist in artists){
		NSString *artistName = [artist objectForKey:@"name"];
		[artistsString appendString:[NSString stringWithFormat:@"%@, ", artistName]];
	}
	
	return [artistsString stringByReplacingCharactersInRange:NSMakeRange([artistsString length]-2, 2) withString:@""];
}

- (NSString*)albumTitle {
	return [[self objectForKey:@"album"] objectForKey:@"name"];
}

- (NSString*)composer {
	return @"composer :)";
}

- (NSString*)genre {
	return @"genre :)";
}

@end




#else

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
		UIImage *albumArtImage = [mediaItem.artwork imageWithSize:mediaItem.artwork.bounds.size];
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

#endif
