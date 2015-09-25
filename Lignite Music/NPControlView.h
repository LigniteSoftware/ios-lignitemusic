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

- (id)initWithMusicPlayer:(MPMusicPlayerController*)musicPlayer;

- (void)updateWithMediaItem:(MPMediaItem*)newItem;
- (void)updateWithOrientation:(UIDeviceOrientation)newOrientation;

@end
