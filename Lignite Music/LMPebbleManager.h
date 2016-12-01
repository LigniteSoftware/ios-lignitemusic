//
//  LMPebbleManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMPebbleMessageQueue.h"

@class LMMusicPlayer;

@interface LMPebbleManager : NSObject

typedef enum {
	NowPlayingTitle = 0,
	NowPlayingArtist,
	NowPlayingAlbum,
	NowPlayingTitleArtist,
	NowPlayingNumbers,
} NowPlayingType;

typedef enum {
	NowPlayingStatePlayPause = 1,
	NowPlayingStateSkipNext,
	NowPlayingStateSkipPrevious,
	NowPlayingStateVolumeUp,
	NowPlayingStateVolumeDown
} NowPlayingState;

typedef enum {
	NowPlayingRequestTypeAllData = 0,
	NowPlayingRequestTypeOnlyTrackInfo,
	NowPlayingRequestTypeOnlyAlbumArt
} NowPlayingRequestType;

typedef enum {
	WATCH_INFO_MODEL_UNKNOWN = 0,          //Unknown model.
	WATCH_INFO_MODEL_PEBBLE_ORIGINAL,      //Original Pebble.
	WATCH_INFO_MODEL_PEBBLE_STEEL,         //Pebble Steel.
	WATCH_INFO_MODEL_PEBBLE_TIME,          //Pebble Time.
	WATCH_INFO_MODEL_PEBBLE_TIME_STEEL,    //Pebble Time Steel.
	WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_14, //Pebble Time Round, 14mm luggy duggy size.
	WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_20, //Pebble Time Round, 20mm luggy duggy size.
	WATCH_INFO_MODEL_PEBBLE_2_HR,		   //Pebble 2 with heart rate.
	WATCH_INFO_MODEL_PEBBLE_2_SE,		   //Pebble 2 without heart rate.
	WATCH_INFO_MODEL_PEBBLE_TIME_2,		   //Pebble Time 2
	WATCH_INFO_MODEL_MAX				   //An unknown Pebble maybe? Future people, can you tell us what Pebbles are next?
} WatchInfoModel;

typedef enum {
	TrackPlayModeShuffleAll = 10,
	TrackPlayModeRepeatModeNone = 20,
	TrackPlayModeRepeatModeOne = 21,
	TrackPlayModeRepeatModeAll = 22
} TrackPlayMode;

#define MessageKeyReconnect @(0)
#define MessageKeyRequestLibrary @(1)
#define MessageKeyRequestOffset @(2)
#define MessageKeyLibraryResponse @(3)
#define MessageKeyNowPlaying @(4)
#define MessageKeyRequestParent @(5)
#define MessageKeyPlayTrack @(6)
#define MessageKeyNowPlayingResponseType @(7)
#define MessageKeyAlbumArt @(8)
#define MessageKeyAlbumArtLength @(9)
#define MessageKeyAlbumArtIndex @(10)
#define MessageKeyChangeState @(11)
#define MessageKeyCurrentState @(12)
#define MessageKeySequenceNumber @(13)
#define MessageKeyHeaderIcon @(14)
#define MessageKeyHeaderIconLength @(15)
#define MessageKeyHeaderIconIndex @(16)
#define MessageKeyWatchModel @(17)
#define MessageKeyImagePart @(18)
#define MessageKeyAppMessageSize @(19)
#define MessageKeyTrackPlayMode @(20)
#define MessageKeyFirstOpen @(21)
#define MessageKeyConnectionTest @(22)

#define MAX_LABEL_LENGTH 20
#define MAX_RESPONSE_COUNT 90

/**
 The message queue for communicating with Pebble.
 */
@property LMPebbleMessageQueue *messageQueue;

/**
 The shared Pebble manager.

 @return The shared Pebble manager.
 */
+ (id)sharedPebbleManager;

/**
 Set the manager's music player. Only needs to be set once, and should be called from within LMMusicPlayer's Singleton creation dispatch.

 @param musicPlayer The music player to set.
 */
- (void)setManagerMusicPlayer:(LMMusicPlayer*)musicPlayer;

/**
 Attaches the Pebble manager to a view controller. When called with a non-nil view controller, a volume control is added to that view controller's view to allow volume control on Pebble. It also uses the associated UIStoryBoard to get the settings view controller.
 
 @param viewControllerToAttachTo The view controller to attach to.
 */
- (void)attachToViewController:(UIViewController*)viewControllerToAttachTo;

/**
 Show a settings window for the Pebble app.
 */
- (void)showSettings;

@end
