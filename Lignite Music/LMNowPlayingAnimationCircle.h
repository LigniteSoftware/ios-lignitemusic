//
//  LMNowPlayingAnimationCircle.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-05.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMAppIcon.h"

typedef NS_ENUM(NSInteger, LMNowPlayingAnimationCircleDirection){
	LMNowPlayingAnimationCircleDirectionClockwise = 0,
	LMNowPlayingAnimationCircleDirectionCounterClockwise
};

@interface LMNowPlayingAnimationCircle : LMView

/**
 The direction that the animation circle is currently pointing in.
 */
@property LMNowPlayingAnimationCircleDirection direction;

/**
 The current progress of the circle.
 */
@property CGFloat progress;

/**
 The icon to display within the circle.
 */
@property LMIcon icon;

/**
 Whether or not to grow as a square instead of a circle.
 */
@property BOOL squareMode;

/**
 Sets the progress in a potentially animated manner.

 @param progress The progress to set.
 @param animated Whether or not to animate the change in progress.
 */
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end
