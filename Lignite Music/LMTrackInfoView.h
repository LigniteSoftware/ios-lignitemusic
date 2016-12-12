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
 The labels of the track info view.
 */
@property MarqueeLabel *titleLabel, *artistLabel, *albumLabel;

@end
