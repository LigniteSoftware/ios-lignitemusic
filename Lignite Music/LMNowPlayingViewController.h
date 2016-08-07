//
//  TestViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MarqueeLabel.h"
#import "LMButton.h"
#import "NPAlbumArtView.h"
#import "LMSlider.h"

@interface LMNowPlayingViewController : UIViewController

@property (weak) MPMusicPlayerController *musicPlayer;

@property IBOutlet UIView *contentContainerView;

@property IBOutlet UIImageView *backgroundImageView;
@property IBOutlet NPAlbumArtView *albumArtView;
@property IBOutlet LMSlider *songDurationSlider;
@property IBOutlet UILabel *songNumberLabel, *songDurationLabel;
@property IBOutlet MarqueeLabel *songTitleLabel, *songArtistLabel, *songAlbumLabel;

@property IBOutlet LMButton *shuffleButton, *repeatButton, *dynamicPlaylistButton;

@end
