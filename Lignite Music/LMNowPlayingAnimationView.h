//
//  LMNowPlayingAnimationView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-05.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"

typedef NS_ENUM(NSInteger, LMNowPlayingAnimationViewResult){
	LMNowPlayingAnimationViewResultSkipToNextIncomplete = 0,
	LMNowPlayingAnimationViewResultSkipToNextComplete,
	LMNowPlayingAnimationViewResultGoToPreviousIncomplete,
	LMNowPlayingAnimationViewResultGoToPreviousComplete
};

@interface LMNowPlayingAnimationView : LMView

/**
 Whether or not to grow the animation as a square instead of a circle.
 */
@property BOOL squareMode;

/**
 Progresses the animation along from a certain starting point.

 @param progressPoint The current point of the user's gesture.
 @param startingPoint The starting point of the user's gesture.
 @return The current result based on the difference between the starting point and the progress point of the gesture.
 */
- (LMNowPlayingAnimationViewResult)progress:(CGPoint)progressPoint fromStartingPoint:(CGPoint)startingPoint;

/**
 Finishes the animation with a certain result, overridden by an accepted quick gesture.

 @param result The result to finalise the animation/gesture with.
 @param acceptQuickGesture Whether or not the user made a quick gesture. If so, even an incomplete gesture will be accepted as the user didn't take the time to complete it but meant to by doing a quick swipe.
 */
- (void)finishAnimationWithResult:(LMNowPlayingAnimationViewResult)result acceptQuickGesture:(BOOL)acceptQuickGesture;

@end
