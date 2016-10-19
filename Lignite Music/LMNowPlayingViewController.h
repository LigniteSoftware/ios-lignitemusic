//
//  TestViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMPebbleManager.h"

@interface LMNowPlayingViewController : UIViewController

@property (weak) MPMusicPlayerController *musicPlayer;

@end
