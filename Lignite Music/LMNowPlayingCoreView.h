//
//  LMNowPlayingCoreView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-25.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMTutorialView.h"

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

/**
 The tutorial view for the now playing core view, if one exists.
 */
@property LMTutorialView *tutorialView;

@end
