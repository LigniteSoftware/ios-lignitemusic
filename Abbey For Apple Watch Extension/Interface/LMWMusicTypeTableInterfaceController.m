//
//  LMWMusicTypeTableInterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWMusicTypeTableInterfaceController.h"
#import "LMWMusicTypeRowController.h"

@implementation LMWMusicTypeTableInterfaceController

- (void)setupMusicTypesTable {
	NSArray *musicTypesArray = @[
								 @{
									 @"icon": @"icon_favourite_black.png",
									 @"title": @"Favourites"
									 },
								 @{
									 @"icon": @"icon_artists.png",
									 @"title": @"Artists"
									 },
								 @{
									 @"icon": @"icon_albums.png",
									 @"title": @"Albums"
									 },
								 @{
									 @"icon": @"icon_titles.png",
									 @"title": @"Titles"
									 },
								 @{
									 @"icon": @"icon_playlists.png",
									 @"title": @"Playlists"
									 },
								 @{
									 @"icon": @"icon_genres.png",
									 @"title": @"Genres"
									 },
								 @{
									 @"icon": @"icon_compilations.png",
									 @"title": @"Compilations"
									 }
								 ];
	
	[self.musicTypesTable setNumberOfRows:[musicTypesArray count] withRowType:@"MusicTypeRow"];
	for (NSInteger i = 0; i < self.musicTypesTable.numberOfRows; i++) {
		LMWMusicTypeRowController *row = [self.musicTypesTable rowControllerAtIndex:i];
		
		NSDictionary *musicTypeInfo = [musicTypesArray objectAtIndex:i];
		
		[row.icon setImage:[UIImage imageNamed:[musicTypeInfo objectForKey:@"icon"]]];
		[row.titleLabel setText:NSLocalizedString([musicTypeInfo objectForKey:@"title"], nil)];
	}
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];
	
	[self setTitle:NSLocalizedString(@"Library", nil)];

	[self setupMusicTypesTable];
}

@end
