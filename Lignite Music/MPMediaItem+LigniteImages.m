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
#import "LMDemoViewController.h"
#import "LMSettings.h"
@import SDWebImage;

@implementation MPMediaItem (LigniteImages)

- (NSString*)artist {
	if([[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDemoMode] && [[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyArtistsFilteredForDemo]){
		NSArray<NSArray*> *artistsByLetter = @[
											  
	  @[ @"A Good Kid", @"A Great Person", @"A haHAA", @"Add Me", @"Altitude", @"Angel Demon", @"Angry Beotch", @"Ass Blaster", @"Attention Span", @"Atwood Park" ],
	  
	  @[ @"Bad Intentions", @"Bad Kid", @"Base Builder", @"Big Fish", @"Black Beatles", @"Blow Me", @"Boogie Tonight", @"Bravado", @"Bullfrog Plaza", @"Buzzcut Boi" ],
	  
	  @[ @"Can Opener", @"Can U Not", @"Canada Proud", @"Candy Sweets", @"Cantina Band", @"Capper", @"Capsized", @"Cheque", @"Check Yourself", @"Crap" ],
	  
	  @[ @"Dead Inside", @"Daddy Slick", @"Damn Son", @"Darn Kids", @"Darn You", @"Demogorgon", @"Destroyer of Worlds", @"Dirty Harry", @"Drama King", @"Dreamer" ],
	  
	  @[ @"Earth Day", @"Eddie", @"Eeeek", @"Ember", @"Emergency Time", @"Emperor", @"Energetic Kid", @"Escape", @"Eternal Fire", @"Eyes Throat Genitals" ],
	  
	  @[ @"Fake Artist", @"Fake Kim Jong Un", @"Fake Names", @"Fall Apart", @"Feel Good", @"Finale", @"Fire", @"First Kiss", @"Fooking Hell", @"Fudge You" ],
	  
	  @[ @"Glow Dark", @"Good Intentions", @"Good Kid", @"Good Living", @"Great Meme", @"Greatest Artist", @"Grind Master", @"Grinding Daily", @"Grow Up Girl", @"Guitar Man" ],
	  
	  @[ @"Hacksaw Ridge", @"Hahahaha", @"Happy Dance", @"Hatchet Woman", @"Hate You", @"Hater For Life", @"Have A Nice Day", @"Have This", @"Heck", @"Hello World" ],
	  
	  @[ @"I Love You", @"I Want To Die", @"I'm Okay Now", @"I'm Right Here", @"Ice Ice Babe E", @"Imagination", @"Imagine", @"In Headspace", @"It Is Time", @"It's Okay" ],
	  
	  @[ @"Jacob Rhodes", @"Jake Ducker", @"Jealous Boy", @"Jell Oh", @"Jimminy Jilickers", @"Jock Strap", @"Jocks For Days", @"Johannesburg", @"Joke Around", @"Jonny Boy" ],
	  
	  ];
		
	//	NSArray *artists = @[ @"ass", @"bitch", @"cunt", @"dick", @"eat a dick", @"fuck you", @"gobbler", @"hell", @"inchworm", @"jockcock" ];
		NSLog(@"per id %lld", (self.persistentID % 100) / 10);
		return [[artistsByLetter objectAtIndex:(self.persistentID % 100) / 10] objectAtIndex:(self.persistentID % 10)];
	}
	return [self valueForProperty:MPMediaItemPropertyArtist];
}

- (nonnull UIImage*)albumArt {
	//Get the album artwork
	UIImage *albumArtImage = [self uncorrectedAlbumArt];
	
	//If that's not found, default back to no album art image
	if(!albumArtImage){
		albumArtImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	
	return albumArtImage;
}

- (nullable UIImage*)uncorrectedAlbumArt {
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

- (nullable UIImage*)uncorrectedArtistImage {
	LMMusicPlayerType currentPlayerType = [[LMMusicPlayer sharedMusicPlayer] playerType];
	
	if(currentPlayerType == LMMusicPlayerTypeSystemMusicPlayer || currentPlayerType == LMMusicPlayerTypeAppleMusic){
		UIImage *artistImage = [[LMImageManager sharedImageManager] imageForMediaItem:self withCategory:LMImageManagerCategoryArtistImages];
		
		if(artistImage) {
			return artistImage;
		}
	}
	
//	NSLog(@"Warning: Artist image not found for track %@.", self.title);
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDemoMode]){
		return [[[SDImageCache alloc] initWithNamespace:LMDemoImageCache] imageFromCacheForKey:[NSString stringWithFormat:@"%@_%d", LMDemoImageCache, (int)(self.persistentID % 10)]];
	}
	
	return nil;
}

- (nonnull UIImage*)artistImage {
	UIImage *artistImage = [self uncorrectedArtistImage];
	
	if(!artistImage){
		artistImage = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	
	return artistImage;
}

- (BOOL)isFavourite {
	NSString *favouriteKey = [NSString stringWithFormat:@"favourite_%llu", self.persistentID];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:favouriteKey]){
		return [userDefaults boolForKey:favouriteKey];
	}
	
	return NO;
}

@end
