//
//  LMPlaylist.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

#define LMEnhancedPlaylistPersistentIDsKey @"persistentIDs"
#define LMEnhancedPlaylistMusicTypesKey @"musicTypes"

#define LMEnhancedPlaylistWantToHearKey @"wantToHear"
#define LMEnhancedPlaylistDontWantToHearKey @"dontWantToHear"

@interface LMPlaylist : NSObject

/**
 The title of the playlist.
 */
@property NSString *title;

/**
 The image of the playlist, set by the user. If the user set no photo, this will be nil.
 */
@property UIImage *image;

/**
 Whether or not the playlist is enhanced.
 */
@property BOOL enhanced;

/**
 Whether or not to shuffle all in an enhanced playlist. If NO, the playlist will be built in order of the conditions the user set.
 */
@property BOOL enhancedShuffleAll;

/**
 The conditions dictionary for the enhanced playlist.
 */
@property NSDictionary *enhancedConditionsDictionary;


/**
 The music types of the want to hear section, parsed directly from the dictionary if the playlist is enhanced.
 */
@property (readonly) NSArray<NSNumber*> *wantToHearMusicTypes;

/**
 The persistent IDs of the want to hear section, parsed directly from the dictionary if the playlist is enhanced.
 */
@property (readonly) NSArray<NSNumber*> *wantToHearPersistentIDs;

/**
 The track collections of the want to hear conditions parsed directly from the dictionary.
 */
@property (readonly) NSArray<LMMusicTrackCollection*> *wantToHearTrackCollections;

/**
 The music types of the want to hear section, parsed directly from the dictionary if the playlist is enhanced.
 */
@property (readonly) NSArray<NSNumber*> *dontWantToHearMusicTypes;

/**
 The persistent IDs of the want to hear section, parsed directly from the dictionary if the playlist is enhanced.
 */
@property (readonly) NSArray<NSNumber*> *dontWantToHearPersistentIDs;

/**
 The track collections of the want to hear conditions parsed directly from the dictionary.
 */
@property (readonly) NSArray<LMMusicTrackCollection*> *dontWantToHearTrackCollections;


/**
 The collection of tracks associated with this playlist.
 */
@property LMMusicTrackCollection *trackCollection;

/**
 The persistent ID for the Lignite playlist, which has nothing to do with the system.
 */
@property MPMediaEntityPersistentID persistentID;

/**
 The persistent ID of the playlist from before it was ported to Lignite Music. Will equal 0 if it was not ported and was user created.
 */
@property MPMediaEntityPersistentID systemPersistentID;

/**
 If the user wants to edit a playlist, they must first accept an agreement of understanding that they won't be able to sync their playlist with iTunes or any other outside source. This variable will be YES if this playlist is a system playlist (systemPersistentID > 0) and the user understands & accepts that they want to convert this system playlist into a Lignite playlist. If this is done, the playlist will no longer be syncable with iTunes or external sources.
 */
@property BOOL userPortedToLignitePlaylist;

/**
 Whether or not the system playlist checker has verified that this is a system playlist. If NO, this playlist was deleted from the user's library through iTunes or Apple Music and should be scheduled for deletion.
 */
@property BOOL verifiedStillSystemPlaylist;

/**
 Regenerates the playlist, if enhanced, based on the conditions provided.
 */
- (void)regenerateEnhancedPlaylist;

/**
 Gets a dictionary representation of the playlist.

 @return The dictionary representation of tracks within the playlist.
 */
- (NSDictionary*)dictionaryRepresentation;

@end
