//
//  LMAccessibilityMusicControlBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 3/16/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"

typedef NS_ENUM(NSInteger, LMAccessibilityControlButtonType){
	LMAccessibilityControlButtonTypeToggleNowPlaying = 0
};

@protocol LMAccessibilityMusicControlBarDelegate <NSObject>
@required

/**
 An accessibility control bar button that can't be managed by itself was tapped. The delegate should take action from this point forward in completing the desired action.

 @param controlButtonType The button type that was tapped.
 */
- (void)accessibilityControlBarButtonTapped:(LMAccessibilityControlButtonType)controlButtonType;

@end

@interface LMAccessibilityMusicControlBar : LMView

/**
 The delegate.
 */
@property id<LMAccessibilityMusicControlBarDelegate> delegate;

/**
 Whether or not the control bar is being used for the mini player. Default is NO.
 */
@property BOOL isMiniPlayer;

@end
