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
#import "LMCircleView.h"
#import "LMColour.h"

@interface LMDynamicSearchView()<LMSectionTableViewDelegate, LMMusicPlayerDelegate>

/**
 The section table view for search results.
 */
@property LMSectionTableView *sectionTableView;

/**
 The current search string, nil if nothing's being searched for.
 */
@property NSString *currentSearchString;

/**
 The cached array of arrays of track collections which the creator would like to be searchable.
 */
@property NSArray<NSArray<LMMusicTrackCollection*>*> *cachedSearchableTrackCollections;

/**
 The cached music types which are associated with those searchable track collections. Used for property setting & UI layouting.
 */
@property NSArray<NSNumber*> *cachedSearchableMusicTypes;

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

/**
 An array of dictionaries containing info on the track collections which were selected by the user if the selection mode was a selectable mode.
 
 Dictionary format:
 {
 @"trackCollection":<LMMusicTrackCollection*>, //Is empty if it's a playlist
 @"musicType":<NSNumber<LMMusicType*>*>,
 @"playlist":<LMPlaylist*> //Only if the musicType is LMMusicTypePlaylists
 }
 */
@property NSMutableArray<NSDictionary*> *selectedTrackCollectionsData;

/**
 The background view for the content of the ri-dic-u-lous welcome to search screen.
 */
@property UIView *welcomeToSearchContentBackgroundView;

/**
 The label for the insane welcome to search screen.
 */
@property UILabel *welcomeToSearchLabel;

/**
 Ugh, I hate this stupid welcome to search screen.
 */
@property UIView *welcomeToSearchImageBackgroundView;

/**
 The image view for the search icon for the annoying welcome to search screen.
 */
@property UIImageView *welcomeToSearchImageView;

/**
 The music player, used for tracking syncing.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMDynamicSearchView

@synthesize cachedSearchableTrackCollections = _cachedSearchableTrackCollections;
@synthesize cachedSearchableMusicTypes = _cachedSearchableMusicTypes;

/* Begin tableview-related code */

- (NSArray<NSNumber*>*)cachedSearchableMusicTypes {
	if(_cachedSearchableMusicTypes){
		return _cachedSearchableMusicTypes;
	}
	
	[self reloadSearchableCache];
	
	return _cachedSearchableMusicTypes;
}

- (void)setCachedSearchableMusicTypes:(NSArray<NSNumber *> *)cachedSearchableMusicTypes {
	_cachedSearchableMusicTypes = cachedSearchableMusicTypes;
}

- (NSArray<NSArray<LMMusicTrackCollection*>*>*)cachedSearchableTrackCollections {
	if(_cachedSearchableTrackCollections){
		return _cachedSearchableTrackCollections;
	}
	
	[self reloadSearchableCache];
	
	return _cachedSearchableTrackCollections;
}

- (void)setCachedSearchableTrackCollections:(NSArray<NSArray<LMMusicTrackCollection *> *> *)cachedSearchableTrackCollections {
	_cachedSearchableTrackCollections = cachedSearchableTrackCollections;
}

- (void)musicLibraryChanged:(BOOL)finished {
	if(finished){
		[self reloadSearchableCache];
		[self searchForString:self.currentSearchString];
	}
}

- (void)reloadSearchableCache {
	_cachedSearchableMusicTypes = [self.delegate searchableMusicTypesForSearchView:self];
	_cachedSearchableTrackCollections = [self.delegate searchableTrackCollectionsForSearchView:self];
	
	[self parseSearchableCache];
}

