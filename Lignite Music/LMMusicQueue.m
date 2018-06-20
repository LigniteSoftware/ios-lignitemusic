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
#import "LMSettings.h"

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
 Whether or not the full system queue is available to us. If YES, no tracks provided by the system were nil and the queue was not shortened to optimise for speed.
 */
@property BOOL fullQueueAvailable;

/**
 The starting index of the system queue. This will be NSNotFound if there's no queue, and if the full queue isn't available, there's a chance that this will be greater than 0 (due to only being able to access 499 songs in either direction).
 */
@property NSInteger systemQueueStartingIndex;

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

/**
 The index range of the previous tracks array relative to the complete queue.
 */
@property (readonly) NSRange previousTracksIndexRange;

/**
 The index range of the next up tracks array relative to the complete queue.
 */
@property (readonly) NSRange nextTracksIndexRange;

@end

@implementation LMMusicQueue

@synthesize nextTracks = _nextTracks;
@synthesize previousTracks = _previousTracks;
@synthesize count = _count;
@synthesize systemQueueCount = _systemQueueCount;
@synthesize indexOfNowPlayingTrack = _indexOfNowPlayingTrack;
@synthesize completeQueue = _completeQueue;
@synthesize completeQueueTrackCollection = _completeQueueTrackCollection;

- (LMMusicTrackCollection*)completeQueueTrackCollection {
	return [LMMusicTrackCollection collectionWithItems:self.completeQueue];
}

- (void)systemNowPlayingTrackDidChange:(LMMusicTrack*)musicTrack {
	NSLog(@"System music track changed");
	
	[self calculateAdjustedIndex];
	if(!self.fullQueueAvailable){
		[self rebuild];
	}
}

- (void)prepareForBackgrounding {
	if(self.requiresSystemReload){
		self.requiresSystemReload = NO;
		
		CGFloat currentPlaybackTime = self.musicPlayer.currentPlaybackTime;
		
		NSLog(@"Preparing for the background by performing a system reload of the queue.");
		
		[self systemReloadWithTrack:self.musicPlayer.nowPlayingTrack];
		
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

- (BOOL)hasBeenBuilt {
	return (self.completeQueue.count > 0);
}

- (NSInteger)systemQueueCount {
	return (NSInteger)[[MPMusicPlayerController systemMusicPlayer] performSelector:@selector(numberOfItems)];
}

- (MPMediaItem*)systemQueueTrackAtIndex:(unsigned long long)index  {
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

- (NSInteger)systemIndexOfNowPlayingTrack {
	return self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem;
}

- (NSInteger)indexOfNowPlayingTrack {
	if([LMLayoutManager isSimulator] || ![self queueAPIsAvailable]){
		return (self.testCollection.items.count - 6);
	}
	
	if(![self queueAPIsAvailable]){
		return NSNotFound;
	}
	
//	if(self.fullQueueAvailable){
		if(self.adjustedIndexOfNowPlayingTrack != NSNotFound){
			return self.adjustedIndexOfNowPlayingTrack;
		}
		return self.systemIndexOfNowPlayingTrack;
//	}
	
//#warning Todo: fix this for large queues that were set outside of Lignite Music
//	return self.adjustedIndexOfNowPlayingTrack;
}

- (NSInteger)indexOfNextTrack {
	if(![self queueAPIsAvailable]){
		return NSNotFound;
	}
	
	if((self.indexOfNowPlayingTrack + 1) < self.completeQueue.count){
		return self.indexOfNowPlayingTrack + 1;
	}
	else if(self.completeQueue.count > 0){
		return 0;
	}
	
	return NSNotFound;
}

- (NSInteger)indexOfPreviousTrack {
	if(![self queueAPIsAvailable]){
		return NSNotFound;
	}
	
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
	
	if((indexOfNextTrack != NSNotFound) && (indexOfNextTrack < self.completeQueue.count)){
		return [self.completeQueue objectAtIndex:indexOfNextTrack];
	}
	
	return nil;
}

- (LMMusicTrack*)previousTrack {
	NSInteger indexOfPreviousTrack = [self indexOfPreviousTrack];
	
	if((indexOfPreviousTrack != NSNotFound) && (indexOfPreviousTrack < self.completeQueue.count)){
		return [self.completeQueue objectAtIndex:indexOfPreviousTrack];
	}
	
	return nil;
}

- (void)systemReloadWithTrack:(LMMusicTrack*)newTrack {
	self.requiresSystemReload = NO;
	
	NSLog(@"Queue was modified and needs a refresher, here we go.");
	
	self.adjustedIndexOfNowPlayingTrack = NSNotFound;
	
	[self.musicPlayer.systemMusicPlayer setQueueWithItemCollection:self.completeQueueTrackCollection];
	[self.musicPlayer.systemMusicPlayer setNowPlayingItem:newTrack];
	[self.musicPlayer.systemMusicPlayer play];
}


- (void)notifyDelegatesOfCompletelyChangedQueue {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicQueueDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(queueCompletelyChanged)]){
			[delegate queueCompletelyChanged];
		}
	}
}

