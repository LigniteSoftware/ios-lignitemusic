//
//  LMDynamicSearchView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

@class LMDynamicSearchView;

@protocol LMDynamicSearchViewDelegate<NSObject>
@optional

/**
 The search view was tapped or scrolled upon. In most cases, the delegate should then dismiss the keyboard and allow the search view to consume as much screen space as possible.

 @param searchView The search view which was interacted with.
 */
- (void)searchViewWasInteractedWith:(LMDynamicSearchView*)searchView;

/**
 A search view entry was tapped.

 @param musicData The music data associated with the tapped entry. This is by default a single LMMusicTrackCollection, unless the musicType is LMMusicTypePlaylists, then it is an LMPlaylist.
 @param musicType The music type that the tapped entry was under, section-wise.
 */
- (void)searchViewEntryWasTappedWithData:(id)musicData forMusicType:(LMMusicType)musicType;

/**
 An entry on the search view was selected or deselected by the user.

 @param searchView The search view whose entry was selected or unselected.
 @param selected Whether or not the entry was selected. If NO, the entry was previous selected and the user is now deselecting it.
 @param musicData The music data associated with the selected entry. The data is by default a single LMMusicTrackCollection, unless the musicType is LMMusicTypePlaylists, then it is an LMPlaylist.
 @param musicType The music type associated with the data and entry tapped.
 */
- (void)searchView:(LMDynamicSearchView*)searchView entryWasSetAsSelected:(BOOL)selected withData:(id)musicData forMusicType:(LMMusicType)musicType;

@end

@interface LMDynamicSearchView : LMView

/**
 How to go about what happens when an entry is tapped. Selected in this context refers to the action of the entry being added to a specifically selected array of track collections, which are provided to the delegate for use of which the delegate decides.

 - LMSearchViewEntrySelectionModeNoSelection: No entry has the ability to be selected.
 - LMSearchViewEntrySelectionModeTitlesAndFavourites: Only titles and favourites may be selected.
 - LMSearchViewEntrySelectionModeAll: All entries may be selected.
 */
typedef NS_ENUM(NSInteger, LMSearchViewEntrySelectionMode){
	LMSearchViewEntrySelectionModeNoSelection = 0,
	LMSearchViewEntrySelectionModeTitlesAndFavourites,
	LMSearchViewEntrySelectionModeAll
};

- (void)setData:(id)data asSelected:(BOOL)selected forMusicType:(LMMusicType)musicType;

/**
 The selection mode for the search view. Default is LMSearchViewEntrySelectionModeNoSelection.
 */
@property LMSearchViewEntrySelectionMode selectionMode;

/**
 The delegate for recieving information about searches.
 */
@property id<LMDynamicSearchViewDelegate> delegate;

/**
 The array of arrays of track collections which the creator would like to be searchable.
 */
@property NSArray<NSArray<LMMusicTrackCollection*>*> *searchableTrackCollections;

/**
 The music types which are associated with those searchable track collections. Used for property setting & UI layouting.
 */
@property NSArray<NSNumber*> *searchableMusicTypes;

/**
 Searches for a specific string through all provided collections and automatically displays the results.

 @param searchText The string to search for.
 */
- (void)searchForString:(NSString*)searchText;

/**
 Sets a track collection (which for titles and favourits is a collection with just one track in it) as selected or not, so in search it displays as such.

 @param data The data to set as selected or not. LMMusicTrackCollection in all cases except when the musicType is LMMusictypePlaylists, then it is an LMPlaylist.
 @param selected Whether or not the track collection should be selected.
 @param musicType The music type associated with the selection change.
 */
- (void)setData:(id)data asSelected:(BOOL)selected forMusicType:(LMMusicType)musicType;

@end
