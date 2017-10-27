//
//  LMPhoneLandscapeDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"
#import "LMDetailView.h"
#import "LMPlaylistManager.h"

@interface LMPhoneLandscapeDetailView : LMView

/**
 The music type.
 */
@property LMMusicType musicType;

/**
 The collection of music tracks.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 The playlist associated with this landscape detail view if the music type is LMMusicTypePlaylists.
 */
@property LMPlaylist *playlist;

/**
 The actual detail view for displaying shit.
 */
@property LMDetailView *detailView;

/**
 The index.
 */
@property NSInteger index;

/**
 I hate this issue
 */
@property id flowLayout;

/**
 Reload the content of this landscape detail view.
 */
- (void)reloadContent;

@end
