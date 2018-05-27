//
//  MPMediaItem+LigniteImages.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

//#define SPOTIFY

#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaItem (LigniteImages)

typedef MPMediaItem LMMusicTrack;

typedef MPMediaEntityPersistentID LMMusicTrackPersistentID;

/**
 Gets the album art associated with with LMMusicTrack. If the album art has not yet been created for this track, it will create it. If there is no album art, it'll return the Lignite Music logo. It is recommended that this not be called in the main thread.
 
 @return The album art.
 */
- (nonnull UIImage*)albumArt;

/**
 Gets the album art for a track if it exists in either the track itself or in image cache. Otherwise it returns nil.
 
 @return The album art, if it exists.
 */
- (nullable UIImage*)uncorrectedAlbumArt;

/**
 Gets the artist image associated with this track. The artist image is stored within the LMImageManager cache and is nil if the artist image has not been downloaded or could not be found.
 
 @return The artist image.
 */
- (nonnull UIImage*)artistImage;

/**
 Gets the uncorrected artist image, meaning that if the artist image doesn't exist, nil is returned. Use the standard -artistImage if you want to always have an image returned to you.

 @return The artist image if it exists, nil if not.
 */
- (nullable UIImage*)uncorrectedArtistImage;

/**
 Whether or not the track is a favourite of the user.

 @return YES or NO whether the user has favourited the track.
 */
- (BOOL)isFavourite;

@end