- (void)setQueue:(LMMusicTrackCollection*)newQueue
		autoPlay:(BOOL)autoPlay
updateCompleteQueue:(BOOL)updateCompleteQueue {
	
	self.mostRecentAction = LMMusicQueueActionTypePlayMusic;
	
	BOOL initialQueue = (self.completeQueue.count == 0);
	
	NSLog(@"Setting new queue with autoplay %d, updateCompleteQueue %d", autoPlay, updateCompleteQueue);
	
	for(NSInteger i = 0; i < newQueue.items.count; i++){
		LMMusicTrack *track = [newQueue.items objectAtIndex:i];
		NSLog(@"> Track %d is %@", (int)i, track.title);
	}
	
	if(updateCompleteQueue){
		self.completeQueue = [NSMutableArray arrayWithArray:newQueue.items];
		[self.musicPlayer.systemMusicPlayer setQueueWithItemCollection:newQueue];
		
		self.fullQueueAvailable = YES;
		
		[self queueFinishedBuilding];
	}
	
	if(autoPlay){
		[self.musicPlayer.systemMusicPlayer setNowPlayingItem:[[newQueue items] objectAtIndex:0]];
		[self.musicPlayer.systemMusicPlayer play];
	}
	else if(!autoPlay && !updateCompleteQueue){
		self.requiresSystemReload = YES;
	}
	
	if(updateCompleteQueue){
		[self notifyDelegatesOfCompletelyChangedQueue];
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
	NSLog(@"Adding %@ to queue at index %d", trackToAdd.title, (int)(self.indexOfNowPlayingTrack + 1));
	
	self.mostRecentAction = LMMusicQueueActionTypeAddTrack;
	
	[self.completeQueue insertObject:trackToAdd atIndex:self.indexOfNowPlayingTrack + 1];
	
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
	
	self.mostRecentAction = LMMusicQueueActionTypeRemoveTrack;
	
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

- (void)moveTrackFromIndexPath:(NSIndexPath*)oldIndexPath toIndexPath:(NSIndexPath*)newIndexPath {
	NSInteger previousIndexOfNowPlayingTrack = self.indexOfNowPlayingTrack;
	
	NSInteger oldIndex = [self indexOfTrackInCompleteQueueFromIndexPath:oldIndexPath];
	NSInteger newIndex = [self indexOfTrackInCompleteQueueFromIndexPath:newIndexPath];
	
	BOOL isReplacingNowPlayingTrack = (newIndex == previousIndexOfNowPlayingTrack);
	
	BOOL oldIndexIsInPreviousTracks = (oldIndex < previousIndexOfNowPlayingTrack);
	BOOL newIndexIsInPreviousTracks = oldIndexIsInPreviousTracks ? (newIndex < previousIndexOfNowPlayingTrack) : (newIndex <= previousIndexOfNowPlayingTrack);
	
	BOOL movingIntoPreviousTracks = (!oldIndexIsInPreviousTracks && newIndexIsInPreviousTracks) && (newIndex <= previousIndexOfNowPlayingTrack);
	BOOL movingIntoNextTracks = (oldIndexIsInPreviousTracks && !newIndexIsInPreviousTracks);
	
	LMMusicTrack *currentMusicTrack = [self.completeQueue objectAtIndex:oldIndex];
	[self.completeQueue removeObjectAtIndex:oldIndex];
	[self.completeQueue insertObject:currentMusicTrack atIndex:newIndex - (movingIntoNextTracks && !isReplacingNowPlayingTrack)];
	
	if(movingIntoPreviousTracks){
		self.adjustedIndexOfNowPlayingTrack = (previousIndexOfNowPlayingTrack + 1);
	}
	else if(movingIntoNextTracks){
		self.adjustedIndexOfNowPlayingTrack = (previousIndexOfNowPlayingTrack - 1);
	}
	
	[self completeQueueUpdated];
	
	NSArray *safeDelegates = [[NSArray alloc] initWithArray:self.delegates];
	
	for(id<LMMusicQueueDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackMovedInQueue:)]){
			[delegate trackMovedInQueue:currentMusicTrack];
		}
	}
}

