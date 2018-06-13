//
//  LMQueueView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

@interface LMQueueView : LMView

/**
 Whether or not to display white text on the header (which has a transparent background to reveal the background image behind it).
 */
@property BOOL whiteText;

/**
 Resets the content offset of the queue view to display the currently playing track at the top.
 */
- (void)resetContentOffsetToNowPlaying;

@end
