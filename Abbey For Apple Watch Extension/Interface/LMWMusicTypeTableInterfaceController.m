//
//  LMWMusicTypeTableInterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWMusicTypeTableInterfaceController.h"
#import "LMWMusicTypeRowController.h"
#import "LMWMusicTrackInfo.h"

@implementation LMWMusicTypeTableInterfaceController

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	LMWMusicTypeRowController *row = [self.musicTypesTable rowControllerAtIndex:rowIndex];
	
	[self pushControllerWithName:@"MusicBrowsingController" context:@{
																	  @"title": NSLocalizedString([row.musicTypeDictionary objectForKey:@"title"], nil),
																	  @"musicType": [row.musicTypeDictionary objectForKey:@"type"],
																	  @"lastIndex": @(0),
																	  @"persistentID": @(0)
																	  }];
}

- (void)setupMusicTypesTable {
	NSArray *musicTypesArray = @[
								 @{
									 @"icon": @"icon_favourite_black.png",
									 @"title": @"Favourites",
									 @"type": @(LMMusicTypeFavourites)
									 },
								 @{
									 @"icon": @"icon_artists.png",
									 @"title": @"Artists",
									 @"type": @(LMMusicTypeArtists)
									 },
								 @{
									 @"icon": @"icon_albums.png",
									 @"title": @"Albums",
									 @"type": @(LMMusicTypeAlbums)
									 },
								 @{
									 @"icon": @"icon_titles.png",
									 @"title": @"Titles",
									 @"type": @(LMMusicTypeTitles)
									 },
								 @{
									 @"icon": @"icon_playlists.png",
									 @"title": @"Playlists",
									 @"type": @(LMMusicTypePlaylists)
									 },
								 @{
									 @"icon": @"icon_genres.png",
									 @"title": @"Genres",
									 @"type": @(LMMusicTypeGenres)
									 },
								 @{
									 @"icon": @"icon_compilations.png",
									 @"title": @"Compilations",
									 @"type": @(LMMusicTypeCompilations)
									 }
								 ];
	
	[self.musicTypesTable setNumberOfRows:[musicTypesArray count] withRowType:@"MusicTypeRow"];
	for (NSInteger i = 0; i < self.musicTypesTable.numberOfRows; i++) {
		LMWMusicTypeRowController *row = [self.musicTypesTable rowControllerAtIndex:i];
		
		NSDictionary *musicTypeInfo = [musicTypesArray objectAtIndex:i];
		
		[row.icon setImage:[UIImage imageNamed:[musicTypeInfo objectForKey:@"icon"]]];
		[row.titleLabel setText:NSLocalizedString([musicTypeInfo objectForKey:@"title"], nil)];
		
		row.musicTypeDictionary = musicTypeInfo;
	}
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];
	
	[self setTitle:NSLocalizedString(@"Library", nil)];

	[self setupMusicTypesTable];
}

- (void)willActivate {
	//Nothing, right now
}

@end
