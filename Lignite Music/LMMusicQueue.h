//
//  LMMusicQueue.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPMediaItem+LigniteImages.h"
#import "MPMediaItemCollection+LigniteInfo.h"

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
 The number of items in the system queue.
 */
@property (readonly) NSInteger numberOfItemsInSystemQueue;

/**
 The index of the now playing track in the complete queue.
 */
@property (readonly) NSInteger indexOfNowPlayingTrack;


/**
 Rebuilds the queue from the system API.
 */
- (void)rebuild;

/**
 Gets the index of a track in the complete queue based off of the index path.

 @param trackIndexPath The track index path based off of the LMQueueView structure of displaying previous and next tracks.
 @return The index of the track relative to the complete queue.
 */
- (NSInteger)indexOfTrackInCompleteQueueFromIndexPath:(NSIndexPath * _Nonnull)trackIndexPath;

/**
 Move a track in the queue from its old index to a new index.

 @param oldIndex The old index of the track, relative to the whole queue (not just previously played or up next).
 @param newIndex The new index of the track, relative to the whole queue (not just previously played or up next).
 */
- (void)moveTrackFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;

/**
 Removes a track from the queue. 

 @param trackIndex The index of the track to remove from the queue, relative to the complete queue. If this track isn't in the queue, it'll ignore the request to remove.
 */
- (void)removeTrackAtIndex:(NSInteger)trackIndex;

/**
 Adds a music track to the queue (it will play next).

 @param trackToAdd The track to add to the queue.
 */
- (void)addTrackToQueue:(LMMusicTrack * _Nonnull)trackToAdd;

/**
 Gets the track that is going to play after the currently playing track (relative to the complete queue).

 @return The next track that's going to play.
 */
- (LMMusicTrack * _Nullable)nextTrack;

/**
 Gets the track that played before the currently playing track (relative to the complete queue).
 
 @return The previous track that's going to play.
 */
- (LMMusicTrack * _Nullable)previousTrack;

/**
 Gets the index of the next track relative to the complete queue.

 @return The index of the next track in the complete queue.
 */
- (NSInteger)indexOfNextTrack;

/**
 Gets the index of the previous track relative to the complete queue.
 
 @return The index of the previous track in the complete queue.
 */
- (NSInteger)indexOfPreviousTrack;

/**
 Adds a delegate.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMMusicQueueDelegate> _Nonnull)delegate;

/**
 Removes a delegate.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMMusicQueueDelegate> _Nonnull)delegate;

/**
 The shared music queue.

 @return The music queue that is shared across the app.
 */
+ (LMMusicQueue * _Nonnull)sharedMusicQueue;

@end
