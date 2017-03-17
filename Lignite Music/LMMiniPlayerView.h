//
//  LMMiniPlayerView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMMiniPlayerView : UIView

/**
 The track which this miniplayer holds.
 */
@property LMMusicTrack *loadedTrack;

/**
 The index of the loaded track in the queue playing.
 */
@property NSInteger loadedTrackIndex;

/**
 Change the music track that's associated with this miniplayer.

 @param newTrack The new track to set.
 @param index The index of the new track in its collection associated.
 */
- (void)changeMusicTrack:(id)newTrack  withIndex:(NSInteger)index;

- (void)setup;

@end
