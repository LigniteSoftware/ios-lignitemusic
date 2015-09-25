//
//  LMMainViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface LMMainViewController : UIViewController

@property MPMusicPlayerController *musicPlayer;

typedef enum {
    SWITCHER_TYPE_ALBUM
} SwitcherType;

@end