- (void)parseSearchableCache {
	//Check for instances the array containing LMMusicTypeTitles or LMMusicTypeFavourites which have all of their songs packed into one LMMusicTrackCollection at the front of the array, and fix them.
	NSUInteger indexOfTitles = [self.cachedSearchableMusicTypes indexOfObject:@(LMMusicTypeTitles)];
	NSUInteger indexOfFavourites = [self.cachedSearchableMusicTypes indexOfObject:@(LMMusicTypeFavourites)];
	if(indexOfTitles != NSNotFound || indexOfFavourites != NSNotFound){
		NSArray<LMMusicTrackCollection*> *titlesCollectionsArray = (indexOfTitles != NSNotFound) ? [self.cachedSearchableTrackCollections objectAtIndex:indexOfTitles] : nil;
		NSArray<LMMusicTrackCollection*> *favouritesCollectionsArray = (indexOfFavourites != NSNotFound) ? [self.cachedSearchableTrackCollections objectAtIndex:indexOfFavourites] : nil;
		
		
		if(titlesCollectionsArray){
			LMMusicTrackCollection *firstCollection = [titlesCollectionsArray firstObject];
			NSMutableArray<LMMusicTrackCollection*> *fixedTitlesCollectionsArray = [NSMutableArray new];
			if(firstCollection.count > 1 && titlesCollectionsArray.count == 1){ //Is bundled
				for(LMMusicTrack *track in firstCollection.items){
					[fixedTitlesCollectionsArray addObject:[[LMMusicTrackCollection alloc] initWithItems:@[ track ]]];
				}
				
				NSMutableArray *updatedArray = [[NSMutableArray alloc] initWithArray:self.cachedSearchableTrackCollections];
				[updatedArray removeObjectAtIndex:indexOfTitles];
				[updatedArray insertObject:[NSArray arrayWithArray:fixedTitlesCollectionsArray] atIndex:indexOfTitles];
				self.cachedSearchableTrackCollections = [NSArray arrayWithArray:updatedArray];
				
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
				
				NSMutableArray *updatedArray = [[NSMutableArray alloc] initWithArray:self.cachedSearchableTrackCollections];
				[updatedArray removeObjectAtIndex:indexOfFavourites];
				[updatedArray insertObject:[NSArray arrayWithArray:fixedFavouritesCollectionsArray] atIndex:indexOfFavourites];
				self.cachedSearchableTrackCollections = [NSArray arrayWithArray:updatedArray];
				
				NSLog(@"Fixed count %d", (int)fixedFavouritesCollectionsArray.count);
			}
		}
	}
}

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

- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
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

- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
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

- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults] || section == -1){
		return 0;
	}
	
	if(section >= self.searchResultsMusicTypes.count){
		return 0;
	}
	
	LMMusicType musicType = (LMMusicType)[self.searchResultsMusicTypes objectAtIndex:section].integerValue;
	if(musicType == LMMusicTypePlaylists){
		return self.searchResultsPlaylistsArray.count;
	}

	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:section];

	return collections.count;
}

- (NSString*)accessibilityLabelForIndexPath:(NSIndexPath *)indexPath {
	NSString *title = [self titleForIndexPath:indexPath forSectionTableView:self.sectionTableView];
	NSString *subtitle = [self subtitleForIndexPath:indexPath forSectionTableView:self.sectionTableView];

	return [NSString stringWithFormat:@"%@, %@", title, subtitle];
}

- (NSString*)accessibilityHintForIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"VoiceOverHint_TapSearchEntry", nil);
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];
	
//	return [NSString stringWithFormat:@"%d", (musicType != LMMusicTypeTitles && musicType != LMMusicTypeFavourites)];
	
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
	
	if(musicType == LMMusicTypePlaylists){
		LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.row];
		image = playlist.image;
	}

	if(!image){
		image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}

	return image;
}

