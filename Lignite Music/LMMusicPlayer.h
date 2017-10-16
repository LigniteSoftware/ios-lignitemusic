//
//  LMMusicPlayer.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import "LMSourceSelectorView.h"
#import "LMPebbleManager.h"
#import "MPMediaItem+LigniteImages.h"
#import "MPMediaItemCollection+LigniteInfo.h"
#import "LMButtonNavigationBar.h"

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
	LMMusicTypeArtists = 0,
	LMMusicTypeAlbums,
	LMMusicTypeTitles,
	LMMusicTypePlaylists,
	LMMusicTypeGenres,
	LMMusicTypeComposers,
	LMMusicTypeCompilations
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

@class LMMusicPlayer;

@protocol LMMusicPlayerDelegate <NSObject>
@required
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

@optional
/**
 Is called when the current playback time of the song changes.
 
 @param newPlaybackTime The new playback time.
 */
- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime;

/**
 The music library did change. When this is called, the object subscribed to this method should reload any media collections or queries it has and redraw any according layers.
 */
- (void)musicLibraryDidChange;

/**
 The output port of the music changed.
 
 @param audioRoute The new output port.
 */
- (void)musicOutputPortDidChange:(AVAudioSessionPortDescription*)outputPort;

/**
 A playback mode changed. Included in one delegate function instead of complicating with two.

 @param shuffleMode The current shuffle mode.
 @param repeatMode The current repeat mode.
 */
- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode;

/**
 A track was added to the queue.

 @param trackAdded The track that was added.
 */
- (void)trackAddedToQueue:(LMMusicTrack*)trackAdded;

/**
 A track was removed from the queue.
 
 @param trackAdded The track that was removed.
 */
- (void)trackRemovedFromQueue:(LMMusicTrack*)trackRemoved;

/**
 A track was moved around the queue.

 @param trackMoved The track that was moved.
 */
- (void)trackMovedInQueue:(LMMusicTrack*)trackMoved;
@end

@interface LMMusicPlayer : NSObject



- (void)addTrackToQueue:(LMMusicTrack*)trackToAdd;
- (void)removeTrackFromQueue:(LMMusicTrack*)trackToRemove;
- (void)moveTrackInQueueFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;


/**
 The system music player.
 */
@property MPMusicPlayerController *systemMusicPlayer;

/**
 The music player's current type.
 */
@property LMMusicPlayerType playerType;

/**
 The currently playing track of the music player.
 */
@property LMMusicTrack *nowPlayingTrack;

/**
 The currently playing collection. Should rarely be nil, though nil cases should still be handled.
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
 The current point in time which the now playing track is at in seconds.
 */
@property NSTimeInterval currentPlaybackTime;

/**
 The current repeat mode of the music player.
 */
@property LMMusicRepeatMode repeatMode;

/**
 The current shuffle mode of the music player.
 */
@property LMMusicShuffleMode shuffleMode;

/**
 Whether or not the music should continue to play when the audioPlayer switches tracks.
 */
@property BOOL autoPlay;

/**
 The source selector for the music app. This is the bottom part which is never destroyed, and should be set on init. The music player uses this to set the source title and source subtitle.
 */
@property LMSourceSelectorView *sourceSelector;

/**
 The navigation bar which goes at the bottom of the screen to help the user navigate their music.
 */
@property LMButtonNavigationBar *navigationBar;

/**
 The shared music player.
 
 @return The shared music player.
 */
+ (LMMusicPlayer*)sharedMusicPlayer;

/**
 Prepare for release through ARC. Unhooks observers tied to state and track change notifications.
 */
- (void)deinit;

/**
 Prepare for app termination. The music player will transfer the contents of the now playing item to the system music player should it be using the system music player.
 */
- (void)prepareForTermination;

/**
 Prepare for when the app is coming back into the foreground (being activated again).
 */
- (void)prepareForActivation;

/**
 Adds an LMMusicPlayerDelegate to the list of delegates.
 
 @param newDelegate The new delegate to add.
 */
- (void)addMusicDelegate:(id<LMMusicPlayerDelegate>)newDelegate;

