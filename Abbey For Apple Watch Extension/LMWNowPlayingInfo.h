//
//  LMWNowPlayingInfo.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMWMusicTrackInfo.h"

@interface LMWNowPlayingInfo : NSObject


/**
 LMMusicRepeatMode is the repeat mode of the music.
 */
typedef NS_ENUM(NSInteger, LMMusicRepeatMode) {
	LMMusicRepeatModeDefault = 0, //The user's default setting. Bullshit value, never use this.
	LMMusicRepeatModeNone, //Do not repeat.
	LMMusicRepeatModeAll, //Repeat all of the tracks in the current queue.
	LMMusicRepeatModeOne //Repeat this one track.
};

/**
 LMMusicRepeatMode is the repeat mode of the music.
 */
typedef NS_ENUM(NSInteger, LMMusicShuffleMode) {
	LMMusicShuffleModeOff = 0, //Do not shuffle.
	LMMusicShuffleModeOn, //Shuffle.
};


/**
 Whether or not music is currently playing.
 */
@property BOOL playing;

/**
 The duration of the now playing song in seconds.
 */
@property NSInteger playbackDuration;

/**
 The current point in time that the playback is at.
 */
@property NSInteger currentPlaybackTime;

/**
 The current repeat mode.
 */
@property LMMusicRepeatMode repeatMode;

/**
 The current shuffle mode.
 */
@property LMMusicShuffleMode shuffleMode;

/**
 The now playing track.
 */
@property LMWMusicTrackInfo *nowPlayingTrack;

@end
