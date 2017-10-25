//
//  LMPlaylist.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMPlaylist : NSObject

/**
 The title of the playlist.
 */
@property NSString *title;

/**
 The image of the playlist, set by the user. If the user set no photo, this will be nil.
 */
@property UIImage *image;

/**
 The collection of tracks associated with this playlist.
 */
@property LMMusicTrackCollection *trackCollection;

/**
 The persistent ID for the Lignite playlist, which has nothing to do with the system.
 */
@property MPMediaEntityPersistentID persistentID;

/**
 The persistent ID of the playlist from before it was ported to Lignite Music. Will equal 0 if it was not ported and was user created.
 */
@property MPMediaEntityPersistentID systemPersistentID;

@end
