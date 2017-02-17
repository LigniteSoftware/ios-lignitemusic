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
#import "SpotifyInfo.h"
#import "NSDictionary+LigniteImages.h"
#import "NSDictionary+LigniteInfo.h"
#import "LMSpotifyLibrary.h"

#define SPOTIFY

@protocol SpotifyDelegate <NSObject>
@optional

/**
 The Spotify session's status updated.

 @param isValid Whether or not the session is valid.
 */
- (void)sessionUpdated:(BOOL)isValid;

@end

@interface Spotify : NSObject

/**
 The shared instance of the Spotify object.

 @return The Spotify object.
 */
+ (instancetype)sharedInstance;

/**
 Adds a delegate.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<SpotifyDelegate>)delegate;

/**
 Removes a delegate.

 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<SpotifyDelegate>)delegate;

- (void)openLoginOnViewController:(UIViewController*)viewController;

- (void)sessionUpdated;

@end
