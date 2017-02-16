//
//  LMSpotifyLibrary.h
//  Lignite Music
//
//  Created by Edwin Finch on 2/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMSpotifyLibrary : NSObject

/**
 The shared Spotify library, single instance.

 @return The library.
 */
+ (instancetype)sharedLibrary;

/**
 Build the user's Spotify library database.
 */
- (void)buildDatabase;

@end
