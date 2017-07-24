//
//  LMPhoneLandscapeDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

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
 The index.
 */
@property NSInteger index;

/**
 Reload the content of this landscape detail view.
 */
- (void)reloadContent;

@end
