//
//  LMWCompanionBridge.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMWMusicTrackInfo.h"
#import "LMWNowPlayingInfo.h"

//The title of the track. Is an NSString.
#define LMAppleWatchMusicTrackInfoKeyTitle @"LMAppleWatchMusicTrackInfoKeyTitle"
//The subtitle for the track. Is an NSString.
#define LMAppleWatchMusicTrackInfoKeySubtitle @"LMAppleWatchMusicTrackInfoKeySubtitle"
//Whether or not the track is a favourite. Is a BOOL wrapped in an NSNumber.
#define LMAppleWatchMusicTrackInfoKeyIsFavourite @"LMAppleWatchMusicTrackInfoKeyIsFavourite"
//The track's persistent ID. Is a longLong disguised as an NSNumber.
#define LMAppleWatchMusicTrackInfoKeyPersistentID @"LMAppleWatchMusicTrackInfoKeyPersistentID"
//The track's album persistent ID. Is a longLong disguised as an NSNumber.
#define LMAppleWatchMusicTrackInfoKeyAlbumPersistentID @"LMAppleWatchMusicTrackInfoKeyAlbumPersistentID"
//The total playback duration of the music track. Is an NSInteger wrapped in an NSNumber.
#define LMAppleWatchMusicTrackInfoKeyPlaybackDuration @"LMAppleWatchMusicTrackInfoKeyPlaybackDuration"
//The current playback time of the music track. Is an NSInteger wrapped in an NSNumber.
#define LMAppleWatchMusicTrackInfoKeyCurrentPlaybackTime @"LMAppleWatchMusicTrackInfoKeyCurrentPlaybackTime"

//Whether or not the now playing track is playing. BOOL as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyIsPlaying @"LMAppleWatchNowPlayingInfoKeyIsPlaying"
//The current repeat mode. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyRepeatMode @"LMAppleWatchNowPlayingInfoKeyRepeatMode"
//The current shuffle mode. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyShuffleMode @"LMAppleWatchNowPlayingInfoKeyShuffleMode"
//The track playback duration in seconds. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyPlaybackDuration @"LMAppleWatchNowPlayingInfoKeyPlaybackDuration"
//The track's current playback time. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime @"LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime"

//The key to be used as the key for defining which type of data is being transmitted.
#define LMAppleWatchCommunicationKey @"LMAppleWatchCommunicationKey"
//The now playing track is what's being transmitted.
#define LMAppleWatchCommunicationKeyNowPlayingTrack @"LMAppleWatchCommunicationKeyNowPlayingTrack"
//Nothing is playing.
#define LMAppleWatchCommunicationKeyNoTrackPlaying @"LMAppleWatchCommunicationKeyNoTrackPlaying"
//The now playing info is what's being transmitted.
#define LMAppleWatchCommunicationKeyNowPlayingInfo @"LMAppleWatchCommunicationKeyNowPlayingInfo"
//The next 5 items of the now playing queue.
#define LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue @"LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue"
//The watch is requesting music tracks or entries in music browsing.
#define LMAppleWatchCommunicationKeyMusicBrowsingEntries @"LMAppleWatchCommunicationKeyMusicBrowsingEntries"

//The key for the music types when the communication key is LMAppleWatchCommunicationKeyMusicBrowsingEntries. Music types is plural because it's an array of music types which define the structure of windows that the user has been presented in their current browsing session.
#define LMAppleWatchBrowsingKeyMusicTypes @"LMAppleWatchBrowsingKeyMusicTypes"
//The key for the persistent IDs, used as a source of data.
#define LMAppleWatchBrowsingKeyPersistentIDs @"LMAppleWatchBrowsingKeyPersistentIDs"
//The key for the user's selected indexes in browsing. First page index will always be -1.
#define LMAppleWatchBrowsingKeySelectedIndexes @"LMAppleWatchBrowsingKeySelectedIndexes"
//The key for the user's page indexes in browsing.
#define LMAppleWatchBrowsingKeyPageIndexes @"LMAppleWatchBrowsingKeyPageIndexes"

//The keys for the properties which go in a music track/music browsing entry.
#define LMAppleWatchBrowsingKeyEntryPersistentID @"LMAppleWatchBrowsingKeyEntryPersistentID"
#define LMAppleWatchBrowsingKeyEntryTitle @"LMAppleWatchBrowsingKeyEntryTitle"
#define LMAppleWatchBrowsingKeyEntrySubtitle @"LMAppleWatchBrowsingKeyEntrySubtitle"
#define LMAppleWatchBrowsingKeyEntryIcon @"LMAppleWatchBrowsingKeyEntryIcon"

//Whether or not the list of entries has reached the end of the complete list.
#define LMAppleWatchBrowsingKeyIsEndOfList @"LMAppleWatchBrowsingKeyIsEndOfList"
//Whether or not it's the beginning of the list.
#define LMAppleWatchBrowsingKeyIsBeginningOfList @"LMAppleWatchBrowsingKeyIsBeginningOfList"
//The amount of entries remaining after the list that's being sent.
#define LMAppleWatchBrowsingKeyRemainingEntries @"LMAppleWatchBrowsingKeyRemainingEntries"
//The total amount of entries.
#define LMAppleWatchBrowsingKeyTotalNumberOfEntries @"LMAppleWatchBrowsingKeyTotalNumberOfEntries"

