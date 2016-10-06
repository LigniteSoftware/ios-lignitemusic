//
//  LMMusicTrack.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/*
 LMMusicTrack is the global way of viewing data associated with a music track.
 
 Since Lignite Music supplies 3 different types of music player sources (system, Spotify, Apple Music), the application
 must have a global way of determining track data.
 */

@interface LMMusicTrack : NSObject

typedef uint64_t LMMusicTrackPersistentID;

/**
 The song's name/title.
 */
@property NSString *title;

/**
 The song's artist.
 */
@property NSString *artist;

/**
 The song's album name/title.
 */
@property NSString *albumTitle;

/**
 The song's genre. There is a chance that this will be nil.
 */
@property NSString *genre;

/**
 The duration of the song in seconds.
 */
@property NSTimeInterval playbackDuration;

/**
 The persistent IDs of the track.
 */
@property LMMusicTrackPersistentID persistentID;
@property LMMusicTrackPersistentID albumArtistPersistentID;
@property LMMusicTrackPersistentID albumPersistentID;
@property LMMusicTrackPersistentID artistPersistentID;
@property LMMusicTrackPersistentID composerPersistentID;
@property LMMusicTrackPersistentID genrePersistentID;

/**
 A reference to the source track which provided the LMMusicTrack with its data. 
 This changes depending on the type of instance that LMMusicPlayer is (ie. Spotify).
 */
@property id sourceTrack;


/**
 Initializes an LMMusicTrack with the contents of the associated MPMediaItem.

 @param item The item which will have its data injected into the LMMusicTrack.

 @return The created LMMusicTrack.
 */
- (instancetype)initWithMPMediaItem:(MPMediaItem*)item;

/**
 Gets the album art associated with with LMMusicTrack. If the album art has not yet been created for this track, it will create it. It is recommended that this not be called in the main thread.

 @return The album art.
 */
- (UIImage*)albumArt;

@end
