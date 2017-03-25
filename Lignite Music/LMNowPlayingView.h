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
 The constraint which pins this now playing view to the top of its superview. Should be used in the pan gesture transition from top to bottom.
 */
@property NSLayoutConstraint *topConstraint;

/**
 Whether or not the now playing view is open.
 */
@property BOOL isOpen;

/**
 The track which this miniplayer holds.
 */
@property LMMusicTrack *loadedTrack;

/**
 The index of the loaded track in the queue playing.
 */
@property NSInteger loadedTrackIndex;

/**
 Change the music track that's associated with this miniplayer.
 
 @param newTrack The new track to set.
 @param index The index of the new track in its collection associated.
 */
- (void)changeMusicTrack:(LMMusicTrack*)newTrack  withIndex:(NSInteger)index;

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

@end
