//
//  LMTrackPickerController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@interface LMTrackPickerController : UIViewController

/**
 The depth level that this track picker controller is dealing its data with.

 - LMTrackPickerDepthLevelArtists: The lowest depth level, artists/composers. It is lowest because we must go from artist -> albums -> songs.
 - LMTrackPickerDepthLevelAlbums: The second lowest level, right before songs.
 - LMTrackPickerDepthLevelSongs: The highest level, where tracks can actually be selected.
 */
typedef NS_ENUM(NSInteger, LMTrackPickerDepthLevel){
	LMTrackPickerDepthLevelArtists = 0,
	LMTrackPickerDepthLevelAlbums,
	LMTrackPickerDepthLevelSongs
};

/**
 The depth level this track picker.
 */
@property LMTrackPickerDepthLevel depthLevel;

/**
 The music type associated with this track picker.
 */
@property LMMusicType musicType;

@end
