//
//  LMTutorialView.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/20/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"

#define LMTutorialViewAmountOfTutorialsKey 3

#define LMTutorialViewTutorialKeyNormalPlaylists @"LMTutorialViewTutorialKeyNormalPlaylists"
#define LMTutorialViewTutorialKeyFavourites @"LMTutorialViewTutorialKeyFavourites"
#define LMTutorialViewTutorialKeyQueueManagement @"LMTutorialViewTutorialKeyQueueManagement"

@class LMTutorialView;

@protocol LMTutorialViewDelegate <NSObject>

/**
 A tutorial view was selected by the user, playback of the associated tutorial view should begin immediately.

 @param tutorialView The tutorial view which was tapped.
 @param youTubeVideoURLString The YouTube video URL associated with this tutorial view, based off its key.
 */
- (void)tutorialViewSelected:(LMTutorialView*)tutorialView withYouTubeVideoURLString:(NSString*)youTubeVideoURLString;

@end

@interface LMTutorialView : LMView

/**
 The delegate.
 */
@property id<LMTutorialViewDelegate> delegate;

/**
 The key of the tutorial associated with this tutorial view.
 */
@property NSString *tutorialKey;

/**
 Gets the cover image of this tutorial view.

 @return The cover image.
 */
- (UIImage*)coverImage;

/**
 Simulate a tap by calling this, perfect for force touch.
 */
- (void)tapped;

@end
