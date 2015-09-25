//
//  ViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "XYPieChart.h"

@interface LMNowPlayingView : UIView

@property MPMusicPlayerController *musicPlayer;

typedef enum {
    NOW_PLAYING_VIEW_MODE_FULLSCREEN = 0,
    NOW_PLAYING_VIDE_MODE_COMPRESSED,
    NOW_PLAYING_VIEW_MODE_HIDDEN
} NowPlayingViewMode;

- (void)setupView;
- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying;

@end

