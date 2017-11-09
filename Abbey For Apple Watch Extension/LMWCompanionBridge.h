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

//Invert the play/pause status from whatever it is now.
#define LMAppleWatchControlKeyPlayPause @"LMAppleWatchControlKeyPlayPause"
//Skip to the next track in the queue.
#define LMAppleWatchControlKeyNextTrack @"LMAppleWatchControlKeyNextTrack"
//Go back to the previous track in the queue.
#define LMAppleWatchControlKeyPreviousTrack @"LMAppleWatchControlKeyPreviousTrack"
//Invert the favourite status of this track.
#define LMAppleWatchControlKeyFavouriteUnfavourite @"LMAppleWatchControlKeyFavouriteUnfavourite"
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
 Sets the current playback time by sending a message with the set time to the phone.

 @param currentPlaybackTime The current playback time to set.
 */
- (void)setCurrentPlaybackTime:(NSInteger)currentPlaybackTime;

@end
