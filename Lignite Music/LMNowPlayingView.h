//
//  LMNowPlayingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMView.h"

@interface LMNowPlayingView : LMView

/**
 Gets a duration string for a total playback time.

 @param totalPlaybackTime The total playback time of the track.

 @return The formatted string. 0 padded.
 */
+ (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime;

/**
 The constraint which pins this now playing view to the top of its superview. Should be used in the pan gesture transition from top to bottom.
 */
@property NSLayoutConstraint *topConstraint;

@end
