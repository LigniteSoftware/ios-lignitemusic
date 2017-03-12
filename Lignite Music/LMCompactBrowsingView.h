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
 Reload the contents of the view after changing the music type and music track collections.
 */
- (void)reloadContents;

/**
 Scroll the view to a certain index in its music track collection.
 
 @param index The index to scroll to.
 */
- (void)scrollViewToIndex:(NSUInteger)index;

@end
