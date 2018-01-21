//
//  LMNowPlayingCoreView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-25.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

@interface LMNowPlayingCoreView : LMView

@property id rootViewController;
@property id buttonNavigationBar;

/**
 The constraint which pins this now playing view to the top of its superview. Should be used in the pan gesture transition from top to bottom.
 */
@property NSLayoutConstraint *topConstraint;

/**
 Whether or not the now playing view is open.
 */
@property BOOL isOpen;

/*
 Used for the sole purpose of refreshing all 3 now playing views when the queue has been shifted.
 */
- (void)musicTrackDidChange:(LMMusicTrack *)newTrack;

@end
