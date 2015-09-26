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
    NOW_PLAYING_VIEW_MODE_LANDSCAPE = 0,
    NOW_PLAYING_VIEW_MODE_PORTRAIT,
    NOW_PLAYING_VIDE_MODE_COMPRESSED_LANDSCAPE,
    NOW_PLAYING_VIDE_MODE_COMPRESSED_PORTRAIT,
    NOW_PLAYING_VIEW_MODE_HIDDEN
} NowPlayingViewMode;

- (void)setupView;
- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying;

@end

