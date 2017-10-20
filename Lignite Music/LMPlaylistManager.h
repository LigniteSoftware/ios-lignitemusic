//
//  LMPlaylistManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMusicPlayer.h"

#define LMUserUnderstandsPlaylistManagementKey @"LMUserUnderstandsPlaylistManagementKey"

@interface LMPlaylistManager : NSObject

/**
 Launches the LMAlertView for getting the user's understanding about how playlists are handled within the app.

 @param view The view to launch the playlist management alert on.
 */
- (void)launchPlaylistManagementWarningOnView:(UIView*)view;


/**
 Returns the shared playlist manager.

 @return The playlist manager.
 */
+ (LMPlaylistManager*)sharedPlaylistManager;



/**
 If YES, the user has seen and clicked "I understand" on a popup that states playlists are managed within the app & do not get exported to the default music app due to API limitations.
 */
@property BOOL userUnderstandsPlaylistManagement;

@end