- (NSMutableArray<LMMusicTrack*>*)completeQueue {
	if([LMLayoutManager isSimulator] || ![self queueAPIsAvailable]){
		NSMutableArray *array = [NSMutableArray arrayWithArray:self.testCollection.items];
	//	NSLog(@"Array count %d", (int)array.count);
		return array;
	}
	
	return _completeQueue;
}

- (void)setCompleteQueue:(NSMutableArray<LMMusicTrack *> *)completeQueue {
	_completeQueue = completeQueue;
}

- (NSInteger)completeQueueCount {
//	NSLog(@"Count %d is sim %d", (int)self.completeQueue.count, LMLayoutManager.isSimulator);
	return self.completeQueue.count;
}

- (NSInteger)count {
	if([LMLayoutManager isSimulator] || ![self queueAPIsAvailable]){
		return self.completeQueueCount;
	}
	
	if(self.fullQueueAvailable && ![LMSettings quickLoad]){
		return self.completeQueueCount;
	}
	
	return self.systemQueueCount;
}

- (BOOL)queueIsStale {
//	NSLog(@"Now playing track %d, count %d, complete %d", (self.musicPlayer.nowPlayingTrack ? YES : NO), (int)self.systemQueueCount, (int)self.completeQueue.count);
	return (self.musicPlayer.nowPlayingTrack && (self.systemQueueCount > 0) && (self.completeQueue.count == 0));
}

- (NSRange)previousTracksIndexRange {
	NSInteger indexOfNowPlayingTrack = self.indexOfNowPlayingTrack;
	
	if(indexOfNowPlayingTrack == 0){ //Nothing previous to the first track of course
		return NSMakeRange(0, 0);
	}
	
	NSInteger startingIndex = 0;
	if([LMSettings quickLoad]){
		if(indexOfNowPlayingTrack > 24){
			startingIndex = indexOfNowPlayingTrack - 25;
		}
	}
	
	return NSMakeRange(startingIndex, indexOfNowPlayingTrack);
}

- (NSRange)nextTracksIndexRange {
	NSInteger indexOfNowPlayingTrack = self.indexOfNowPlayingTrack;
	NSInteger finalIndexOfQueue = self.completeQueue.count - 1;
	
	if(indexOfNowPlayingTrack == finalIndexOfQueue){
		return NSMakeRange(0, 0);
	}
	
	NSInteger indexOfNextTrack = (indexOfNowPlayingTrack + 1);
	NSInteger length = ((finalIndexOfQueue + 1) - indexOfNextTrack);
	
	if([LMSettings quickLoad]){
		if(length > 25){
			length = 25;
		}
	}
	
	return NSMakeRange(indexOfNextTrack, length);
}

