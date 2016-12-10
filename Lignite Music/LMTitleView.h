//
//  LMTitleView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMTitleView : UIView

@property LMMusicTrackCollection *musicTitles;

- (void)setup;
- (void)reloadSourceSelectorInfo;

/**
 Scrolls to an index of a track.

 @param index The index to scroll to.
 */
- (void)scrollToTrackIndex:(NSUInteger)index;

/**
 Scroll to a track with its persistent ID.

 @param persistentID The persistent ID of the track to scroll to.
 */
- (void)scrollToTrackWithPersistentID:(LMMusicTrackPersistentID)persistentID;

@end
