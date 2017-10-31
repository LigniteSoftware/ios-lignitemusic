//
//  LMDynamicSearchView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMDynamicSearchView.h"
#import "LMSectionTableView.h"
#import "LMPlaylistManager.h"

@interface LMDynamicSearchView()<LMSectionTableViewDelegate>

/**
 The section table view for search results.
 */
@property LMSectionTableView *sectionTableView;

/**
 The array of search results.
 */
@property NSArray<NSArray<LMMusicTrackCollection*>*> *searchResultsTrackCollections;

/**
 The music types associated with the search results track collections array.
 */
@property NSArray<NSNumber*> *searchResultsMusicTypes;

/**
 The search results for playlists, if playlists were included in the searchable music types.
 */
@property NSArray<LMPlaylist*> *searchResultsPlaylistsArray;

@end

@implementation LMDynamicSearchView

/* Begin tableview-related code */

- (NSString*)propertyStringForMusicType:(LMMusicType)musicType {
	switch(musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return MPMediaItemPropertyTitle;
		case LMMusicTypeComposers:
			return MPMediaItemPropertyComposer;
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
			return MPMediaItemPropertyAlbumTitle;
		case LMMusicTypeArtists:
			return MPMediaItemPropertyArtist;
		case LMMusicTypeGenres:
			return MPMediaItemPropertyGenre;
		default:
			NSAssert(true, @"This music type (%d) is not yet supported", musicType);
			return @"";
	}
}

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return nil;
	}

	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:section] unsignedIntegerValue];

	switch(musicType){
		case LMMusicTypeArtists:
			return [LMAppIcon imageForIcon:LMIconArtists];
		case LMMusicTypeCompilations:
			return [LMAppIcon imageForIcon:LMIconCompilations];
		case LMMusicTypeAlbums:
			return [LMAppIcon imageForIcon:LMIconAlbums];
		case LMMusicTypeComposers:
			return [LMAppIcon imageForIcon:LMIconComposers];
		case LMMusicTypeGenres:
			return [LMAppIcon imageForIcon:LMIconGenres];
		case LMMusicTypeTitles:
			return [LMAppIcon imageForIcon:LMIconTitles];
		case LMMusicTypePlaylists:
			return [LMAppIcon imageForIcon:LMIconPlaylists];
		case LMMusicTypeFavourites:
			return [LMAppIcon imageForIcon:LMIconFavouriteBlackFilled];
		default:
			return [LMAppIcon imageForIcon:LMIconBug];
	}
}

- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return @"";
	}

	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:section];
	
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:section] unsignedIntegerValue];
	
	switch(musicType){
		case LMMusicTypeArtists:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Artist" : @"Artists", nil)];
		case LMMusicTypeCompilations:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Compilation" : @"Compilations", nil)];
		case LMMusicTypeAlbums:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Album" : @"Albums", nil)];
		case LMMusicTypeComposers:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Composer" : @"Composers", nil)];
		case LMMusicTypeGenres:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Genre" : @"Genres", nil)];
		case LMMusicTypeTitles:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Title" : @"Titles", nil)];
		case LMMusicTypePlaylists:
			return [NSString stringWithFormat:@"%lu %@", self.searchResultsPlaylistsArray.count, NSLocalizedString(self.searchResultsPlaylistsArray.count == 1 ? @"Playlist" : @"Playlists", nil)];
		case LMMusicTypeFavourites:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Favourite" : @"Favourites", nil)];
		default:
			return @"Unknown Section";
	}
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return 0;
	}
	
	LMMusicType musicType = (LMMusicType)[self.searchResultsMusicTypes objectAtIndex:section].integerValue;
	if(musicType == LMMusicTypePlaylists){
		return self.searchResultsPlaylistsArray.count;
	}

	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:section];

	return collections.count;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];

	return (musicType == LMMusicTypePlaylists)
		? [self.searchResultsPlaylistsArray objectAtIndex:indexPath.row].title
		: [collection.representativeItem valueForProperty:[self propertyStringForMusicType:musicType]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];
	
	MPMediaItem *representativeItem = collection.representativeItem;
	
	switch(musicType){
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
			return [NSString stringWithFormat:
					 @"%@ | %lu %@",
					 representativeItem.artist ? representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil),
					 collection.count,
					 NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		case LMMusicTypePlaylists: {
			LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.row];
		
			return [NSString stringWithFormat:@"%lu %@", playlist.trackCollection.count, NSLocalizedString(playlist.trackCollection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeComposers:
		case LMMusicTypeArtists:
		case LMMusicTypeGenres:
			return [NSString stringWithFormat:@"%lu %@", collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		case LMMusicTypeTitles:
		case LMMusicTypeFavourites:
			return collection.representativeItem.artist;
		default:
			return @"Unknown Section";
	}

	return nil;
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];
	
	LMMusicTrack *representativeTrack = collection.representativeItem;
	
	UIImage *image = (musicType == LMMusicTypeArtists || musicType == LMMusicTypeComposers)
		? [representativeTrack artistImage]
		: [representativeTrack albumArt];

	if(!image){
		image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	}

	return image;
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];

	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];
	
	if([self.delegate respondsToSelector:@selector(searchViewEntryWasTappedWithData:forMusicType:)]){
		if(musicType == LMMusicTypePlaylists){
			LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.section];
			[self.delegate searchViewEntryWasTappedWithData:playlist forMusicType:musicType];
		}
		else{
			[self.delegate searchViewEntryWasTappedWithData:collection forMusicType:musicType];
		}
	}
	
	NSLog(@"Tapped %d.%d", (int)indexPath.section, (int)indexPath.row);
}

