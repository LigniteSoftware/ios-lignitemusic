//
//  LMAlbumViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMAlbumView : UIView

@property LMMusicPlayer *musicPlayer;

- (void)dismissViewOnTop;

@end