//Invert the play/pause status from whatever it is now.
#define LMAppleWatchControlKeyPlayPause @"LMAppleWatchControlKeyPlayPause"
//Skip to the next track in the queue.
#define LMAppleWatchControlKeyNextTrack @"LMAppleWatchControlKeyNextTrack"
//Go back to the previous track in the queue.
#define LMAppleWatchControlKeyPreviousTrack @"LMAppleWatchControlKeyPreviousTrack"
//Invert the favourite status of this track.
#define LMAppleWatchControlKeyFavouriteUnfavourite @"LMAppleWatchControlKeyFavouriteUnfavourite"
//Invert the shuffle mode.
#define LMAppleWatchControlKeyInvertShuffleMode @"LMAppleWatchControlKeyInvertShuffleMode"
//Switches the repeat mode to the next repeat mode.
#define LMAppleWatchControlKeyNextRepeatMode @"LMAppleWatchControlKeyNextRepeatMode"
//Changes the now playing queue track based off of one of the "up next" tracks.
#define LMAppleWatchControlKeyUpNextTrackSelected @"LMAppleWatchControlKeyUpNextTrackSelected"
//The current playback time. NEEDS to be sent along with a key:value pair of LMAppleWatchControlKeyCurrentPlaybackTime:<NSNumber*>playbackTime.
#define LMAppleWatchControlKeyCurrentPlaybackTime @"LMAppleWatchControlKeyCurrentPlaybackTime"

@protocol LMWCompanionBridgeDelegate<NSObject>
@optional

/**
 The music track changed, as per the phone's request. Delegate should update UI accordingly.

 @param musicTrackInfo The new music track.
 */
- (void)musicTrackDidChange:(LMWMusicTrackInfo*)musicTrackInfo;

/**
 The album art changed for the now playing track.

 @param albumArt The new album art.
 */
- (void)albumArtDidChange:(UIImage*)albumArt;

/**
 The now playing info changed. Delegate should update UI accordingly.

 @param nowPlayingInfo The new now playing info.
 */
- (void)nowPlayingInfoDidChange:(LMWNowPlayingInfo*)nowPlayingInfo;

/**
 The now playing queue up next changed.

 @param upNextTracks The tracks which are up next.
 */
- (void)nowPlayingUpNextDidChange:(NSArray<LMWMusicTrackInfo*>*)upNextTracks;

/**
 Asks the delegate to display a debug message, if possible.

 @param debug The debug message to display.
 */
- (void)companionDebug:(NSString*)debug;

@end

@interface LMWCompanionBridge : NSObject


/**
 The info of now playing on the phone. If nothing is playing, nowPlayingTrack will be nil.
 */
@property LMWNowPlayingInfo *nowPlayingInfo;


/**
 The companion bridge which is shared across the watch.

 @return The companion bridge.
 */
+ (LMWCompanionBridge*)sharedCompanionBridge;

/**
 Adds a delegate to the list of delegates.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMWCompanionBridgeDelegate>)delegate;

/**
 Removes a delegate to the list of delegates.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMWCompanionBridgeDelegate>)delegate;

/**
 Sends a ping to the companion asking for the latest and greatest now playing info.
 */
- (void)askCompanionForNowPlayingTrackInfo;

/**
 Sends a control message to the companion for doing actions such as changing the song. Automatically handles resending in the case of disconnection.

 @param key The communication key to send to the phone.
 */
- (void)sendMusicControlMessageToPhoneWithKey:(NSString*)key;

/**
 Sets the now playing track based off the next up/now playing queue, from an index provided by a track displayed in the up next section. Confusing, eh?

 @param indexOfNextUpTrackSelected The index of the track in the now playing queue, from up next.
 */
- (void)setUpNextTrack:(NSInteger)indexOfNextUpTrackSelected;

/**
 Requests a list of tracks from the phone based off a browsing entry and music type. If beginning to browse, set entryInfo to nil.

 @param selectedIndexes The indexes that have been selected by the user. First page should have an index of -1.
 @param pageIndexes The indexes of the pages of each level of browsing.
 @param musicTypes The tree of music types associated with the current browsing session.
 @param persistentIDs The tree of persistent IDs associated with the current browsing session.
 @param replyHandler The reply handler, which will receive the results.
 @param errorHandler The error handler in case something goes wrong.
 */
- (void)requestTracksWithSelectedIndexes:(NSArray<NSNumber*>*)selectedIndexes
						 withPageIndexes:(NSArray<NSNumber*>*)pageIndexes
						   forMusicTypes:(NSArray<NSNumber*>*)musicTypes
					   withPersistentIDs:(NSArray<NSNumber*>*)persistentIDs
							replyHandler:(nullable void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
							errorHandler:(nullable void (^)(NSError *error))errorHandler;

/**
 Sets the current playback time by sending a message with the set time to the phone.

 @param currentPlaybackTime The current playback time to set.
 */
- (void)setCurrentPlaybackTime:(NSInteger)currentPlaybackTime;

@end
