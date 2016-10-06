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

/**
 LMMusicPlayerType is the type of music player, such as the system music player or Spotify.
 */
typedef enum {
	LMMusicPlayerTypeSystemMusicPlayer = 0,
	LMMusicPlayerTypeAppleMusic
} LMMusicPlayerType;

/**
 LMMusicType is the type of music, for example, albums. This type is usually used within queries for music.
 */
typedef enum {
	LMMusicTypeArtists = 0,
	LMMusicTypeAlbums,
	LMMusicTypeTitles,
	LMMusicTypePlaylists,
	LMMusicTypeComposers
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

@class LMMusicPlayer;

@protocol LMMusicPlayerDelegate <NSObject>

/**
 Is called when the music track of the app changes.

 @param newTrack The new track that is playing.
 */
- (void)musicTrackDidChange:(LMMusicTrack*)newTrack;

/**
 Is called when the music playback state of the app changes.

 @param newState The new state.
 */
- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState;

@end

@interface LMMusicPlayer : NSObject

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
@property LMMusicPlaybackState playbackState;

/**
 The current repeat mode of the music player.
 */
@property MPMusicRepeatMode repeatMode;

/**
 The current shuffle mode of the music player.
 */
@property MPMusicShuffleMode shuffleMode;

/**
 Prepare for release through ARC. Unhooks observers tied to state and track change notifications.
 */
- (void)deinit;

/**
 Adds an LMMusicPlayerDelegate to the list of delegates.

 @param newDelegate The new delegate to add.
 */
- (void)addMusicDelegate:(id)newDelegate;

/**
 Removes an LMMusicPlayerDelegate from the list of delegates.

 @param delegateToRemove The delegate to remove.
 */
- (void)removeMusicDelegate:(id)delegateToRemove;

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
