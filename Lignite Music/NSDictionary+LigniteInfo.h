//
//  NSDictionary+LigniteInfo.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NSDictionary+LigniteImages.h"

@interface NSDictionary (LigniteInfo)

typedef NSDictionary LMMusicTrackCollection;

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

@property (readonly) NSArray *items;

@property (readonly) LMMusicTrack *representativeItem;

@end

