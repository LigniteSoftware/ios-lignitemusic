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
 The queue completely changed (instead of a small update being made like a track being added or removed).
 */
- (void)queueCompletelyChanged;

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
 If the full queue isn't available, this returns the systemQueueCount. Otherwise, it returns the completeQueueCount.
 */
@property (readonly) NSInteger count;

/**
 The number of items in the system queue.
 */
@property (readonly) NSInteger systemQueueCount;

/**
 The number of items in the complete queue, which is the queue that Lignite Music has been able to construct (this count may not align with the systemQueueCount).
 */
@property (readonly) NSInteger completeQueueCount;

/**
 The index of the now playing track in the complete queue.
 */
@property (readonly) NSInteger indexOfNowPlayingTrack;

/**
 Whether or not the queue requires a system reload. If YES, that means that although the queue has been set within Lignite Music, it hasn't been set within the system music player. This is due to Apple's annoying bug where one cannot change the currently playing queue without completely halting the music that's playing first. The hope with this is to reset the queue in between tracks so that the user doesn't notice.
 */
@property BOOL requiresSystemReload;

/**
 The playback time that needs to be restored from the system restore.
 */
@property CGFloat systemRestorePlaybackTime;


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

 @param oldIndexPath The old index path of the track, relative to the way that LMQueueView is structured.
 @param newIndexPath The new index path of the track, relative to the way that LMQueueView is structured.
 */
- (void)moveTrackFromIndexPath:(NSIndexPath * _Nonnull)oldIndexPath toIndexPath:(NSIndexPath * _Nonnull)newIndexPath;

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
 Sets the currently playing queue and notifies delegates of a change to the queue.

 @param newQueue The new queue to set.
 @param autoPlay Whether or not to begin playing the queue from the first track in the collection.
 */
- (void)setQueue:(LMMusicTrackCollection * _Nonnull)newQueue autoPlay:(BOOL)autoPlay;

/**
 Sets the currently playing queue and notifies delegates of a change to the queue. Does not autoplay.

 @param newQueue The new queue to set.
 */
- (void)setQueue:(LMMusicTrackCollection * _Nonnull)newQueue;

/**
 Performs a system reload of the currently playing queue, based on the complete queue, set with a specific track.

 @param newTrack The new track to set (track should be within the complete queue).
 */
- (void)systemReloadWithTrack:(LMMusicTrack * _Nonnull)newTrack;

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
 Prepare the queue for the app being backgrounded by the system.8
 */
- (void)prepareForBackgrounding;

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
