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

@property LMMusicPlayer *musicPlayer;

- (void)setup;

@end
