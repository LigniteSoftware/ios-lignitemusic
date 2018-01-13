//
//  LMTitleView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMTableView.h"
#import "LMMusicPlayer.h"
#import "LMCoreViewController.h"

@interface LMTitleView : UIView

@property (readonly) LMMusicTrackCollection *musicTitles;

- (void)setup DEPRECATED_ATTRIBUTE; //throwback
- (void)musicTrackDidChange:(LMMusicTrack *)newTrack;
@property NSInteger currentlyHighlighted;

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

/**
 The table view that displays the song.
 */
@property LMTableView *songListTableView;

/**
 The title view's root view controller.
 */
@property LMCoreViewController *rootViewController;

/**
 Whether or not to display favourites. NO for all titles.
 */
@property BOOL favourites;

@end
