//
//  LMTitleView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@protocol LMTitleViewDelegate <NSObject>
@optional

/**
 The title view finished initialisation and is ready to be fucked with.
 */
- (void)titleViewFinishedInitialising;

@end

@interface LMTitleView : LMView

/**
 The current list of tracks being displayed.
 */
@property (readonly) LMMusicTrackCollection *musicTitles;

/**
 The currently highlighted element in the collection view.
 */
@property NSInteger currentlyHighlighted;

/**
 The title view's delegate.
 */
@property id<LMTitleViewDelegate> delegate;

/**
 The collection view that displays the list of tracks.
 */
@property UICollectionView *collectionView;

/**
 The title view's raw root view controller.
 */
@property id rawViewController;

/**
 Whether or not to display favourites. NO for all titles.
 */
@property BOOL favourites;

/**
 The amount to offset the shuffle button in landscape, because otherwise, it will be covered by the button navigation.
 */
@property CGFloat shuffleButtonLandscapeOffset;


/**
 The music track changed.

 @param newTrack The new track that's being played.
 */
- (void)musicTrackDidChange:(LMMusicTrack *)newTrack;

/**
 Scrolls to an index of a track.

 @param index The index to scroll to.
 */
- (void)scrollToTrackIndex:(NSUInteger)index;

/**
 Scroll to a track with its persistent ID.

 @param persistentID The persistent ID of the track to scroll to.
 @return The index that was scrolled to, -1 if it couldn't be found.
 */
- (NSInteger)scrollToTrackWithPersistentID:(LMMusicTrackPersistentID)persistentID;

/**
 Simulates a user tap at a certain index. Great for automatically playing music.

 @param index The index to tap.
 */
- (void)tapEntryAtIndex:(NSInteger)index;

/**
 Rebuild the track collection of the title view.
 */
- (void)rebuildTrackCollection;

/**
 The persistent ID of the track which is currently at the top of the title view, used for state restoration.

 @return The persistent ID.
 */
- (MPMediaEntityPersistentID)topTrackPersistentID;

@end
