//
//  LMCompactBrowsingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

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
 Reload the contents of the view after changing the music type and music track collections.
 */
- (void)reloadContents;

@end
