//
//  LMTrackPickerController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMMusicPickerController.h"

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

/**
 The music type of the track picker which presented this track picker.
 */
@property LMMusicType previousMusicType;

/**
 The track collections for this picker.
 */
@property NSArray<LMMusicTrackCollection*> *trackCollections;

/**
 The track collection for favourites and titles.
 */
@property (readonly) LMMusicTrackCollection *titleTrackCollection;

/**
 The track collection of songs that have been selected by the user for this music picker.
 */
@property (readonly) LMMusicTrackCollection *selectedTrackCollection;

/**
 The track collections that the picker should display. This changes based on whether or not the user is searching.
 */
@property (readonly) NSArray<LMMusicTrackCollection*> *displayingTrackCollections;

/**
 The title collections that the picker should display. This changes based on whether or not the user is searching.
 */
@property (readonly) LMMusicTrackCollection *displayingTitleTrackCollection;

/**
 The source music picker controller that contains the original selected track collection. Called upon to modify the selected tracks.
 */
@property LMMusicPickerController *sourceMusicPickerController;

@end
