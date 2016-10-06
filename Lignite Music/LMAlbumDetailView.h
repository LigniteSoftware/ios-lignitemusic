//
//  LMAlbumDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMAlbumView.h"
#import "LMMusicPlayer.h"

@interface LMAlbumDetailView : UIView

@property LMAlbumView *rootView;
@property LMMusicPlayer *musicPlayer;

/**
 Setup the detail view's contents.
 */
- (void)setup;

/**
 Initializes an LMAlbumDetailView with a collection as defined in the parameters.

 @param collection The collection to base this detail view off of.

 @return The initialized LMDetailView.
 */
- (instancetype)initWithMusicTrackCollection:(LMMusicTrackCollection*)collection;

@end
