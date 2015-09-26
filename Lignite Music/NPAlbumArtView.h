//
//  NPAlbumArtView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NPAlbumArtView : UIView

@property MPMusicPlayerController *musicPlayer;

- (id)init;
- (void)updateContentWithMediaItem:(MPMediaItem*)nowPlaying;
- (void)updateContentWithFrame:(CGRect)newFrame;

@end
