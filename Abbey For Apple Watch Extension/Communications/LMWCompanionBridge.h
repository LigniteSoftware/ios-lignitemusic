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

//Whether or not the now playing track is playing. BOOL as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyIsPlaying @"LMAppleWatchNowPlayingInfoKeyIsPlaying"
//The current repeat mode. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyRepeatMode @"LMAppleWatchNowPlayingInfoKeyRepeatMode"
//The current shuffle mode. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyShuffleMode @"LMAppleWatchNowPlayingInfoKeyShuffleMode"
//The track's current playback time. NSInteger as NSNumber.
#define LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime @"LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime"
//The phone's volume, from 0.0 to 1.0.
#define LMAppleWatchNowPlayingInfoKeyVolume @"LMAppleWatchNowPlayingInfoKeyVolume"

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
//The user wants to shuffle all tracks within the currently viewable browse level.
#define LMAppleWatchCommunicationKeyBrowsingShuffleAll @"LMAppleWatchCommunicationKeyBrowsingShuffleAll"
//The user wants to play a certain track from a collection.
#define LMAppleWatchCommunicationKeyBrowsingPlayIndividualTrack @"LMAppleWatchCommunicationKeyBrowsingPlayIndividualTrack"
//A property of the track changed on the phone. Message should contain a key of LMAppleWatchCommunicationKeyNowPlayingTrackUpdate with a value of the LMAppleWatchMusicTrackInfoKey that was changed, along with that associated LMAppleWatchMusicTrackInfoKey as a key with a value of the new property.
#define LMAppleWatchCommunicationKeyNowPlayingTrackUpdate @"LMAppleWatchCommunicationKeyNowPlayingTrackUpdate"
//A property of the now playing info changed on the phone. Message should contain a key of LMAppleWatchCommunicationKeyNowPlayingInfoUpdate with a value of the LMAppleWatchNowPlayingInfoKey that was changed, along with that associated LMAppleWatchNowPlayingInfoKey as a key with a value of the new property.
#define LMAppleWatchCommunicationKeyNowPlayingInfoUpdate @"LMAppleWatchCommunicationKeyNowPlayingInfoUpdate"

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
//Volume up.
#define LMAppleWatchControlKeyVolumeUp @"LMAppleWatchControlKeyVolumeUp"
//Volume down.
#define LMAppleWatchControlKeyVolumeDown @"LMAppleWatchControlKeyVolumeDown"

//A BOOL of whether or not the command sent was a success.
#define LMAppleWatchCommandSuccess @"LMAppleWatchCommandSuccess"

@protocol LMWCompanionBridgeDelegate<NSObject>
@optional

/**
 The music track changed, as per the phone's request. Delegate should update UI accordingly.

 @param musicTrackInfo The new music track.
 */
- (void)musicTrackDidChange:(LMWMusicTrackInfo* _Nullable)musicTrackInfo;

/**
 The album art changed for the now playing track.

 @param albumArt The new album art.
 */
- (void)albumArtDidChange:(UIImage* _Nullable)albumArt;

/**
 The now playing info changed. Delegate should update UI accordingly.

 @param nowPlayingInfo The new now playing info.
 */
- (void)nowPlayingInfoDidChange:(LMWNowPlayingInfo* _Nonnull)nowPlayingInfo;

/**
 The now playing queue up next changed.

 @param upNextTracks The tracks which are up next.
 */
- (void)nowPlayingUpNextDidChange:(NSArray<LMWMusicTrackInfo*>* _Nonnull)upNextTracks;

/**
 An update was made to the now playing track for a certain LMAppleWatchMusicTrackInfoKey.

 @param nowPlayingTrack The now playing track that was updated.
 @param key The key.
 */
- (void)nowPlayingTrackUpdate:(LMWMusicTrackInfo* _Nonnull)nowPlayingTrack forKey:(NSString* _Nonnull)key;

/**
 An update was made to the now playing info for a certain LMAppleWatchNowPlayingInfoKey.
 
 @param nowPlayingInfo The now playing info that was updated.
 @param key The key.
 */
- (void)nowPlayingInfoUpdate:(LMWNowPlayingInfo* _Nonnull)nowPlayingInfo forKey:(NSString* _Nonnull)key;

/**
 The companion's connection status changed. If connected, messaging is possible.

 @param connected Whether or not the companion is connected.
 */
- (void)companionConnectionStatusChanged:(BOOL)connected;

/**
 Asks the delegate to display a debug message, if possible.

 @param debug The debug message to display.
 */
- (void)companionDebug:(NSString* _Nullable)debug;

@end

@interface LMWCompanionBridge : NSObject


/**
 The info of now playing on the phone. If nothing is playing, nowPlayingTrack will be nil.
 */
@property LMWNowPlayingInfo * _Nonnull nowPlayingInfo;


/**
 The companion bridge which is shared across the watch.

 @return The companion bridge.
 */
+ (LMWCompanionBridge* _Nonnull)sharedCompanionBridge;

/**
 Whether or not the watch is connected to the phone and the phone is reachable for live messaging.

 @return YES if the phone is connected and reachable, NO otherwise.
 */
- (BOOL)connected;

