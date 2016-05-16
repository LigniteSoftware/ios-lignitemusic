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
#import "NPControlView.h"
#import "NPTextInfoView.h"
#import "NPAlbumArtView.h"

@interface LMNowPlayingView : UIView

@property MPMusicPlayerController *musicPlayer;

@property NPAlbumArtView *albumArtView;
@property NPControlView *controlView;
@property NPTextInfoView *songInfoView;

typedef enum {
    NowPlayingViewModeLandscape = 0,
    NowPlayingViewModePortrait,
    NowPlayingViewModeMiniLandscape,
    NowPlayingViewModeMiniPortrait,
    NowPlayingViewModeHidden
} NowPlayingViewMode;

- (id)initWithFrame:(CGRect)frame withViewMode:(NowPlayingViewMode)newViewMode;
- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying;


@end

