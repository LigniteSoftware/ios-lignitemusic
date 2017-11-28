//
//  LMAppleWatchBridge.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

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
//The next 5 items of the now playing queue
#define LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue @"LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue"

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

- (void)test;

/**
 Returns the single instance of the shared Apple Watch bridge.

 @return The Apple Watch bridge.
 */
+ (LMAppleWatchBridge*)sharedAppleWatchBridge;

/**
 Tells the watch bridge to send the now playing track info to the watch to display on the main interface. This automatically handles whether or not the watch is connected and any errors associated with sending the data.
 */
- (void)sendNowPlayingTrackToWatch;

/**
 Tells the watch bridge to send the now playing info to the watch. Now playing info contains information on whether or not the music is playing, the playback time, etc. This automatically handles whether or not the watch is connected and any errors associated with sending the data.
 */
- (void)sendNowPlayingInfoToWatch;

/**
 Tells the watch bridge to send the "next up" tracks to the watch. Next up tracks are a small number of tracks which proceed the track currently playing. Next up is only sent if the watch is connected and there are items after the now playing track in queue.
 */
- (void)sendUpNextToWatch;

@end
