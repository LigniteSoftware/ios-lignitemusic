//
//  LMTiledAlbumCoverView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMTiledAlbumCoverView : UIView

/**
 The music collection associated with this LMTiledAlbumCoverView.
 */
@property LMMusicTrackCollection *musicCollection;

/**
 The simple mode which will lay out the view in 2*2 square and reduce lag. Temporary patch.
 */
@property BOOL simpleMode;

@end
