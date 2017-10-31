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

@end

@interface LMDynamicSearchView : LMView

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

@end