/* End tableview-related code */

/* Begin search-related code */

- (BOOL)noResults {
	if(!self.searchResultsTrackCollections || !self.searchResultsMusicTypes){
		return YES;
	}
	if(self.searchableTrackCollections.count == 0){
		return YES;
	}
	return NO;
}

- (void)searchForString:(NSString *)searchText {
	NSLog(@"Search for: '%@'", searchText);
	
	NSString *searchProperty = MPMediaItemPropertyTitle; //The property of the media item to put against the search text
	
	NSMutableArray<NSArray<LMMusicTrackCollection*>*> *searchResultsTrackCollectionsMutableArray = [NSMutableArray new];
	NSMutableArray<NSNumber*> *searchResultsMusicTypesMutableArray = [NSMutableArray new];
	
	for(NSInteger i = 0; i < self.searchableTrackCollections.count; i++){ //Go through all of the searchable track collections provided by the object that created this instance
		
		LMMusicType musicType = (LMMusicType)[[self.searchableMusicTypes objectAtIndex:i] integerValue];
		NSArray<LMMusicTrackCollection*> *trackCollections = [self.searchableTrackCollections objectAtIndex:i];
		
		//Set the property to be found based on the music type.
		switch(musicType){
			case LMMusicTypeTitles:
			case LMMusicTypeFavourites:
				searchProperty = MPMediaItemPropertyTitle;
				break;
			case LMMusicTypeAlbums:
			case LMMusicTypeCompilations:
				searchProperty = MPMediaItemPropertyAlbumTitle;
				break;
			case LMMusicTypeArtists:
				searchProperty = MPMediaItemPropertyArtist;
				break;
			case LMMusicTypeComposers:
				searchProperty = MPMediaItemPropertyComposer;
				break;
			case LMMusicTypeGenres:
				searchProperty = MPMediaItemPropertyGenre;
				break;
			case LMMusicTypePlaylists:
				//Nothing here, playlists are handled in a special way.
				break;
		}
		
		NSMutableArray *searchResultsMutableArray = [NSMutableArray new];
		
		//If the music type is playlists, scan through those playlist's titles
		if(musicType == LMMusicTypePlaylists){
			NSArray<LMPlaylist*> *playlists = [LMPlaylistManager sharedPlaylistManager].playlists;
			
			for(LMPlaylist *playlist in playlists){
				if([playlist.title.lowercaseString containsString:searchText.lowercaseString]){
					[searchResultsMutableArray addObject:playlist];
				}
			}
		}
		//Otherwise handle all other collections in the same way
		else{
			for(LMMusicTrackCollection *collection in trackCollections){ //Go through every collection in the track collections array of this music type
				
				NSString *trackValue = [collection.representativeItem valueForProperty:searchProperty];
				if([trackValue.lowercaseString containsString:searchText.lowercaseString]){ //Compare the base track value as set above with the search string
					[searchResultsMutableArray addObject:collection];
				}
				else if(musicType != LMMusicTypeArtists && musicType != LMMusicTypeTitles){ //Otherwise, search all other music types aside from artists and titles for the string inside of the artist's name
					NSString *trackArtistValue = [collection.representativeItem valueForProperty:MPMediaItemPropertyArtist];
					if([trackArtistValue.lowercaseString containsString:searchText.lowercaseString]){
						[searchResultsMutableArray addObject:collection];
					}
				}
				else if(musicType == LMMusicTypeTitles){ //Otherwise, if still not found, search against the album title if the music type is titles
					NSString *trackAlbumValue = [collection.representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle];
					if([trackAlbumValue.lowercaseString containsString:searchText.lowercaseString]){
						[searchResultsMutableArray addObject:collection];
					}
				}
				
			}
		}
		
		//If there are any results
		if(searchResultsMutableArray.count > 0){
			//If it's of playlist, set the playlist results array accordingly. Add a blank entry to the track collections results array to ensure no misalignment of searching through other music type collections which may be pulled from at any point. Also log the playlists music type as one with results.
			if(musicType == LMMusicTypePlaylists){
				self.searchResultsPlaylistsArray = [NSArray arrayWithArray:searchResultsMutableArray];
				
				[searchResultsTrackCollectionsMutableArray addObject:@[]];
				[searchResultsMusicTypesMutableArray addObject:@(musicType)];
			}
			//Otherwise, just add that music collections array and that music type to their results array.
			else{
				[searchResultsTrackCollectionsMutableArray addObject:searchResultsMutableArray];
				[searchResultsMusicTypesMutableArray addObject:@(musicType)];
			}
		}
		else{
			NSLog(@"No results found for music type %d", musicType);
		}
	}
	
	//Set the global variables from the local ones.
	self.searchResultsTrackCollections = [[NSArray alloc]initWithArray:searchResultsTrackCollectionsMutableArray];
	self.searchResultsMusicTypes = [[NSArray alloc]initWithArray:searchResultsMusicTypesMutableArray];
	
	//Log the results
	for(NSInteger i = 0; i < self.searchResultsTrackCollections.count; i++){
		NSArray<LMMusicTrackCollection*> *collections = [self.searchResultsTrackCollections objectAtIndex:i];
		LMMusicType musicType = (LMMusicType)[self.searchResultsMusicTypes objectAtIndex:i].integerValue;
		
		NSLog(@"Got %d results for music type %d.", (int)collections.count, musicType);
	}
	
	//Reload the table view with the new data.
	self.sectionTableView.totalNumberOfSections = self.searchResultsTrackCollections.count;
	
	if(self.searchResultsTrackCollections.count == 0){
		self.searchResultsTrackCollections = nil;
		self.searchResultsMusicTypes = nil;
		self.sectionTableView.totalNumberOfSections = 1;
	}
	else{
		[self.sectionTableView registerCellIdentifiers];
	}
	
	[self.sectionTableView reloadData];
	
	//Search complete, papa bless!
}

