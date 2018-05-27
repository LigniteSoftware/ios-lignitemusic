//
//  LMMusicQueue.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMusicPlayer.h"

@protocol LMMusicQueueDelegate <NSObject>
@optional

/**
 The music queue began (went from not playing anything to playing a queue).
 */
- (void)queueBegan;

/**
 The music queue ended (went from playing a queue to not playing anything).
 */
- (void)queueEnded;

/**
 A track was added to the queue.
 
 @param trackAdded The track that was added.
 */
- (void)trackAddedToQueue:(LMMusicTrack * _Nonnull)trackAdded;

/**
 A track was removed from the queue.
 
 @param trackAdded The track that was removed.
 */
- (void)trackRemovedFromQueue:(LMMusicTrack * _Nonnull)trackRemoved;

/**
 A track was moved around the queue (user adjusted).
 
 @param trackMoved The track that was moved.
 */
- (void)trackMovedInQueue:(LMMusicTrack * _Nonnull)trackMoved;

@end

@interface LMMusicQueue : NSObject

/**
 The total amount of tracks in the queue. This is the count of previously played tracks, the current track, and the next up tracks altogether.
 */
@property (readonly) NSInteger count;

/**
 Relative to the music player's now playing track, these are the tracks prior to that track, as provided by the system API.
 
 @return The previous tracks relative to the currently playing track.
 */
@property (nonnull, readonly) NSArray<LMMusicTrack*> *previousTracks;

/**
 Relative to the music player's now playing track, these are the tracks after that track, as provided by the system API.
 
 @return The "next up" tracks relative to the currently playing track.
 */
@property (nonnull, readonly) NSArray<LMMusicTrack*> *nextTracks;


/**
 Rebuilds the queue from the system API.
 */
- (void)rebuild;

/**
 Adds a delegate.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMMusicQueueDelegate>)delegate;

/**
 Removes a delegate.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMMusicQueueDelegate>)delegate;

/**
 The shared music queue.

 @return The music queue that is shared across the app.
 */
+ (LMMusicQueue*)sharedMusicQueue;

@end
