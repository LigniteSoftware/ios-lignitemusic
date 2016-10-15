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

@property LMMusicPlayer *musicPlayer;
@property LMMusicTrackCollection *musicTitles;

- (void)setup;

@end
