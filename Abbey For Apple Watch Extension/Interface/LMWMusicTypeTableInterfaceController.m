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
	
//	LMWMusicBrowsingInterfaceController *controller = [LMWMusicBrowsingInterfaceController new];
	
	
	[self pushControllerWithName:@"BrowsingController" context:@{
																	  @"title": NSLocalizedString([row.musicTypeDictionary objectForKey:@"title"], nil),
																	  @"musicTypes": @[ [row.musicTypeDictionary objectForKey:@"type"] ],
																	  @"lastIndex": @(0),
																	  @"persistentID": @(0)
																	  //entryInfo is nil because it's the start of the list
																	  }];
}

- (void)setupMusicTypesTable {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray *musicTypesArray = @[
									 @{
										 @"icon": @"icon_favourite_white",
										 @"title": @"Favourites",
										 @"type": @(LMMusicTypeFavourites)
										 },
									 @{
										 @"icon": @"icon_artists_white",
										 @"title": @"Artists",
										 @"type": @(LMMusicTypeArtists)
										 },
									 @{
										 @"icon": @"icon_albums_white",
										 @"title": @"Albums",
										 @"type": @(LMMusicTypeAlbums)
										 },
									 @{
										 @"icon": @"icon_titles_white",
										 @"title": @"Titles",
										 @"type": @(LMMusicTypeTitles)
										 },
									 @{
										 @"icon": @"icon_playlists_white",
										 @"title": @"Playlists",
										 @"type": @(LMMusicTypePlaylists)
										 },
									 @{
										 @"icon": @"icon_genres_white",
										 @"title": @"Genres",
										 @"type": @(LMMusicTypeGenres)
										 },
									 @{
										 @"icon": @"icon_compilations_white",
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
		
		[self.loadingImage stopAnimating];
		[self.loadingGroup setHidden:YES];
	});
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];
	
	[self setTitle:NSLocalizedString(@"Library", nil)];
	
	[self.loadingLabel setText:NSLocalizedString(@"HangOn", nil)];
	
	[self.loadingImage setImageNamed:@"Activity"];
	[self.loadingImage startAnimatingWithImagesInRange:NSMakeRange(0, 30)
											  duration:1.0
										   repeatCount:0];

	[self setupMusicTypesTable];
}

- (void)willActivate {
	//Nothing, yet
}

@end
