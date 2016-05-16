//
//  NPControlView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMExtras.h"

@interface NPControlView : UIView

- (id)initWithMusicPlayer:(MPMusicPlayerController*)musicPlayer withViewMode:(uint8_t)viewMode onFrame:(CGRect)frame;

- (IBAction)setPlaying:(id)sender;
- (void)updateWithMediaItem:(MPMediaItem*)newItem;
- (void)updateWithRootFrame:(CGRect)newRootFrame withViewMode:(BOOL)newViewMode;

@end
