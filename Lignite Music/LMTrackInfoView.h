//
//  LMTrackInfoView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMarqueeLabel.h"
#import "LMLabel.h"
#import "LMView.h"

@interface LMTrackInfoView : LMView

/**
 The text alignment to use.
 */
@property NSTextAlignment textAlignment;

/**
 The text of the track info view.
 */
@property NSString *titleText, *artistText, *albumText;

/**
 The labels of the track info view. PROPERTIES ON THESE SHOULD NOT BE SET. Use dedicated text setting functions for these.
 */
@property MarqueeLabel *titleLabel, *artistLabel, *albumLabel;

/**
 The text colour for all titles.
 */
@property UIColor *textColour;

/**
 Is for the miniplayer or not. Default: NO
 */
@property BOOL miniplayer;

/**
 Reloads the heights of the text.
 */
- (void)reload;

@end
