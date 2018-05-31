//
//  LMMusicQueue.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NSTimer+Blocks.h"
#import "LMMusicPlayer.h"
#import "LMMusicQueue.h"

@interface LMMusicQueue()

/**
 The queue's delegates.
 */
@property NSMutableArray<id<LMMusicQueueDelegate>> *delegates;

/**
 The complete queue, as provided by the system.
 */
@property NSMutableArray<LMMusicTrack*> *completeQueue;

/**
 Whether or not the full system queue is available to us. If YES, no tracks provided by the system were nil.
 */
@property BOOL fullQueueAvailable;

/**
 The adjusted index of the now playing track, only used when fullQueueAvailable is NO.
 */
@property NSInteger adjustedIndexOfNowPlayingTrack;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The complete queue in the form of a track collection.
 */
@property (readonly) LMMusicTrackCollection *completeQueueTrackCollection;

@end

@implementation LMMusicQueue

@synthesize nextTracks = _nextTracks;
@synthesize previousTracks = _previousTracks;
@synthesize count = _count;
@synthesize numberOfItemsInSystemQueue = _numberOfItemsInSystemQueue;
@synthesize indexOfNowPlayingTrack = _indexOfNowPlayingTrack;
@synthesize completeQueueTrackCollection = _completeQueueTrackCollection;

- (LMMusicTrackCollection*)completeQueueTrackCollection {
	return [LMMusicTrackCollection collectionWithItems:self.completeQueue];
}

- (void)prepareForBackgrounding {
	if(self.requiresSystemReload){
		self.requiresSystemReload = NO;
		
		CGFloat currentPlaybackTime = self.musicPlayer.currentPlaybackTime;
		
		NSLog(@"Preparing for the background by performing a system reload of the queue.");
		
		[self.musicPlayer.systemMusicPlayer setQueueWithItemCollection:self.completeQueueTrackCollection];
		[self.musicPlayer.systemMusicPlayer setNowPlayingItem:self.musicPlayer.nowPlayingTrack];
		[self.musicPlayer.systemMusicPlayer play];
		
		self.systemRestorePlaybackTime = currentPlaybackTime;
		
//		self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid = playbackTime;
		
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.05 block:^{
			[self.musicPlayer setCurrentPlaybackTime:currentPlaybackTime];
			NSLog(@"Set playback time to %f", currentPlaybackTime);
		} repeats:NO];
		
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		[[NSRunLoop currentRunLoop] run];
	}
}

- (NSInteger)numberOfItemsInSystemQueue {
	return [[MPMusicPlayerController systemMusicPlayer] performSelector:@selector(numberOfItems)];
}

- (MPMediaItem*)queueTrackAtIndex:(unsigned long long)index  {
	NSString *selectorString = [NSString stringWithFormat:@"n%@%@%@", @"owPlayingI",@"temA",@"tIndex:"];
	
	SEL sse = NSSelectorFromString(selectorString);
	
	if ([MPMusicPlayerController instancesRespondToSelector:sse]) {
		IMP sseimp = [MPMusicPlayerController instanceMethodForSelector:sse];
		MPMediaItem *mediaItem = sseimp([MPMusicPlayerController systemMusicPlayer], sse, @(index));
		//		NSLog(@"Object %@ title %@ for index %lld for selector %@", mediaItem, mediaItem.title, index, NSStringFromSelector(sse));
		return mediaItem;
	}
	
	NSLog(@"Doesn't respond :(");
	
	return nil;
}

- (void)reshuffle {
#warning Todo: reshuffle
}

- (NSInteger)indexOfNowPlayingTrack {
	if(self.fullQueueAvailable){
		return self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem;
	}
	
#warning Todo: fix this for large queues that were set outside of Lignite Music
	return self.adjustedIndexOfNowPlayingTrack;
}

- (NSInteger)indexOfNextTrack {	
	if((self.indexOfNowPlayingTrack + 1) < self.completeQueue.count){
		return self.indexOfNowPlayingTrack + 1;
	}
	else if(self.completeQueue.count > 0){
		return 0;
	}
	
	return NSNotFound;
}

- (NSInteger)indexOfPreviousTrack {
	if((self.indexOfNowPlayingTrack - 1) > 0){
		return self.indexOfNowPlayingTrack - 1;
	}
	else if(self.completeQueue.count > 0){
		return (self.completeQueue.count - 1);
	}
	
	return NSNotFound;
}

- (LMMusicTrack*)nextTrack {
	NSInteger indexOfNextTrack = [self indexOfNextTrack];
	
	if(indexOfNextTrack != NSNotFound){
		return [self.completeQueue objectAtIndex:indexOfNextTrack];
	}
	
	return nil;
}

- (LMMusicTrack*)previousTrack {
	NSInteger indexOfPreviousTrack = [self indexOfPreviousTrack];
	
	if(indexOfPreviousTrack != NSNotFound){
		return [self.completeQueue objectAtIndex:indexOfPreviousTrack];
	}
	
	return nil;
}