- (NSInteger)indexPathOfSelectedTrackCollectionWithData:(id)data forMusicType:(LMMusicType)selectedMusicType {
	for(NSInteger i = 0; i < self.selectedTrackCollectionsData.count; i++){
		NSDictionary *trackDictionary = [self.selectedTrackCollectionsData objectAtIndex:i];
		
		LMMusicTrackCollection *collection = [trackDictionary objectForKey:@"trackCollection"];
		LMMusicType musicType = (LMMusicType)[[trackDictionary objectForKey:@"musicType"] integerValue];
		LMPlaylist *playlist = (musicType == LMMusicTypePlaylists) ? [trackDictionary objectForKey:@"playlist"] : nil;
		
		BOOL isPlaylist = (selectedMusicType == LMMusicTypePlaylists);
		LMMusicTrackCollection *selectedCollection = isPlaylist ? nil : (LMMusicTrackCollection*)data;
		LMPlaylist *selectedPlaylist = isPlaylist ? (LMPlaylist*)data : nil;
		
		if(isPlaylist){
			if(selectedPlaylist.persistentID == playlist.persistentID){
				return i;
			}
		}
		else if(musicType == LMMusicTypeTitles || selectedMusicType == LMMusicTypeFavourites){
			if((selectedCollection.representativeItem.persistentID == collection.representativeItem.persistentID)){
				return i;
			}
		}
		else{
			MPMediaEntityPersistentID collectionPersistentID = (MPMediaEntityPersistentID)[collection.representativeItem valueForProperty:[self propertyStringForMusicType:musicType]];
			MPMediaEntityPersistentID selectedPersistentID = (MPMediaEntityPersistentID)[selectedCollection.representativeItem valueForProperty:[self propertyStringForMusicType:selectedMusicType]];
			
			if(collectionPersistentID == selectedPersistentID){
				return i;
			}
		}
	}
	
	return NSNotFound;
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];

	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];
	
	BOOL notifyOfTap = NO;
	
	switch(self.selectionMode){
		case LMSearchViewEntrySelectionModeNoSelection: {
			notifyOfTap = YES;
			break;
		}
		case LMSearchViewEntrySelectionModeTitlesAndFavourites: {
			switch(musicType){
				case LMMusicTypeFavourites:
				case LMMusicTypeTitles:
					break;
				default:
					notifyOfTap = YES;
					break;
			}
			break;
		}
		case LMSearchViewEntrySelectionModeAll: {
			break;
		}
	}
	
	if([self.delegate respondsToSelector:@selector(searchViewEntryWasTappedWithData:forMusicType:)] && notifyOfTap){
		if(musicType == LMMusicTypePlaylists){
			LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.row];
			[self.delegate searchViewEntryWasTappedWithData:playlist forMusicType:musicType];
		}
		else{
			[self.delegate searchViewEntryWasTappedWithData:collection forMusicType:musicType];
		}
	}
	else if([self.delegate respondsToSelector:@selector(searchView:entryWasSetAsSelected:withData:forMusicType:)] && !notifyOfTap){
		if(musicType == LMMusicTypePlaylists){
			LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.section];
			NSInteger indexOfSelectedCollection = [self indexPathOfSelectedTrackCollectionWithData:playlist forMusicType:musicType];
			[self setData:playlist asSelected:indexOfSelectedCollection == NSNotFound forMusicType:musicType];
		}
		else{
			NSInteger indexOfSelectedCollection = [self indexPathOfSelectedTrackCollectionWithData:collection forMusicType:musicType];
			[self setData:collection asSelected:indexOfSelectedCollection == NSNotFound forMusicType:musicType];
		}
	}
	
	NSLog(@"Tapped %d.%d, %d", (int)indexPath.section, (int)indexPath.row, (int)self.selectedTrackCollectionsData.count);
}

