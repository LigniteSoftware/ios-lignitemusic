//
//  LMWCompanionBridge.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMWMusicTrackInfo.h"

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


//The key to be used as the key for defining which type of data is being transmitted.
#define LMAppleWatchCommunicationKey @"LMAppleWatchCommunicationKey"
//The now playing track is what's being transmitted.
#define LMAppleWatchCommunicationKeyNowPlayingTrack @"LMAppleWatchCommunicationKeyNowPlayingTrack"

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



- (void)companionDebug:(NSString*)debug;



@end

@interface LMWCompanionBridge : NSObject



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

@end