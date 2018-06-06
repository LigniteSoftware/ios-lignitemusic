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

- (LMNowPlayingAnimationViewResult)progress:(CGPoint)progressPoint fromStartingPoint:(CGPoint)startingPoint;
- (void)finishAnimationWithResult:(LMNowPlayingAnimationViewResult)result acceptQuickGesture:(BOOL)acceptQuickGesture;

@end