/**
 Removes an LMMusicPlayerDelegate from the list of delegates.
 
 @param delegateToRemove The delegate to remove.
 */
- (void)removeMusicDelegate:(id<LMMusicPlayerDelegate>)delegateToRemove;

/**
 Gets a dictionary of the letters available. The key is the letter, the object is an NSNumber of the index in which that letter is first available within that collection.
 
 @param collectionArray The collection array to scan for.
 @param musicType The music type the letters are associated to.
 @return The dictionary of letters with their indexes.
 */
- (NSDictionary*)lettersAvailableDictionaryForMusicTrackCollectionArray:(NSArray<LMMusicTrackCollection*>*)collectionArray
												withAssociatedMusicType:(LMMusicType)musicType;

/**
 Gets the track collections for a media query with a certain music type.
 
 @param mediaQuery The media query to convert.
 @param musicType The music type associated.
 @return The array of collections.
 */
- (NSArray<LMMusicTrackCollection*>*)trackCollectionsForMediaQuery:(id)mediaQuery withMusicType:(LMMusicType)musicType;

/**
 Compiles an array of collections associated to a persistent ID from a track and music type. For example, the track with a persistent ID of Chiddy Bang and the music type of LMMusicTypeArtists would result in collections of all of Chiddy Bang's albums.
 
 @param representativeTrack The representative track to use in the query and pull data from.
 @param musicType The music type to group for.
 @return The grouped collections.
 */
- (NSArray<LMMusicTrackCollection*>*)collectionsForRepresentativeTrack:(LMMusicTrack*)representativeTrack forMusicType:(LMMusicType)musicType;

/**
 Finds collections of music based off of the type provided.
 
 @param musicType The type of music to find.
 
 @return The collections from the query's results.
 */
- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType;

/**
 Automatically restarts the song if only been playing for less than 5 seconds, otherwise goes back.
 */
- (void)autoBackThrough;

/**
 Starts playback of the next media item in the playback queue; or, the music player is not playing, designates the next media item as the next to be played.
 */
- (void)skipToNextTrack;

/**
 Restarts playback at the beginning of the currently playing media item.
 */
- (void)skipToBeginning;

/**
 Starts playback of the previous media item in the playback queue; or, the music player is not playing, designates the previous media item as the next to be played.
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

/**
 Stop the music completely.
 */
- (void)stop;

/**
 Invert the current playback state. If the music is paused/stopped, it will play the music, otherwise it will pause the music.
 */
- (LMMusicPlaybackState)invertPlaybackState;

/**
 Whether or not the music player has a track loaded.
 
 @return If a track is loaded. NO if track contains nil title, YES if there is a track.
 */
- (BOOL)hasTrackLoaded;

/**
 Save the now playing state to user defaults.
 */
- (void)saveNowPlayingState;

/**
 Load the now playing state from storage.
 */
- (void)loadNowPlayingState;

/**
 Gets the currently saved LMMusicPlayerType through NSUserDefaults. Returns LMMusicPlayerTypeSystemMusicPlayer if the entry doesn't exist in NSUserDefaults.
 
 @return The saved LMMusicPlayerType.
 */
+ (LMMusicPlayerType)savedPlayerType;

/**
 Checks whether or not a now playing collection is equal to the currently playing collection or its shuffled version.

 @param musicTrackCollection The music track collection to compare with.
 @return Whether or not it's equal to either the shuffled collection which is now playing or the sorted base collection.
 */
- (BOOL)nowPlayingCollectionIsEqualTo:(LMMusicTrackCollection*)musicTrackCollection;

/**
 Whether or not an output port is wireless.
 
 @param outputPort The audio route to check.
 @return Whether or not that route is wireless (ie. Bluetooth).
 */
+ (BOOL)outputPortIsWireless:(AVAudioSessionPortDescription*)outputPort;

/**
 The pebbleManager manages the connection between the phone and the Pebble. It is directly linked to the music player to ensure that new data is pushed directly to the watch without a view or view controller required.
 */
@property LMPebbleManager *pebbleManager;

@end
