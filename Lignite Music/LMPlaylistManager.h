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
 Returns the shared playlist manager.

 @return The playlist manager.
 */
+ (LMPlaylistManager*)sharedPlaylistManager;

/**
 The array of all of the user's current playlists.
 */
@property NSArray<LMPlaylist*>* playlists;

/**
 If YES, the user has seen and clicked "I understand" on a popup that states playlists are managed within the app & do not get exported to the default music app due to API limitations.
 */
@property BOOL userUnderstandsPlaylistManagement;

@end
