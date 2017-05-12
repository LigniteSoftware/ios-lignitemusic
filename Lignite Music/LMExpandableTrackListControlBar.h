//
//  LMExpandableTrackListControlBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"
#import "LMView.h"

@class LMExpandableTrackListControlBar;

@protocol LMExpandableTrackListControlBarDelegate <NSObject>
@optional

/**
 The close button on the control bar was tapped, the detail view should be dismissed.

 @param controlBar The control bar which was tapped.
 */
- (void)closeButtonTappedForExpandableTrackListControlBar:(LMExpandableTrackListControlBar*)controlBar;

@end

@interface LMExpandableTrackListControlBar : LMView

/**
 The control bar's display/usage mode. Depending on what data the detail view is showing, this might change.

 - LMExpandableTrackListControlBarModeGeneralControl: Just a control bar on the left side with an X on the right to close the detail view.
 - LMExpandableTrackListControlBarModeControlWithAlbumDetail: A control bar with the X both on the right side, and a back button on the left with some details about the album to the right of that back button.
 */
typedef NS_ENUM(NSInteger, LMExpandableTrackListControlBarMode) {
	LMExpandableTrackListControlBarModeGeneralControl = 0,
	LMExpandableTrackListControlBarModeControlWithAlbumDetail
};

/**
 The delegate for this control bar.
 */
@property id<LMExpandableTrackListControlBarDelegate> delegate;

/**
 The mode of this control bar. Animates when changed.
 */
@property LMExpandableTrackListControlBarMode mode;

/**
 The music track collection associated with this control bar's detail view & this control bar.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 The recommended height of the expandable track list control bar.

 @return The recommended height in pixels.
 */
+ (CGFloat)recommendedHeight;

@end
