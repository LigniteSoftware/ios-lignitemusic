//
//  LMDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/27/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

@class LMDetailView;

@protocol LMDetailViewDelegate <NSObject>
@optional

/**
 Whether or not the detail view is showing the album tile view. If this is called and the BOOL is false, that means the user has transitioned from the album tile view into a specific track collection.

 @param showingAlbumTileView Whether or not the album tile view is now showing.
 */
- (void)detailViewIsShowingAlbumTileView:(BOOL)showingAlbumTileView;

@end

@interface LMDetailView : LMView

/**
 The delegate for size change notifications.
 */
@property id<LMDetailViewDelegate> delegate;

/**
 The collection view which actually displays the data.
 */
@property UICollectionView *collectionView;

/**
 The music type associated with this expandable track list view.
 */
@property LMMusicType musicType;

/**
 The music track collection associated with this track list view.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 The flow layout associated.
 */
@property id flowLayout;

/**
 Whether or not the album tile view is being displayed.
 */
@property (readonly) BOOL showingAlbumTileView;

/**
 Initializes the expandable track list view (for autolayout) with a certain music track collection for its layouting.
 
 @param musicTrackCollection The music track collection to associate with it.
 @param musicType The type of music associated.
 @return The initialized LMExpandableTrackList view, ready for autolayout.
 */
- (instancetype)initWithMusicTrackCollection:(LMMusicTrackCollection*)musicTrackCollection musicType:(LMMusicType)musicType;

/**
 The total size of the expandable track list view based on what contents it currently wants to display. For example, if displaying the artist-album view, and then an album is tapped, this will change based on the amount of items within that it needs to display.
 
 @return The total size in width and height pixels.
 */
- (CGSize)totalSize;

/**
 Set whether or not to display specific track collections. If YES, the albums/specific collections will be displayed. Optionally animated.

 @param showingSpecificTrackCollection Whether or not to show the specific track collections.
 @param animated Whether or not to animate the transition.
 */
- (void)setShowingSpecificTrackCollection:(BOOL)showingSpecificTrackCollection animated:(BOOL)animated;

@end
