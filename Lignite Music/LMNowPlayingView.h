//
//  LMNowPlayingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMView.h"

@interface LMNowPlayingView : LMView

/**
 The core view controller, shared to provide status bar update changes.
 */
@property LMCoreViewController *coreViewController;

/**
 The core now playing view which controls this subview.
 */
@property id nowPlayingCoreView;

/**
 The constraint which pins this now playing view to the top of its superview. Should be used in the pan gesture transition from top to bottom.
 */
@property NSLayoutConstraint *topConstraint;

/**
 Whether or not the now playing view is open.
 */
@property BOOL isOpen;

/**
 Whether or not this now playing view is the one that the user can interact with (the centre now playing view within the core now playing view).
 */
@property BOOL isUserFacing DEPRECATED_ATTRIBUTE;

/**
 The track which this miniplayer holds.
 */
@property LMMusicTrack *loadedTrack DEPRECATED_ATTRIBUTE;

/**
 The index of the loaded track in the queue playing.
 */
@property NSInteger loadedTrackIndex DEPRECATED_ATTRIBUTE;

/**
 Reloads the now playing view with the now playing track.
 */
- (void)reload;

/**
 Gets a duration string for a total playback time.
 
 @param totalPlaybackTime The total playback time of the track.
 
 @return The formatted string. 0 padded.
 */
+ (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime;

/**
 Pan now playing down gesture.

 @param recognizer The gesture recognizer to forward.
 */
- (void)panNowPlayingDown:(UIPanGestureRecognizer *)recognizer;

/**
 Whether or not the now playing queue is open.

 @return Whether or not the queue is open.
 */
- (BOOL)nowPlayingQueueOpen;

/**
 Set whether or not the now playing queue is open.

 @param open Whether or not to open it.
 @param animated Whether or not to animate the transition.
 */
- (void)setShowingQueueView:(BOOL)open animated:(BOOL)animated;

@end
