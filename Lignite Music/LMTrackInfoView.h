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

@interface LMTrackInfoView : UIView

@property LMMarqueeLabel *titleLabel, *artistLabel, *albumLabel;

- (void)setupWithTextAlignment:(NSTextAlignment)textAlignment;

@end
