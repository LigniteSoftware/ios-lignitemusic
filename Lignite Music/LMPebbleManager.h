//
//  LMPebbleManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMusicPlayer.h"

@interface LMPebbleManager : NSObject

typedef enum {
	NowPlayingTitle,
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
	WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_14, //Pebble Time Round, 14mm lug size.
	WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_20, //Pebble Time Round, 20mm lug size.
	WATCH_INFO_MODEL_MAX				   //Probably the Pebble 2.
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
 Initialize the Pebble manager with a music player which will control its data and will be used to gather information on the music that should be sent to the watch.

 @param musicPlayer The music player to associate.

 @return The new Pebble manager.
 */
- (instancetype)initWithMusicPlayer:(LMMusicPlayer*)musicPlayer;

/**
 The music player for this Pebble manager.
 */
@property LMMusicPlayer *musicPlayer;

@end
