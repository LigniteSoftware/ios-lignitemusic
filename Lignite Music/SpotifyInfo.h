//
//  SpotifyInfo.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#ifndef SpotifyInfo_h
#define SpotifyInfo_h

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

/**
 The token swap service endpoint for logging in.
 */
#define SpotifyTokenSwapServiceURL @"https://api.lignite.me:2006/swap"

/**
 The token refresh service endpoint for maintaining a login.
 */
#define SpotifyTokenRefreshServiceURL @"https://api.lignite.me:2006/refresh"

#endif /* SpotifyInfo_h */