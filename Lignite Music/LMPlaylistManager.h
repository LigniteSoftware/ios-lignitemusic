//
//  LMPlaylistManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMusicPlayer.h"
#import "LMPlaylist.h"

#define LMUserUnderstandsPlaylistManagementKey @"LMUserUnderstandsPlaylistManagementKey"
#define LMPlaylistManagerImageCacheNamespaceKey @"LMPlaylistManagerImageCacheNamespaceKey"

@interface LMPlaylistManager : NSObject

/**
 Launches the LMAlertView for getting the user's understanding about how playlists are handled within the app.

 @param view The view to launch the playlist management alert on.
 @param completionHandler The completion handler which will be called when the user taps "I understand"
 */
- (void)launchPlaylistManagementWarningOnView:(UIView*)view withCompletionHandler:(void(^)(void))completionHandler;

/**
 Checks whether or not there are system playlists that need converting to the LMPlaylist format. If there are, it automatically converts them and includes them in the array stack.
 */
- (void)internalizeSystemPlaylists;

/**
 Reloads all the playlist's contents.
 */
- (void)reloadPlaylists;

/**
 Returns the shared playlist manager.

 @return The playlist manager.
 */
+ (LMPlaylistManager*)sharedPlaylistManager;

/**
 Saves a playlist to storage.

 @param playlist The playlist to save.
 */
- (void)savePlaylist:(LMPlaylist*)playlist;

/**
 Deletes a playlist from the device. If it is a system playlist, it prevents it from reentering the user's Lignite playlists.

 @param playlist The playlist to delete.
 */
- (void)deletePlaylist:(LMPlaylist*)playlist;

/**
 Gets a playlist based off it's Lignite persistent ID (NOT the persistent ID that the system originally gave it).

 @param persistentID The Lignite persistent ID of the playlist to fetch.
 @return The playlist, nil if it couldn't be found.
 */
- (LMPlaylist*)playlistForPersistentID:(long long)persistentID;

/**
 Returns a playlist's dictionary based off its songs.

 @param playlist The playlist to get the dictionary for.
 @return The dictionary.
 */
- (NSDictionary*)playlistDictionaryForPlaylist:(LMPlaylist*)playlist;

/**
 Converts a playlist dictionary into an actual playlist.

 @param playlistDictionary The playlist dictionary to convert.
 @return The playlist, prebuilt.
 */
- (LMPlaylist*)playlistForPlaylistDictionary:(NSDictionary*)playlistDictionary;

/**
 The array of all of the user's current playlists.
 */
@property NSArray<LMPlaylist*>* playlists;

/**
 The track collections from the playlists.
 */
@property (readonly) NSArray<LMMusicTrackCollection*>* playlistTrackCollections;

/**
 If YES, the user has seen and clicked "I understand" on a popup that states playlists are managed within the app & do not get exported to the default music app due to API limitations.
 */
@property BOOL userUnderstandsPlaylistManagement;

@end
