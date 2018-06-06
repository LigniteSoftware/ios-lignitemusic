//
//  LMMiniPlayerView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMView.h"

@interface LMMiniPlayerView : LMView

/**
 Trust me, I want to learn what better pattern to use than passing pointers around, but I'm just in too much of a rush to justify it right now. Sorry :(
 */
@property id rootViewController;

/**
 The track which this miniplayer holds.
 */
@property LMMusicTrack *loadedTrack DEPRECATED_MSG_ATTRIBUTE("Please use the now playing track");

/**
 The index of the loaded track in the queue playing.
 */
@property NSInteger loadedTrackIndex DEPRECATED_MSG_ATTRIBUTE("Please use the now playing index");

/**
 Whether or not this miniplayer is user facing (is the centre miniplayer).
 */
@property BOOL isUserFacing DEPRECATED_MSG_ATTRIBUTE("Please don't use this awful API");

/**
 Reloads the contents of the mini player with the now playing track.
 */
- (void)reload;

@end
