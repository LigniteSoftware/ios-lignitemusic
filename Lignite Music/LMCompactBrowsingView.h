//
//  LMCompactBrowsingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"
#import "LMCoreViewController.h"

@interface LMCompactBrowsingView : LMView

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
@property LMCoreViewController *rootViewController;

/**
 The actual collection view for displaying collections in a compact method.
 */
@property UICollectionView *collectionView;

/**
 Reload the contents of the view after changing the music type and music track collections.
 */
- (void)reloadContents;

/**
 Scroll the view to a certain index in its music track collection.
 
 @param index The index to scroll to.
 */
- (void)scrollViewToIndex:(NSUInteger)index;

/**
 Scroll to the position in the list with that persistent ID.
 
 @param persistentID The persistent ID to scroll to.
 */
- (void)scrollToItemWithPersistentID:(LMMusicTrackPersistentID)persistentID;

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

@end
