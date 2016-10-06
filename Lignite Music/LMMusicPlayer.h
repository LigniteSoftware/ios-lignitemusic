//
//  LMMusicPlayer.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import "LMMusicTrack.h"
#import "LMMusicTrackCollection.h"

@interface LMMusicPlayer : NSObject

/**
 LMMusicPlayerType is the type of music player, such as the system music player or Spotify.
 */
typedef enum {
	LMMusicPlayerTypeSystemMusicPlayer = 0,
	LMMusicPlayerTypeAppleMusic
} LMMusicPlayerType;

typedef enum {
	LMMusicTypeArtists = 0,
	LMMusicTypeAlbums,
	LMMusicTypeTitles,
	LMMusicTypePlaylists,
	LMMusicTypeComposers
} LMMusicType;

/**
 The music player's current type.
 */
@property LMMusicPlayerType playerType;

/**
 The currently playing track of the music player.
 */
@property LMMusicTrack *nowPlayingTrack;

/**
 The currently playing collection. Can be nil if the user was playing music outside of Lignite Music before entering.
 */
@property LMMusicTrackCollection *nowPlayingCollection;

/**
 The index of the currently playing track in the current playback queue.
 */
@property NSUInteger indexOfNowPlayingTrack;

/**
 The current playback state of the music player.
 */
@property MPMusicPlaybackState playbackState;

/**
 The current repeat mode of the music player.
 */
@property MPMusicRepeatMode repeatMode;

/**
 The current shuffle mode of the music player.
 */
@property MPMusicShuffleMode shuffleMode;

/**
 Finds collections of music based off of the type provided.

 @param musicType The type of music to find.

 @return The collections from the query's results.
 */
- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType;

/**
 Starts playback of the next media item in the playback queue; or, the music player is not playing, 
 designates the next media item as the next to be played.
 */
- (void)skipToNextTrack;

/**
 Restarts playback at the beginning of the currently playing media item.
 */
- (void)skipToBeginning;

/**
 Starts playback of the previous media item in the playback queue; or, the music player is not playing, 
 designates the previous media item as the next to be played.
 */
- (void)skipToPreviousItem;

/**
 Play the music.
 */
- (void)play;

/**
 Pause the music.
 */
- (void)pause;


@end
