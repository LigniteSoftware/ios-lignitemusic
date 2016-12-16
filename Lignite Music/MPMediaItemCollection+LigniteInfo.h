//
//  MPMediaItemCollection+LigniteInfo.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaItemCollection (LigniteInfo)

typedef MPMediaItemCollection LMMusicTrackCollection;

/**
 The title of this collection, if it applies.
 
 @param musicType The type of music to get the title for.
 @return The title for a certain music type.
 */
- (NSString*)titleForMusicType:(uint8_t)musicType;

/**
 Whether or not this collection has various artists instead of a singluar artist.
 
 @return If YES, the representative item cannot be trusted for artist information.
 */
- (BOOL)variousArtists;

/**
 Whether or not this collection has various genres associated with it instead of
 a singluar genre.
 
 @return If YES, the representative item cannot be trusted for genre information.
 */
- (BOOL)variousGenres;

/**
 The number of albums in this collection.
 
 @return The number of albums in this collection.
 */
- (NSUInteger)numberOfAlbums;

@end