- (void)systemReloadWithTrack:(LMMusicTrack*)newTrack {
	self.requiresSystemReload = NO;
	
	NSLog(@"Queue was modified and needs a refresher, here we go.");
	
	[self.musicPlayer.systemMusicPlayer setQueueWithItemCollection:self.completeQueueTrackCollection];
	[self.musicPlayer.systemMusicPlayer setNowPlayingItem:newTrack];
	[self.musicPlayer.systemMusicPlayer play];
}


- (void)setQueue:(LMMusicTrackCollection*)newQueue
		autoPlay:(BOOL)autoPlay
updateCompleteQueue:(BOOL)updateCompleteQueue {
	
	BOOL initialQueue = (self.completeQueue.count == 0);
	
	if(updateCompleteQueue){
		self.completeQueue = [NSMutableArray arrayWithArray:newQueue.items];
	}
		
	[self.musicPlayer.systemMusicPlayer setQueueWithItemCollection:newQueue];
	
	if(autoPlay){
		[self.musicPlayer.systemMusicPlayer setNowPlayingItem:[[newQueue items] objectAtIndex:0]];
		[self.musicPlayer.systemMusicPlayer play];
	}
	else if(!initialQueue && !autoPlay){
		self.requiresSystemReload = YES;
	}
	
	if(updateCompleteQueue){
		NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
		
		for(id<LMMusicQueueDelegate> delegate in safeDelegates){
			if([delegate respondsToSelector:@selector(queueCompletelyChanged)]){
				[delegate queueCompletelyChanged];
			}
		}
	}
}

- (void)setQueue:(LMMusicTrackCollection*)newQueue autoPlay:(BOOL)autoPlay {
	[self setQueue:newQueue autoPlay:autoPlay updateCompleteQueue:YES];
}

- (void)setQueue:(LMMusicTrackCollection*)newQueue {
	[self setQueue:newQueue autoPlay:NO];
}

- (void)completeQueueUpdated {
	[self setQueue:self.completeQueueTrackCollection autoPlay:NO updateCompleteQueue:NO];
}

- (void)addTrackToQueue:(LMMusicTrack*)trackToAdd {
	NSLog(@"Adding %@ to queue", trackToAdd.title);
	
	[self.completeQueue insertObject:trackToAdd atIndex:self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem + 1];
	
	[self completeQueueUpdated];
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];

	for(id<LMMusicQueueDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackAddedToQueue:)]){
			[delegate trackAddedToQueue:trackToAdd];
		}
	}
}

- (void)removeTrackAtIndex:(NSInteger)trackIndex {
	if(trackIndex < 0 || (trackIndex >= self.completeQueue.count)){
		return;
	}
	
	LMMusicTrack *trackRemoved = [self.completeQueue objectAtIndex:trackIndex];
	
	[self.completeQueue removeObjectAtIndex:trackIndex];
	
	[self completeQueueUpdated];
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];

	for(id<LMMusicQueueDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackRemovedFromQueue:)]){
			[delegate trackRemovedFromQueue:trackRemoved];
		}
	}
}

- (void)prepareQueueModification DEPRECATED_ATTRIBUTE {
#warning Todo: prepare queue modification
}

- (void)finishQueueModification DEPRECATED_ATTRIBUTE {
#warning Todo: finish queue modification
}

- (NSInteger)indexOfTrackInCompleteQueueFromPreviousTracks:(BOOL)fromPreviousTracks
									 withIndexInSubQueueOf:(NSInteger)indexInSubQueue {
	
	NSInteger indexInCompleteQueue = NSNotFound;
		
	if(!fromPreviousTracks){
		indexInCompleteQueue = self.previousTracks.count + 1 + indexInSubQueue;
	}
	else{
		if((indexInSubQueue == 0) && (self.previousTracks.count == 0)){
			return 0; //Now playing, first track in complete queue
		}
		
		indexInCompleteQueue = indexInSubQueue;
	}
	
	return indexInCompleteQueue;
}

- (NSInteger)indexOfTrackInCompleteQueueFromIndexPath:(NSIndexPath*)trackIndexPath {
	return [self indexOfTrackInCompleteQueueFromPreviousTracks:(trackIndexPath.section == 0)
										 withIndexInSubQueueOf:trackIndexPath.row];
}

- (void)moveTrackFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex {
	NSLog(@"Move track %d to index %d", (int)oldIndex, (int)newIndex);
	
	LMMusicTrack *currentMusicTrack = [self.completeQueue objectAtIndex:oldIndex];
	[self.completeQueue removeObjectAtIndex:oldIndex];
	[self.completeQueue insertObject:currentMusicTrack atIndex:newIndex];
	
	[self completeQueueUpdated];
	
	NSArray *safeDelegates = [[NSArray alloc] initWithArray:self.delegates];
	
	for(id<LMMusicQueueDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackMovedInQueue:)]){
			[delegate trackMovedInQueue:currentMusicTrack];
		}
	}

}

- (NSInteger)count {
	return self.completeQueue.count;
}

- (BOOL)queueIsStale {
	return (self.musicPlayer.nowPlayingTrack && (self.numberOfItemsInSystemQueue > 0) && (self.completeQueue.count == 0));
}