- (UIView*)checkmarkViewSelected:(BOOL)selected {
	UIView *checkmarkPaddedView = [UIView newAutoLayoutView];
	
	LMCircleView *checkmarkView = [LMCircleView newAutoLayoutView];
	checkmarkView.backgroundColor = selected ? [LMColour mainColour] : [LMColour lightGreyBackgroundColour];
	
	[checkmarkPaddedView addSubview:checkmarkView];
	
	
	[checkmarkView autoCentreInSuperview];
	[checkmarkView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
	[checkmarkView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
	
	
	LMCircleView *checkmarkFillView = [LMCircleView newAutoLayoutView];
	checkmarkFillView.backgroundColor = selected ? [LMColour mainColour] : [UIColor whiteColor];
	
	[checkmarkView addSubview:checkmarkFillView];
	
	[checkmarkFillView autoCentreInSuperview];
	[checkmarkFillView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(9.0/10.0)];
	[checkmarkFillView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:checkmarkView withMultiplier:(9.0/10.0)];
	
	
	UIImageView *checkmarkImageView = [UIImageView newAutoLayoutView];
	checkmarkImageView.contentMode = UIViewContentModeScaleAspectFit;
	checkmarkImageView.image = [LMAppIcon imageForIcon:LMIconWhiteCheckmark];
	[checkmarkView addSubview:checkmarkImageView];
	
	[checkmarkImageView autoCentreInSuperview];
	[checkmarkImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
	[checkmarkImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
	
	return checkmarkPaddedView;
}

- (UIView*)arrowView {
	UIView *arrowIconPaddedView = [UIView newAutoLayoutView];
	
	UIImageView *arrowIconView = [UIImageView newAutoLayoutView];
	arrowIconView.contentMode = UIViewContentModeScaleAspectFit;
	arrowIconView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
	
	[arrowIconPaddedView addSubview:arrowIconView];
	
	[arrowIconView autoCentreInSuperview];
	[arrowIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:arrowIconPaddedView withMultiplier:(5.0/8.0)];
	[arrowIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:arrowIconPaddedView];
	
	return arrowIconPaddedView;
}

- (UIView*)rightViewForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	UIView *rightViewBackgroundView = [UIView newAutoLayoutView];
	rightViewBackgroundView.backgroundColor = [UIColor greenColor];
	
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] unsignedIntegerValue];
	NSArray<LMMusicTrackCollection*>* collections = [self.searchResultsTrackCollections objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = (musicType == LMMusicTypePlaylists) ? nil : [collections objectAtIndex:indexPath.row];
	
	switch(self.selectionMode){
		case LMSearchViewEntrySelectionModeNoSelection: {
			return [self arrowView];
		}
		case LMSearchViewEntrySelectionModeTitlesAndFavourites: {
			switch(musicType){
				case LMMusicTypeTitles:
				case LMMusicTypeFavourites: {
					BOOL selected = [self indexPathOfSelectedTrackCollectionWithData:collection forMusicType:musicType] != NSNotFound;
					return [self checkmarkViewSelected:selected];
				}
				default: {
					return [self arrowView];
				}
			}
			break;
		}
		case LMSearchViewEntrySelectionModeAll: {
			BOOL selected = NO;
			if(musicType == LMMusicTypePlaylists){
				LMPlaylist *playlist = [self.searchResultsPlaylistsArray objectAtIndex:indexPath.row];
				selected = [self indexPathOfSelectedTrackCollectionWithData:playlist forMusicType:musicType] != NSNotFound;
			}
			else{
				selected = [self indexPathOfSelectedTrackCollectionWithData:collection forMusicType:musicType] != NSNotFound;
			}
			return [self checkmarkViewSelected:selected];
		}
	}
	
	return rightViewBackgroundView;
}

- (void)setData:(id)data asSelected:(BOOL)selected forMusicType:(LMMusicType)musicType {
	NSInteger indexOfSelectedCollection = [self indexPathOfSelectedTrackCollectionWithData:data forMusicType:musicType];
	
	if(!selected){
		[self.selectedTrackCollectionsData removeObjectAtIndex:indexOfSelectedCollection];
	}
	else{
		BOOL isPlaylist = (musicType == LMMusicTypePlaylists);
		
		NSDictionary *dictionary = nil;
		if(isPlaylist){
			dictionary = @{
						   @"trackCollection":[[LMMusicTrackCollection alloc] initWithItems:@[]],
						   @"musicType":@(musicType),
						   @"playlist":data
						   };
		}
		else{
			dictionary = @{
						   @"trackCollection":data,
						   @"musicType":@(musicType)
						   };
		}
		
		[self.selectedTrackCollectionsData addObject:dictionary];
	}
	
	if(self.didLayoutConstraints){
		[self.sectionTableView reloadData];
		
		[self.delegate searchView:self entryWasSetAsSelected:selected withData:data forMusicType:musicType];
	} //Otherwise, it's just data being set from init
}

/* End tableview-related code */

/* Begin search-related code */

- (BOOL)noResults {
	if(!self.searchResultsTrackCollections || !self.searchResultsMusicTypes){
		return YES;
	}
	if(self.cachedSearchableTrackCollections.count == 0 || self.searchResultsMusicTypes.count == 0 || self.searchResultsTrackCollections.count == 0){
		return YES;
	}
	return NO;
}

- (void)searchForString:(NSString *)searchText {
	NSLog(@"Search for: '%@'", searchText);
	
	self.currentSearchString = ([searchText isEqualToString:@""] || !searchText) ? nil : searchText;
	
	NSString *searchProperty = MPMediaItemPropertyTitle; //The property of the media item to put against the search text
	
	NSMutableArray<NSArray<LMMusicTrackCollection*>*> *searchResultsTrackCollectionsMutableArray = [NSMutableArray new];
	NSMutableArray<NSNumber*> *searchResultsMusicTypesMutableArray = [NSMutableArray new];
	
	for(NSInteger i = 0; i < self.cachedSearchableTrackCollections.count; i++){ //Go through all of the searchable track collections provided by the object that created this instance
		
		LMMusicType musicType = (LMMusicType)[[self.cachedSearchableMusicTypes objectAtIndex:i] integerValue];
		NSArray<LMMusicTrackCollection*> *trackCollections = [self.cachedSearchableTrackCollections objectAtIndex:i];
		
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
	
	BOOL blankSearch = [searchText isEqualToString:@""] || (searchText == nil);
	self.welcomeToSearchContentBackgroundView.hidden = ![self noResults];
	self.welcomeToSearchLabel.text = NSLocalizedString(blankSearch ? @"WelcomeToSearch" : @"NoSearchResults", nil);
	self.welcomeToSearchImageView.image = blankSearch ? [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconSearch]] : [LMAppIcon imageForIcon:LMIconNoSearchResults];
	
	//Search complete, papa bless!
}

- (BOOL)shouldShowSwipeButtonsForIndexPath:(NSIndexPath*)indexPath {
	if(!self.enableSwipeControls){
		return NO;
	}
	
	LMMusicType musicType = (LMMusicType)[[self.searchResultsMusicTypes objectAtIndex:indexPath.section] integerValue];
	
	return (musicType == LMMusicTypeTitles || musicType == LMMusicTypeFavourites);
}

- (NSArray<MGSwipeButton*>*)swipeButtonsForIndexPath:(NSIndexPath*)indexPath rightSide:(BOOL)rightSide {
	if(!self.enableSwipeControls || ![self shouldShowSwipeButtonsForIndexPath:indexPath]){
		return nil;
	}
	
	UIColor *colour = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
	
	LMMusicTrack *musicTrack = [[[self.searchResultsTrackCollections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] representativeItem];
	LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	UIImage *icon = [LMAppIcon imageForIcon:LMIconAddToQueue];
	if(!rightSide){ //Favourite/unfavourite
		icon = [LMAppIcon imageForIcon:musicTrack.isFavourite ? LMIconUnfavouriteWhite : LMIconFavouriteWhiteFilled];
	}
	
	MGSwipeButton *swipeButton = [MGSwipeButton buttonWithTitle:@""
														   icon:icon
											   	backgroundColor:colour
													   	padding:0
													   callback:
		^BOOL(MGSwipeTableCell *sender) {
			if(rightSide){
				NSLog(@"Right %@", musicTrack.title);
				
				[musicPlayer.queue addTrackToQueue:musicTrack];
			}
			else{
				NSLog(@"Favourite %@", musicTrack.title);
				
				if(musicTrack.isFavourite){
					[musicPlayer removeTrackFromFavourites:musicTrack];
				}
				else{
					[musicPlayer addTrackToFavourites:musicTrack];
				}
				
				[self reloadSearchableCache];
				[self searchForString:self.currentSearchString];
			}
			return YES;
	}];
	swipeButton.titleLabel.font = font;
	swipeButton.titleLabel.hidden = YES;
	swipeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
	swipeButton.imageEdgeInsets = UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 18 : 21, 0, LMLayoutManager.isExtraSmall ? 18 : 21, 0);

	return @[ swipeButton ];
}

- (UIColor*)swipeButtonColourForIndexPath:(NSIndexPath*)indexPath rightSide:(BOOL)rightSide {
	if(!self.enableSwipeControls || ![self shouldShowSwipeButtonsForIndexPath:indexPath]){
		return nil;
	}
	
	UIColor *swipeColour = [LMColour successGreenColour];
	
	LMMusicTrack *musicTrack = [[[self.searchResultsTrackCollections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] representativeItem];
	
	if(!rightSide && musicTrack.isFavourite){ //Favourite/unfavourite
		swipeColour = [LMColour deletionRedColour];
	}
	
	return swipeColour;
}

/* End search-related code */

/* Begin initialization and layouting */

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		[self parseSearchableCache];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		
		
		self.backgroundColor = [UIColor orangeColor];
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 1;
		self.sectionTableView.title = @"SearchView";
		self.sectionTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
		self.sectionTableView.allowsSelection = NO;
		[self addSubview:self.sectionTableView];

		NSLog(@"section %@", self.sectionTableView);

		[self.sectionTableView autoPinEdgesToSuperviewEdges];

		[self.sectionTableView setup];
		
		
		
		self.welcomeToSearchContentBackgroundView = [UIView newAutoLayoutView];
//				self.welcomeToSearchContentBackgroundView.backgroundColor = [UIColor magentaColor];
		[self addSubview:self.welcomeToSearchContentBackgroundView];
		
		[self.welcomeToSearchContentBackgroundView autoCentreInSuperview];
		[self.welcomeToSearchContentBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.welcomeToSearchContentBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		
		
		self.welcomeToSearchImageBackgroundView = [UIView newAutoLayoutView];
//				self.welcomeToSearchImageBackgroundView.backgroundColor = [UIColor yellowColor];
		[self.welcomeToSearchContentBackgroundView addSubview:self.welcomeToSearchImageBackgroundView];
		
		[self.welcomeToSearchImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.welcomeToSearchImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.welcomeToSearchImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[self.welcomeToSearchImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.75/10.0)];
		[self.welcomeToSearchImageBackgroundView autoSetDimension:ALDimensionHeight toSize:70.0f];
		
		
		self.welcomeToSearchImageView = [UIImageView newAutoLayoutView];
//				self.welcomeToSearchImageView.backgroundColor = [UIColor orangeColor];
		self.welcomeToSearchImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconSearch]];
		self.welcomeToSearchImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.welcomeToSearchImageBackgroundView addSubview:self.welcomeToSearchImageView];
		
		[self.welcomeToSearchImageView autoPinEdgesToSuperviewEdges];
		
		
		self.welcomeToSearchLabel = [UILabel newAutoLayoutView];
		self.welcomeToSearchLabel.numberOfLines = 0;
		self.welcomeToSearchLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
		self.welcomeToSearchLabel.text = NSLocalizedString(@"WelcomeToSearch", nil);
		self.welcomeToSearchLabel.textAlignment = NSTextAlignmentCenter;
		[self.welcomeToSearchContentBackgroundView addSubview:self.welcomeToSearchLabel];
		
		
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.welcomeToSearchLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.welcomeToSearchImageBackgroundView withOffset:20.0f];
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}
	
	[super layoutSubviews];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.selectionMode = LMSearchViewEntrySelectionModeNoSelection;
		self.selectedTrackCollectionsData = [NSMutableArray new];
	}
	return self;
}

/* End initialization and layouting */

@end
