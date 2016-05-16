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

- (void)setupWithAlbumImage:(UIImage*)albumImage;
- (void)updateContentWithMediaItem:(MPMediaItem*)nowPlaying;

@end