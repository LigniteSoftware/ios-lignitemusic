//
//  LMMusicTrackCollection.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMusicTrack.h"

@interface LMMusicTrackCollection : NSObject

/**
 The MPMusicTrack items which are in this collection.
 */
@property NSArray<LMMusicTrack *> *items;

/**
 A representative track of the tracks in this collection.
 */
@property LMMusicTrack *representativeItem;

/**
 The number of items in this collection.
 */
@property NSUInteger count;

/**
 The title of this collection, if it applies. Currently only for playlists.
 */
@property NSString *title;

/**
 Whether or not this collection has various artists instead of a singluar artist.
 If YES, the representative item cannot be trusted for artist information.
 */
@property BOOL variousArtists;

/**
 Whether or not this collection has various genres associated with it instead of 
 a singluar genre.
 If YES, the representative item cannot be trusted for genre information.
 */
@property BOOL variousGenres;

/**
 The source collection which the LMMusicTrackCollection is based off of.
 */
@property id sourceCollection;

/**
 The number of albums in this collection.
 */
@property (readonly) NSUInteger numberOfAlbums;

/**
 Creates an LMMusicTrackCollection based on the provided array of items. Determination
 of various artists and genres occurs within this function as well.

 @param items            The items to instantiate this LMMusicTrackCollection with.
 @param sourceCollection The source collection which this collection is based off of.

 @return The created LMMusicTrackCollection.
 */
- (instancetype)initWithItems:(NSArray<LMMusicTrack *> *)items basedOnSourceCollection:(id)sourceCollection;

@end
