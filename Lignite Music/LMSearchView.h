//
//  LMSearchView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMSearchBar.h"
#import "LMMusicPlayer.h"

@protocol LMSearchSelectedDelegate <NSObject>

/**
 A search entry was tapped with a certain music type and associated persistent ID.
 
 @param persistentID The persistent ID associated.
 @param musicType The music type associated.
 */
- (void)searchEntryTappedWithPersistentID:(LMMusicTrackPersistentID)persistentID withMusicType:(LMMusicType)musicType;

@end

@interface LMSearchView : LMView

/**
 The search term from the search bar changed.

 @param searchTerm The new search term.
 */
- (void)searchTermChangedTo:(NSString*)searchTerm;

- (void)reloadData;

/**
 The search selected delegate.
 */
@property id<LMSearchSelectedDelegate> searchSelectedDelegate;

@end
