//
//  LMMusicDefinitions.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-21.
//  Copyright © 2018 Lignite. All rights reserved.
//

#ifndef LMMusicDefinitions_h
#define LMMusicDefinitions_h


/**
 Storage key for the user set player type. Correlates to LMMusicPlayerType.
 */
#define DEFAULTS_KEY_PLAYER_TYPE @"setPlayerType"

/**
 Storage key for the user's now playing collection.
 */
#define DEFAULTS_KEY_NOW_PLAYING_COLLECTION @"nowPlayingCollectionVersion2"

/**
 Storage key for the user's now playing track and its associated data.
 */
#define DEFAULTS_KEY_NOW_PLAYING_TRACK @"nowPlayingTrackVersion2"

/**
 LMMusicPlayerType is the type of music player, such as the system music player or Spotify.
 */
typedef enum {
	LMMusicPlayerTypeSystemMusicPlayer = 0,
	LMMusicPlayerTypeAppleMusic,
	LMMusicPlayerTypeSpotify
} LMMusicPlayerType;

/**
 LMMusicType is the type of music, for example, albums. This type is usually used within queries for music.
 */
typedef enum {
	LMMusicTypeFavourites = 0,
	LMMusicTypeArtists, //1
	LMMusicTypeAlbums, //2
	LMMusicTypeTitles, //3
	LMMusicTypePlaylists,//4
	LMMusicTypeGenres, //5
	LMMusicTypeCompilations, //6
	LMMusicTypeComposers, //7
} LMMusicType;

/**
 LMMusicPlaybackState is the playback state of the music, usually the now playing track.
 */
typedef enum {
	LMMusicPlaybackStateStopped = 0,
	LMMusicPlaybackStatePlaying,
	LMMusicPlaybackStatePaused,
	LMMusicPlaybackStateInterrupted,
	LMMusicPlaybackStateSeekingForward,
	LMMusicPlaybackStateSeekingBackward
} LMMusicPlaybackState;

/**
 LMMusicRepeatMode is the repeat mode of the music.
 */
typedef enum {
	LMMusicRepeatModeDefault = 0, //The user's default setting. Bullshit value, never use this.
	LMMusicRepeatModeNone, //Do not repeat.
	LMMusicRepeatModeAll, //Repeat all of the tracks in the current queue.
	LMMusicRepeatModeOne //Repeat this one track.
} LMMusicRepeatMode;

/**
 LMMusicRepeatMode is the repeat mode of the music.
 */
typedef enum {
	LMMusicShuffleModeOff = 0, //Do not shuffle.
	LMMusicShuffleModeOn, //Shuffle.
} LMMusicShuffleMode;


#endif /* LMMusicDefinitions_h */