- (NSArray<LMMusicTrack*>*)previousTracks {
	if(!([LMLayoutManager isSimulator] || ![self queueAPIsAvailable])){
		if(!self.musicPlayer.nowPlayingTrack || (self.systemQueueCount == 0) || ![self queueAPIsAvailable]){
			return @[];
		}
		
		if([self queueIsStale]){
			NSLog(@"Queue is stale, rebuilding.");
			[self rebuild];
			return @[];
		}
		
		if(self.indexOfNowPlayingTrack == 0){ //Nothing previous to the first track of course
			return @[];
		}
	}
	
	return [self.completeQueue subarrayWithRange:self.previousTracksIndexRange];
}

- (NSArray<LMMusicTrack*>*)nextTracks {
	if(!([LMLayoutManager isSimulator] || ![self queueAPIsAvailable])){
		if(!self.musicPlayer.nowPlayingTrack || (self.systemQueueCount == 0) || ![self queueAPIsAvailable]){
			return @[];
		}
		
		if([self queueIsStale]){
			NSLog(@"Queue is stale, rebuilding.");
			[self rebuild];
			return @[];
		}
		
		NSInteger finalIndexOfQueue = self.completeQueue.count - 1;
		
		if(self.indexOfNowPlayingTrack == finalIndexOfQueue){
			return @[];
		}
	}
	
	return [self.completeQueue subarrayWithRange:self.nextTracksIndexRange];
}

- (BOOL)queueExists {
	return (self.completeQueue.count > 0);
}

- (void)calculateAdjustedIndex {
	if(!self.fullQueueAvailable){
		NSLog(@"Calculating adjusted index with current adjusted %d, index of now playing %d, starting index %d", (int)self.adjustedIndexOfNowPlayingTrack, (int)self.systemIndexOfNowPlayingTrack, (int)self.systemQueueStartingIndex);
		
		self.adjustedIndexOfNowPlayingTrack = (self.systemIndexOfNowPlayingTrack - self.systemQueueStartingIndex);
	}
}

- (BOOL)queueAPIsAvailable {
	return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
}

- (void)invalidateCompleteQueue {
	self.completeQueue = nil;
	
	for(id<LMMusicQueueDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(queueInvalidated)]){
			[delegate queueInvalidated];
		}
	}
}

- (void)queueFinishedBuilding {
	for(id<LMMusicQueueDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(queueIsBeingRebuilt:becauseOfActionType:)]){
			[delegate queueIsBeingRebuilt:NO becauseOfActionType:self.mostRecentAction];
		}
	}
}

- (void)queueBeganBuilding {
	for(id<LMMusicQueueDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(queueIsBeingRebuilt:becauseOfActionType:)]){
			[delegate queueIsBeingRebuilt:YES becauseOfActionType:self.mostRecentAction];
		}
	}
}