/**
 One of the potential reasons for watch not connecting could be that the iPhone was just rebooted, and the iOS device must be unlocked first.

 @return Whether or not the iOS device needs to be unlocked to continue.
 */
- (BOOL)requiresUnlock;

/**
 Adds a delegate to the list of delegates.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMWCompanionBridgeDelegate> _Nonnull)delegate;

/**
 Removes a delegate to the list of delegates.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id <LMWCompanionBridgeDelegate> _Nonnull)delegate;

/**
 Sends a ping to the companion asking for the latest and greatest now playing info.
 */
- (void)askCompanionForNowPlayingTrackInfo;

/**
 Sends a control message to the companion for doing actions such as changing the song. Automatically handles resending in the case of disconnection. Both handlers are always called on the main queue for thread safety.

 @param key The communication key to send to the phone.
 @param successHandler The success handler for when the command was sent and the phone has processed it. The response dictionary is the reply dictionary from the phone.
 @param errorHandler The error handler for when the command could not reach the phone (code 503) or another error occurred.
 */
- (void)sendMusicControlMessageToPhoneWithKey:(NSString* _Nonnull)key
							   successHandler:(nullable void (^)(NSDictionary * _Nonnull response))successHandler
								 errorHandler:(nullable void (^)(NSError * _Nonnull error))errorHandler;

/**
 Sets the current playback time by sending a message with the set time to the phone.
 
 @param currentPlaybackTime The current playback time to set.
 @param successHandler The handler for when the command was sent successfully and the phone replied.
 @param errorHandler The handler for when the playback time change message could not be sent.
 */
- (void)setCurrentPlaybackTime:(NSInteger)currentPlaybackTime
				successHandler:(nullable void (^)(NSDictionary * _Nonnull response))successHandler
				  errorHandler:(nullable void (^)(NSError * _Nonnull error))errorHandler;

/**
 Sets the now playing track based off the next up/now playing queue, from an index provided by a track displayed in the up next section. Confusing, eh?

 @param indexOfNextUpTrackSelected The index of the track in the now playing queue, from up next.
 */
- (void)setUpNextTrack:(NSInteger)indexOfNextUpTrackSelected;

/**
 Requests a list of tracks from the phone based on current browsing info.

 @param selectedIndexes The indexes that have been selected by the user. First page should have an index of -1.
 @param pageIndexes The indexes of the pages of each level of browsing.
 @param musicTypes The tree of music types associated with the current browsing session.
 @param persistentIDs The tree of persistent IDs associated with the current browsing session.
 @param replyHandler The reply handler, which will receive the results.
 @param errorHandler The error handler in case something goes wrong.
 */
- (void)requestTracksWithSelectedIndexes:(NSArray<NSNumber*>* _Nonnull)selectedIndexes
						 withPageIndexes:(NSArray<NSNumber*>* _Nonnull)pageIndexes
						   forMusicTypes:(NSArray<NSNumber*>* _Nonnull)musicTypes
					   withPersistentIDs:(NSArray<NSNumber*>* _Nonnull)persistentIDs
							replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> * _Nonnull replyMessage))replyHandler
							errorHandler:(nonnull void (^)(NSError * _Nonnull error))errorHandler;

/**
 Shuffles a list of tracks from the phone based on current browsing info.
 
 @param selectedIndexes The indexes that have been selected by the user. First page should have an index of -1.
 @param pageIndexes The indexes of the pages of each level of browsing.
 @param musicTypes The tree of music types associated with the current browsing session.
 @param persistentIDs The tree of persistent IDs associated with the current browsing session.
 @param replyHandler The reply handler, which will receive the results.
 @param errorHandler The error handler in case something goes wrong.
 */
- (void)shuffleTracksWithSelectedIndexes:(NSArray<NSNumber*>* _Nonnull)selectedIndexes
						 withPageIndexes:(NSArray<NSNumber*>* _Nonnull)pageIndexes
						   forMusicTypes:(NSArray<NSNumber*>* _Nonnull)musicTypes
					   withPersistentIDs:(NSArray<NSNumber*>* _Nonnull)persistentIDs
							replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> * _Nonnull replyMessage))replyHandler
							errorHandler:(nonnull void (^)(NSError * _Nonnull error))errorHandler;

/**
 Plays a specific track from a list of tracks from the phone based on current browsing info.
 
 @param selectedIndexes The indexes that have been selected by the user. First page should have an index of -1.
 @param pageIndexes The indexes of the pages of each level of browsing.
 @param musicTypes The tree of music types associated with the current browsing session.
 @param persistentIDs The tree of persistent IDs associated with the current browsing session.
 @param replyHandler The reply handler, which will receive the results.
 @param errorHandler The error handler in case something goes wrong.
 */
- (void)playSpecificTrackWithSelectedIndexes:(NSArray<NSNumber*>* _Nonnull)selectedIndexes
							 withPageIndexes:(NSArray<NSNumber*>* _Nonnull)pageIndexes
							   forMusicTypes:(NSArray<NSNumber*>* _Nonnull)musicTypes
						   withPersistentIDs:(NSArray<NSNumber*>* _Nonnull)persistentIDs
								replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> * _Nonnull replyMessage))replyHandler
								errorHandler:(nonnull void (^)(NSError * _Nonnull error))errorHandler;

@end
