//
//  NPAlbumArtView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPMediaItem+LigniteImages.h"
#ifdef SPOTIFY
#import "Spotify.h"
#endif

@interface LMAlbumArtView : UIView

@property MPMusicPlayerController *musicPlayer;

@property UIImageView *albumArtImageView;

- (void)setupWithAlbumImage:(UIImage*)albumImage;
- (void)updateContentWithMusicPlayer:(MPMusicPlayerController*)musicPlayer;
- (void)updateContentWithMusicTrack:(LMMusicTrack*)track;

@end