- (NSArray<LMMusicTrack*>*)previousTracks {
	if(!self.musicPlayer.nowPlayingTrack || self.numberOfItemsInSystemQueue == 0){
		return @[];
	}
	
	if([self queueIsStale]){
		NSLog(@"Queue is stale, rebuilding.");
		[self rebuild];
		return @[];
	}
	
	NSInteger indexOfNowPlayingTrack = self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem;
	
	if(indexOfNowPlayingTrack == 0){ //Nothing previous to the first track of course
		return @[];
	}
	
	return [self.completeQueue subarrayWithRange:NSMakeRange(0, indexOfNowPlayingTrack)];
}

- (NSArray<LMMusicTrack*>*)nextTracks {
	if(!self.musicPlayer.nowPlayingTrack || (self.numberOfItemsInSystemQueue == 0)){
		return @[];
	}
	
	if([self queueIsStale]){
		NSLog(@"Queue is stale, rebuilding.");
		[self rebuild];
		return @[];
	}
	
	NSInteger indexOfNowPlayingTrack = self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem;
	NSInteger finalIndexOfQueue = self.completeQueue.count - 1;
	
	if(indexOfNowPlayingTrack == finalIndexOfQueue){
		return @[];
	}
	
	NSInteger indexOfNextTrack = (indexOfNowPlayingTrack + 1);
	NSInteger length = ((finalIndexOfQueue + 1) - indexOfNextTrack);
	
	return [self.completeQueue subarrayWithRange:NSMakeRange(indexOfNextTrack, length)];
}

- (BOOL)queueExists {
	return (self.completeQueue.count > 0);
}

- (void)rebuild {
	__weak id weakSelf = self;

	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
		LMMusicQueue *strongSelf = weakSelf;

		if (!strongSelf) {
			NSLog(@"A strong copy of self doesn't exist, can't build queue.");
			return;
		}
		
		BOOL noPreviousQueue = ![self queueExists];

		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		NSInteger startingIndex = NSNotFound;
		BOOL fullQueueAvailable = YES;

		NSMutableArray<LMMusicTrack*> *systemQueueArray = [NSMutableArray new];
		for(NSInteger i = 0; i < strongSelf.numberOfItemsInSystemQueue; i++){
			LMMusicTrack *track = [strongSelf queueTrackAtIndex:i];
			if(track){
				NSLog(@"Track %d is %@", (int)i, track.title);
				[systemQueueArray addObject:track];
				
				if(startingIndex == NSNotFound){
					startingIndex = i;
				}
			}
			else{
				NSLog(@"Track %d is nil :(", (int)i);
				
				fullQueueAvailable = NO;
			}
		}

		self.completeQueue =  systemQueueArray;
		self.adjustedIndexOfNowPlayingTrack = (self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem - startingIndex);
		self.fullQueueAvailable = fullQueueAvailable;
		
		BOOL noCurrentQueue = ![self queueExists];
		
		NSArray *previous = [self previousTracks];
		for(NSInteger i = 0; i < previous.count; i++){
			LMMusicTrack *track = [previous objectAtIndex:i];
			NSLog(@"Previously played: %@", track.title);
		}
		
		NSLog(@"> Current track: %@", self.musicPlayer.nowPlayingTrack.title);
		
		NSArray *upNext = [self nextTracks];
		for(NSInteger i = 0; i < upNext.count; i++){
			LMMusicTrack *track = [upNext objectAtIndex:i];
			NSLog(@"Up next: %@", track.title);
		}
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		NSLog(@"\nLMMusicQueue rebuild summary\n%d out of %d tracks captured in %f seconds.\n%d tracks previous, %d tracks next.\n\nNo previous queue %d, no current queue %d.", (int)self.completeQueue.count, (int)self.numberOfItemsInSystemQueue, (endTime-startTime), (int)previous.count, (int)upNext.count, noPreviousQueue, noCurrentQueue);


		dispatch_async(dispatch_get_main_queue(), ^{
			if(noPreviousQueue && !noCurrentQueue){
				for(id<LMMusicQueueDelegate>delegate in strongSelf.delegates){
					if([delegate respondsToSelector:@selector(queueBegan)]){
						[delegate queueBegan];
					}
				}
			}
			else if(!noPreviousQueue && noCurrentQueue){
				for(id<LMMusicQueueDelegate>delegate in strongSelf.delegates){
					if([delegate respondsToSelector:@selector(queueEnded)]){
						[delegate queueEnded];
					}
				}
			}

			NSLog(@"Finished building and distributing system queue. %lu tracks loaded.", (unsigned long)systemQueueArray.count);
		});
	});
}

- (void)addDelegate:(id<LMMusicQueueDelegate>)delegate {
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<LMMusicQueueDelegate>)delegate {
	[self.delegates removeObject:delegate];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		self.delegates = [NSMutableArray new];
	}
	return self;
}

+ (LMMusicQueue*)sharedMusicQueue {
	static LMMusicQueue *sharedQueue;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedQueue = [self new];
	});
	return sharedQueue;
}

@end
