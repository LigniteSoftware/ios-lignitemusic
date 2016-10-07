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

@interface LMTrackDurationView : UIView

@property LMSlider *seekSlider;
@property LMLabel *songCountLabel, *songDurationLabel;

- (void)setup;

@end
