//
//  LMPlaylistDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/11/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMBrowsingView.h"

@interface LMPlaylistDetailView : UIView

/**
 The playlist associated with this LMPlaylistDetailView.
 */
@property LMMusicTrackCollection *playlistCollection;

/**
 Setup this view.
 */
- (void)setup;

@end
