//
//  LMPlaylistEditorViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMPlaylistManager.h"

@interface LMPlaylistEditorViewController : UIViewController

/**
 The playlist that is being edited/created by the playlist editor. Set this before load to automatically populate all fields with a playlist for editing.
 */
@property LMPlaylist *playlist;

@end
