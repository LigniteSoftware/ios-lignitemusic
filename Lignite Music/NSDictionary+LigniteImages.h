//
//  NSDictionary+LigniteImages.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface NSDictionary (LigniteImages)

typedef NSDictionary LMMusicTrack;

typedef MPMediaEntityPersistentID LMMusicTrackPersistentID;

/**
 Gets the album art associated with with LMMusicTrack. If the album art has not yet been created for this track, it will create it. It is recommended that this not be called in the main thread.
 
 @return The album art.
 */
- (UIImage*)albumArt;

/**
 Gets the album art for a track if it exists in either the track itself or in image cache. Otherwise it returns nil.
 
 @return The album art, if it exists.
 */
- (UIImage*)uncorrectedAlbumArt;

/**
 Gets the artist image associated with this track. The artist image is stored within the LMImageManager cache and is nil if the artist image has not been downloaded or could not be found.
 
 @return The artist image.
 */
- (UIImage*)artistImage;

@property (readonly) LMMusicTrackPersistentID persistentID;
@property (readonly) LMMusicTrackPersistentID albumPersistentID;
@property (readonly) LMMusicTrackPersistentID artistPersistentID;
@property (readonly) LMMusicTrackPersistentID composerPersistentID;
@property (readonly) LMMusicTrackPersistentID genrePersistentID;

@property (readonly) NSTimeInterval playbackDuration;

@property (readonly) NSString *title;
@property (readonly) NSString *artist;
@property (readonly) NSString *albumTitle;
@property (readonly) NSString *composer;
@property (readonly) NSString *genre;

@end
