//
//  LMNowPlayingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMNowPlayingView : UIView

@property LMMusicPlayer *musicPlayer;

- (void)setup;

@end
