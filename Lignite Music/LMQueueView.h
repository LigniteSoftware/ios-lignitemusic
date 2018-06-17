//
//  LMQueueView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

@protocol LMQueueViewDelegate <NSObject>

/**
 The queue view changed its reordering status.

 @param isReordering Whether or not the queue view is now being reordered.
 */
- (void)queueViewIsReordering:(BOOL)isReordering;

- (void)displayQueueCantReorderWarning; //Temporary (I hope lmao)

@end

@interface LMQueueView : LMView

/**
 The delegate for the queue view.
 */
@property id<LMQueueViewDelegate> delegate;

/**
 Whether or not to display white text on the header (which has a transparent background to reveal the background image behind it).
 */
@property BOOL whiteText;

/**
 Resets the content offset of the queue view to display the currently playing track at the top.
 
 @property animated Whether or not to animate the change.
 */
- (void)resetContentOffsetToNowPlaying:(BOOL)animated;

/**
 Prepares the queue view for the rebuild event.
 */
- (void)prepareForRebuild;

@end
