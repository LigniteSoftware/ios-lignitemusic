//
//  LMWMusicTrackInfo.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface LMWMusicTrackInfo : NSObject

/**
 The standard for persistent IDs
 */
typedef uint64_t MPMediaEntityPersistentID;

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
 The album art of the music track. If no album art exists, it'll load the no cover art icon.
 */
@property UIImage *albumArt;

/**
 Album art which is not modified by any internal rendering/managment. If no album art exists, Lignite Music's logo will be returned.
 */
@property (readonly) UIImage *albumArtNotCropped;

/**
 The title of the music track.
 */
@property NSString *title;

/**
 The subtitle of the music track, determined by the companion.
 */
@property NSString *subtitle;

/**
 Whether or not the track is a favourite of the user.
 */
@property BOOL isFavourite;

/**
 The total playback length of the track. ie. 120 is 2 minutes duration.
 */
@property NSInteger playbackDuration;

/**
 The persistent ID of the music track.
 */
@property MPMediaEntityPersistentID persistentID;

/**
 The persistent ID of the album associated with this track.
 */
@property MPMediaEntityPersistentID albumPersistentID;

/**
 The index of this track in the collection its associated with, if any. -1 if not associated with a collection.
 */
@property NSInteger indexInCollection;

@end