- (void)rebuild {
	__weak id weakSelf = self;
	
//	if(![self queueAPIsAvailable]){
//		NSLog(@"Incompatible version of iOS, refusing to rebuild.");
//		return;
//	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		LMMusicQueue *strongSelf = weakSelf;

		if (!strongSelf) {
			NSLog(@"A strong copy of self doesn't exist, can't build queue.");
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[strongSelf queueBeganBuilding];
		});
		
		BOOL noPreviousQueue = ![strongSelf queueExists];

		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		strongSelf.systemQueueStartingIndex = NSNotFound;
		strongSelf.fullQueueAvailable = YES;

		NSMutableArray<LMMusicTrack*> *systemQueueArray = [NSMutableArray new];
		if([LMSettings quickLoad]){
			NSInteger startingIndex = strongSelf.systemIndexOfNowPlayingTrack - LMQuickLoadQueueLimit;
			NSInteger endingIndex = (startingIndex + (LMQuickLoadQueueLimit * 2) + 1);
			if(startingIndex < 0){
				startingIndex = 0;
			}
			if(endingIndex > strongSelf.systemQueueCount){
				endingIndex = strongSelf.systemQueueCount;
			}
			for(NSInteger i = startingIndex; i < endingIndex; i++){
				LMMusicTrack *track = [strongSelf systemQueueTrackAtIndex:i];
				if(track){
					[systemQueueArray addObject:track];
					
					if(strongSelf.systemQueueStartingIndex == NSNotFound){
						strongSelf.systemQueueStartingIndex = i;
					}
				}
			}
			
			strongSelf.fullQueueAvailable = (systemQueueArray.count == strongSelf.systemQueueCount);
		}
		else{ //Load all possible tracks
			NSLog(@"System queue count %d", (int)strongSelf.systemQueueCount);
			for(NSInteger i = 0; i < strongSelf.systemQueueCount; i++){
				LMMusicTrack *track = [strongSelf systemQueueTrackAtIndex:i];
				if(track){
					[systemQueueArray addObject:track];
					
					if(strongSelf.systemQueueStartingIndex == NSNotFound){
						strongSelf.systemQueueStartingIndex = i;
					}
				}
				else{
					strongSelf.fullQueueAvailable = NO;
				}
			}
		}

		self.completeQueue = systemQueueArray;

		[self calculateAdjustedIndex];
		
		BOOL noCurrentQueue = ![strongSelf queueExists];
		
		NSArray *previous = [strongSelf previousTracks];
//		for(NSInteger i = 0; i < previous.count; i++){
//			LMMusicTrack *track = [previous objectAtIndex:i];
//			NSLog(@"Previously played: %@", track.title);
//		}
//
//		if(previous.count == 0){
//			NSLog(@"\nNothing previously played.");
//		}
		
		NSLog(@"> Current track: %@", strongSelf.musicPlayer.nowPlayingTrack.title);
		
		NSArray *upNext = [strongSelf nextTracks];
		for(NSInteger i = 0; i < upNext.count; i++){
			LMMusicTrack *track = [upNext objectAtIndex:i];
			NSLog(@"Up next: %@", track.title);
		}
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		NSLog(@"\nLMMusicQueue rebuild summary\n%d out of %d tracks captured in %f seconds.\n%d tracks previous, %d tracks next.\n\nNo previous queue %d, no current queue %d.\nAdjusted now playing index %d vs %d.\n", (int)strongSelf.completeQueue.count, (int)strongSelf.systemQueueCount, (endTime-startTime), (int)previous.count, (int)upNext.count, noPreviousQueue, noCurrentQueue, (int)strongSelf.adjustedIndexOfNowPlayingTrack, (int)strongSelf.systemIndexOfNowPlayingTrack);


		dispatch_async(dispatch_get_main_queue(), ^{
			if(noPreviousQueue && !noCurrentQueue){
				for(id<LMMusicQueueDelegate>delegate in self.delegates){
					if([delegate respondsToSelector:@selector(queueBegan)]){
						[delegate queueBegan];
					}
				}
			}
			else if(!noPreviousQueue && noCurrentQueue){
				for(id<LMMusicQueueDelegate>delegate in self.delegates){
					if([delegate respondsToSelector:@selector(queueEnded)]){
						[delegate queueEnded];
					}
				}
			}
			else{
				[self notifyDelegatesOfCompletelyChangedQueue]; //There was a queue playing and there is still a queue playing
			}

			[self queueFinishedBuilding];
			
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
		self.adjustedIndexOfNowPlayingTrack = NSNotFound;
		
		if([LMLayoutManager isSimulator] || ![self queueAPIsAvailable]){
			self.testCollection = [[self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums] objectAtIndex:2];
		}
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
