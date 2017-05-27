//
//  LMExpandableTrackListView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LMMusicPlayer.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMView.h"

@interface LMEmbeddedDetailView : LMView

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
 Whether or not the view is currently changing in size.
 */
@property BOOL isChangingSize;

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

@end
