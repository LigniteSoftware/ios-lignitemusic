//
//  LMAppleWatchBridge.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
//The user's selected theme colour.
#define LMAppleWatchNowPlayingInfoKeyTheme @"LMAppleWatchNowPlayingInfoKeyTheme"

//The key to be used as the key for defining which type of data is being transmitted.
#define LMAppleWatchCommunicationKey @"LMAppleWatchCommunicationKey"
//The now playing track is what's being transmitted.
#define LMAppleWatchCommunicationKeyNowPlayingTrack @"LMAppleWatchCommunicationKeyNowPlayingTrack"
//Nothing is playing.
#define LMAppleWatchCommunicationKeyNoTrackPlaying @"LMAppleWatchCommunicationKeyNoTrackPlaying"
//The now playing info is what's being transmitted.
#define LMAppleWatchCommunicationKeyNowPlayingInfo @"LMAppleWatchCommunicationKeyNowPlayingInfo"
//The next 5 items of the now playing queue
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

@interface LMAppleWatchBridge : NSObject

/**
 The type of info that the Apple Watch either wants or is being sent.

 - LMAppleWatchMusicInfoTypeAll: All of the possible data types.
 - LMAppleWatchMusicInfoTypeTrack: The track info (title, subtitle, and now playing time progress).
 - LMAppleWatchMusicInfoTypeAlbumArt: The album art of the currently playing track. 
 */
typedef NS_ENUM(NSInteger, LMAppleWatchMusicInfoType){
	LMAppleWatchMusicInfoTypeAll = 0,
	LMAppleWatchMusicInfoTypeTrack,
	LMAppleWatchMusicInfoTypeAlbumArt
};

/**
 Returns the single instance of the shared Apple Watch bridge.

 @return The Apple Watch bridge.
 */
+ (LMAppleWatchBridge*)sharedAppleWatchBridge;

/**
 Whether or not the watch is connected to the phone and the watchapp is reachable for live messaging.

 @return YES if watch is reachable, NO otherwise.
 */
- (BOOL)connected;

/**
 Attaches volume events to a certain view controller.

 @param viewController The view controller to attach volume events to.
 */
- (void)attachToViewController:(UIViewController*)viewController;

/**
 Tells the watch bridge to send the now playing track info to the watch to display on the main interface. This automatically handles whether or not the watch is connected and any errors associated with sending the data.
 */
- (void)sendNowPlayingTrackToWatch;

/**
 Tells the watch bridge to send the now playing info to the watch. Now playing info contains information on whether or not the music is playing, the playback time, etc. This automatically handles whether or not the watch is connected and any errors associated with sending the data.
 */
- (void)sendNowPlayingInfoToWatch;
- (void)sendNowPlayingTrackToWatch:(BOOL)overrideDoubleSending; //Same as above, but if overrideDoubleSending is set to YES, double sending prevention will be ignored.

/**
 Tells the watch bridge to send the "next up" tracks to the watch. Next up tracks are a small number of tracks which proceed the track currently playing. Next up is only sent if the watch is connected and there are items after the now playing track in queue.
 */
- (void)sendUpNextToWatch;

@end
