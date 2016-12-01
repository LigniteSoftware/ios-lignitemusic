//
//  LMTrackDurationView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMSlider.h"
#import "LMLabel.h"
#import "LMExtras.h"

@class LMTrackDurationView;

@protocol LMTrackDurationDelegate <NSObject>

- (void)seekSliderValueChanged:(float)newValue isFinal:(BOOL)isFinal;

@end

@interface LMTrackDurationView : UIView

@property LMSlider *seekSlider;
@property LMLabel *songCountLabel, *songDurationLabel;

@property id<LMTrackDurationDelegate> delegate;

@property BOOL shouldUpdateValue;

/**
 Whether or not the info on the duration view (the two texts) should be inset closer towards the inside of the screen.
 */
@property BOOL shouldInsetInfo;

- (BOOL)didJustFinishEditing;
- (void)setup;

@end
