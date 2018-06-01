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
#import "MPMediaItem+LigniteImages.h"
#import "MPMediaItemCollection+LigniteInfo.h"
#import "LMButtonNavigationBar.h"
#import "LMMusicQueue.h"

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

@class LMMusicPlayer;

@protocol LMMusicPlayerDelegate <NSObject>
@optional
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

/**
 Is called when the current playback time of the song changes.
 
 @param newPlaybackTime The new playback time.
 @param userModified Whether or not the playback was user modified or was automatically updated by the system.
 */
- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime userModified:(BOOL)userModified;

/**
 The music library changed.
 
 @param finished Whether or not the sync has complete. If finished, views should resync music collections and reload their collections.
 */
- (void)musicLibraryChanged:(BOOL)finished;

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
 A track was added to favourites.

 @param track The track that was added to favourites.
 */
- (void)trackAddedToFavourites:(LMMusicTrack*)track;

/**
 A track was removed from favourites.
 
 @param track The track that was removed from favourites.
 */
- (void)trackRemovedFromFavourites:(LMMusicTrack*)track;

/**
 The status of VoiceOver being on/off changed.

 @param voiceOverEnabled Whether or not VoiceOver is now enabled.
 */
- (void)voiceOverStatusChanged:(BOOL)voiceOverEnabled;

@end


@interface LMMusicPlayer : NSObject

- (void)addTrackToQueue:(LMMusicTrack*)trackToAdd DEPRECATED_ATTRIBUTE;
- (void)removeTrackFromQueue:(LMMusicTrack*)trackToRemove DEPRECATED_ATTRIBUTE;
- (void)moveTrackInQueueFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex DEPRECATED_ATTRIBUTE;
- (void)prepareQueueModification DEPRECATED_ATTRIBUTE;
- (void)finishQueueModification DEPRECATED_ATTRIBUTE;
- (void)prepareQueueForBackgrounding DEPRECATED_ATTRIBUTE;

@property BOOL nowPlayingQueueTooLarge; //The full queue from the system is not being shown, for whatever fucking reason

/**
 The playback queue.
 */
@property LMMusicQueue *queue;

/**
 The system music player.
 */
@property MPMusicPlayerController *systemMusicPlayer;

/**
 Whether or not the queue requires reloading (setting inside of the system playback
 */
@property BOOL queueRequiresReload DEPRECATED_ATTRIBUTE;

/**
 Whether or not the player is in demo mode.
 */
@property (readonly) BOOL demoMode;

/**
 Whether or not the user has set music within the app. If NO, the app should reject queue requests and whatnot. Gotta love walled gardens.
 */
@property (readonly) BOOL nowPlayingWasSetWithinLigniteMusic DEPRECATED_ATTRIBUTE;

/**
 The music player's current type.
 */
@property (readonly) LMMusicPlayerType playerType;

/**
 The currently playing track of the music player.
 */
@property LMMusicTrack *nowPlayingTrack;

/**
 The currently playing collection. Should rarely be nil, though nil cases should still be handled.
 */
@property LMMusicTrackCollection *nowPlayingCollection DEPRECATED_ATTRIBUTE;

/**
 The index of the currently playing track in the current playback queue.
 */
@property NSUInteger indexOfNowPlayingTrack DEPRECATED_ATTRIBUTE;

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
 Returns a sort descriptor which sorts arrays alphabetically, and ignores the word "the" (case insensitive).
 
 @param sortKey The key to sort by.
 @return The sort descriptor.
 */
- (NSSortDescriptor*)alphabeticalSortDescriptorForSortKey:(NSString*)sortKey;

/**
 Whether or not the user has completed onboarding. If not, the sharedMusicPlayer singleton instance should not be initialized.

 @return Whether or not onboarding is complete.
 */
+ (BOOL)onboardingComplete;

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
 Converts a single track collection into an array of track collections. Helpful for unifying titles and favourites across the app.
 
 @param collection The collection to convert into an array of collections.
 @return An array of track collections, each of which have one item in them.
 */
+ (NSArray<LMMusicTrackCollection*>*)arrayOfTrackCollectionsForMusicTrackCollection:(LMMusicTrackCollection*)collection;

/**
 Condenses an array of track collections down into a single track collection which contains all songs from the track collections inside of the array of track collections.
 
 @param arrayOfTrackCollections The array of track collections to compile into a track collection.
 @return A single track collection containing all songs from the track collections in the array.
 */
+ (LMMusicTrackCollection*)trackCollectionForArrayOfTrackCollections:(NSArray<LMMusicTrackCollection*>*)arrayOfTrackCollections;

/**
 Compares two track collections against one another for equality.
 
 @param trackCollection The first track collection.
 @param otherTrackCollection The other track collection.
 @return Whether or not they equal in contents.
 */
+ (BOOL)trackCollection:(LMMusicTrackCollection*)trackCollection isEqualToOtherTrackCollection:(LMMusicTrackCollection*)otherTrackCollection;

/**
 Returns a persistent ID property string for a certain music type.

 @param musicType The music type to get the persistent ID property string for.
 @return The property string.
 */
+ (NSString*)persistentIDPropertyStringForMusicType:(LMMusicType)musicType;

/**
 Gets a persistent ID of a music track collection's representative item based off of a music type.

 @param trackCollection The track collection to get the persistent ID for.
 @param musicType The music type.
 @return The persistent ID.
 */
+ (MPMediaEntityPersistentID)persistentIDForMusicTrackCollection:(LMMusicTrackCollection*)trackCollection withMusicType:(LMMusicType)musicType;

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
- (NSArray<LMMusicTrackCollection*>*)collectionsForPersistentID:(MPMediaEntityPersistentID)persistentID forMusicType:(LMMusicType)musicType; //Does the same but just with a persistent ID.
- (NSArray<LMMusicTrackCollection*>*)collectionsForWatchForPersistentID:(MPMediaEntityPersistentID)persistentID
														   forMusicType:(LMMusicType)musicType; //Does the same but is for Apple Watch's tree based browsing

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
- (void)skipToPreviousTrack;

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
 The track collection of all of the user's favourite tracks.

 @return The collection of favourites.
 */
- (LMMusicTrackCollection*)favouritesTrackCollection;

/**
 Add a certain track to favourites.

 @param track The track to add to favourites.
 */
- (void)addTrackToFavourites:(LMMusicTrack*)track;

/**
 Removes a certain track from favourites.

 @param track The track to remove from favourites.
 */
- (void)removeTrackFromFavourites:(LMMusicTrack*)track;

/**
 Whether or not an output port is wireless.
 
 @param outputPort The audio route to check.
 @return Whether or not that route is wireless (ie. Bluetooth).
 */
+ (BOOL)outputPortIsWireless:(AVAudioSessionPortDescription*)outputPort;

/**
 Applies the demo filter to a query, if the secret setting has been enabled.

 @param query The query to apply the demo filter for.
 */
- (void)applyDemoModeFilterIfApplicableToQuery:(MPMediaQuery*)query;

@end
