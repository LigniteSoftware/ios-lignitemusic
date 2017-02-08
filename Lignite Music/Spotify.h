//
//  Spotify.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpotifyAuthentication/SpotifyAuthentication.h>
#import <SpotifyMetadata/SpotifyMetadata.h>
#import <SpotifyAudioPlayback/SpotifyAudioPlayback.h>

/**
 The client ID of our Spotify application.
 */
#define SpotifyClientID @"d4059bd5066643ad8d9f4b6532f791e6"

/**
 The key for the session in user defaults.
 */
#define SpotifySessionUserDefaultsKey @"SpotifySession"

/**
 The callback URL for when Lignite Music is authenticated.
 */
#define SpotifyCallbackURL @"lignitemusicspotify://"

@interface Spotify : NSObject

+ (id)sharedInstance;

- (void)openLoginOnViewController:(UIViewController*)viewController;

- (void)sessionUpdated;

@end