/* End search-related code */

/* Begin initialization and layouting */

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		//Check for instances the array containing LMMusicTypeTitles or LMMusicTypeFavourites which have all of their songs packed into one LMMusicTrackCollection at the front of the array, and fix them.
		NSUInteger indexOfTitles = [self.searchableMusicTypes indexOfObject:@(LMMusicTypeTitles)];
		NSUInteger indexOfFavourites = [self.searchableMusicTypes indexOfObject:@(LMMusicTypeFavourites)];
		if(indexOfTitles != NSNotFound || indexOfFavourites != NSNotFound){
			NSArray<LMMusicTrackCollection*> *titlesCollectionsArray = (indexOfTitles != NSNotFound) ? [self.searchableTrackCollections objectAtIndex:indexOfTitles] : nil;
			NSArray<LMMusicTrackCollection*> *favouritesCollectionsArray = (indexOfFavourites != NSNotFound) ? [self.searchableTrackCollections objectAtIndex:indexOfFavourites] : nil;
			
			
			if(titlesCollectionsArray){
				LMMusicTrackCollection *firstCollection = [titlesCollectionsArray firstObject];
				NSMutableArray<LMMusicTrackCollection*> *fixedTitlesCollectionsArray = [NSMutableArray new];
				if(firstCollection.count > 1 && titlesCollectionsArray.count == 1){ //Is bundled
					for(LMMusicTrack *track in firstCollection.items){
						[fixedTitlesCollectionsArray addObject:[[LMMusicTrackCollection alloc] initWithItems:@[ track ]]];
					}
					
					NSMutableArray *updatedArray = [[NSMutableArray alloc] initWithArray:self.searchableTrackCollections];
					[updatedArray removeObjectAtIndex:indexOfTitles];
					[updatedArray insertObject:[NSArray arrayWithArray:fixedTitlesCollectionsArray] atIndex:indexOfTitles];
					self.searchableTrackCollections = [NSArray arrayWithArray:updatedArray];
					
					NSLog(@"Fixed count %d", (int)fixedTitlesCollectionsArray.count);
				}
			}
			if(favouritesCollectionsArray){
				LMMusicTrackCollection *firstCollection = [favouritesCollectionsArray firstObject];
				NSMutableArray<LMMusicTrackCollection*> *fixedFavouritesCollectionsArray = [NSMutableArray new];
				if(firstCollection.count > 1 && favouritesCollectionsArray.count == 1){ //Is bundled
					for(LMMusicTrack *track in firstCollection.items){
						[fixedFavouritesCollectionsArray addObject:[[LMMusicTrackCollection alloc] initWithItems:@[ track ]]];
					}
					
					NSMutableArray *updatedArray = [[NSMutableArray alloc] initWithArray:self.searchableTrackCollections];
					[updatedArray removeObjectAtIndex:indexOfFavourites];
					[updatedArray insertObject:[NSArray arrayWithArray:fixedFavouritesCollectionsArray] atIndex:indexOfFavourites];
					self.searchableTrackCollections = [NSArray arrayWithArray:updatedArray];
					
					NSLog(@"Fixed count %d", (int)fixedFavouritesCollectionsArray.count);
				}
			}
			
		}
		
		self.backgroundColor = [UIColor orangeColor];
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 1;
		self.sectionTableView.title = @"SearchView";
		self.sectionTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
		[self addSubview:self.sectionTableView];

		NSLog(@"section %@", self.sectionTableView);

		[self.sectionTableView autoPinEdgesToSuperviewEdges];

		[self.sectionTableView setup];
	}
	
	[super layoutSubviews];
}

/* End initialization and layouting */

@end
