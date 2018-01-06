//
//  LMCompactBrowsingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"
#import "LMPlaylistEditorViewController.h"
#import "LMEnhancedPlaylistEditorViewController.h"

@interface LMCompactBrowsingView : LMView <LMPlaylistEditorDelegate, LMEnhancedPlaylistEditorDelegate>

/**
 The music track collections associated with this compact browsing view. For every collection there will be an entry.
 */
@property NSArray<LMMusicTrackCollection*> *musicTrackCollections;

/**
 The current music type. 
 */
@property LMMusicType musicType;

/**
 The root/source view controller.
 */
@property id rootViewController;

///**
// If state restoration contained a playlist editor, that playlist editor will sit here pending for an attachment, so that delegate callbacks will be managed properly.
// */
//@property LMPlaylistEditorViewController *pendingStateRestoredPlaylistEditor;

/**
 The actual collection view for displaying collections in a compact method.
 */
@property UICollectionView *collectionView;

/**
 Whether or not the compact view is currently in playlist editing mode.
 */
@property BOOL editing;

/**
 The index of the currently open detail view for transitioning between landscape and portrait on iPhone.
 */
@property NSInteger indexOfCurrentlyOpenDetailView;

/**
 Reload the contents of the view after changing the music type and music track collections.
 */
- (void)reloadContents;

/**
 The back button on the navigation bar was pressed when in phone landscape detail view mode.
 */
- (void)backButtonPressed;

/**
 The plus button was tapped, indicating the user wants to create a new playlist.
 */
- (void)addPlaylistButtonTapped;

/**
 The edit button was tapped, indicating the user wants to enter editing mode.
 */
- (void)editPlaylistButtonTapped;

/**
 Scroll the view to a certain index in its music track collection.
 
 @param index The index to scroll to.
 */
- (void)scrollViewToIndex:(NSUInteger)index;

/**
 Performs the opening or closing of a detail view for a certain index, based on whether or not it's already open.

 @param i The index of the detail view to open/close.
 */
- (void)tappedBigListEntryAtIndex:(NSInteger)i;

/**
 Scroll to the position in the list with that persistent ID.
 
 @param persistentID The persistent ID to scroll to.
 @return The index of the item that was scrolled to. -1 if no item could be found with that persistent ID.
 */
- (NSInteger)scrollToItemWithPersistentID:(LMMusicTrackPersistentID)persistentID;

/**
 Change the bottom spacing of the compact view, for when changes to the button bar occur.
 
 @param persistentID The new bottom spacing to set.
 */
- (void)changeBottomSpacing:(CGFloat)bottomSpacing;

/**
 Set whether or not the phone landscape view should display.

 @param displaying Whether or not to display it.
 @param index The index to display/not display it for. -1 is fine if not displaying.
 */
- (void)setPhoneLandscapeViewDisplaying:(BOOL)displaying forIndex:(NSInteger)index;

/**
 Reload the data and invalidate the layouts at the same time, saving to make 2 calls at once.
 */
- (void)reloadDataAndInvalidateLayouts;

@end
