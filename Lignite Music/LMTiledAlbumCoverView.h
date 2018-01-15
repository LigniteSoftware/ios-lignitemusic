//
//  LMTiledAlbumCoverView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMTiledAlbumCoverView : UIView

/**
 The music collection associated with this LMTiledAlbumCoverView. Setting this reloads the cover.
 */
@property LMMusicTrackCollection *musicCollection;

@end
