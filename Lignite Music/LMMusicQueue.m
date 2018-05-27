//
//  LMMusicQueue.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMMusicQueue.h"

@interface LMMusicQueue()

/**
 The queue's delegates.
 */
@property NSMutableArray<id<LMMusicQueueDelegate>> *delegates;

/**
 The complete queue, as provided by the system.
 */
@property NSArray<LMMusicTrack*> *completeQueue;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMMusicQueue

@synthesize nextTracks = _nextTracks;
@synthesize previousTracks = _previousTracks;
@synthesize count = _count;

- (void)prepareQueueForBackgrounding {
#warning Todo: prepare queue for backgrounding
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

- (void)reshuffleSortedCollection {
#warning Todo: reshuffle
}

- (void)reloadQueueWithTrack:(LMMusicTrack*)newTrack {
#warning Todo: reload queue with track
}

- (LMMusicTrack*)nextTrackInQueue {
//	if((self.indexOfNowPlayingTrack + 1) < self.nowPlayingCollection.count){
//		return [self.nowPlayingCollection.items objectAtIndex:self.indexOfNowPlayingTrack + 1];
//	}
//	else if(self.nowPlayingCollection.count > 0){
//		return [self.nowPlayingCollection.items firstObject];
//	}
	
	return nil;
}

- (LMMusicTrack*)previousTrackInQueue {
//	if((self.indexOfNowPlayingTrack - 1) > 0){
//		return [self.nowPlayingCollection.items objectAtIndex:self.indexOfNowPlayingTrack - 1];
//	}
//	else if(self.nowPlayingCollection.count > 0){
//		return [self.nowPlayingCollection.items lastObject];
//	}
	
	return nil;
}

- (void)setNowPlayingCollection:(LMMusicTrackCollection*)nowPlayingCollection {
	//	self.nowPlayingWasSetWithinLigniteMusic = YES;
	
//	if(!nowPlayingCollection){
//		self.nowPlayingCollectionSorted = nil;
//		self.nowPlayingCollectionShuffled = nil;
//		self.nowPlayingTrack = nil;
//
//		[self.systemMusicPlayer stop];
//	}
//	else{
//		if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
//			self.nowPlayingCollectionSorted = nowPlayingCollection;
//			[self reshuffleSortedCollection];
//
//			if(!self.nowPlayingCollection){
//				[self.systemMusicPlayer setQueueWithQuery:self.bullshitQuery];
//				[self.systemMusicPlayer setNowPlayingItem:nil];
//				[self.systemMusicPlayer play];
//			}
//			NSLog(@"Setting now playing collection to %@", nowPlayingCollection);
//			if(nowPlayingCollection.count > 0){
//				[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
//				[self.systemMusicPlayer setNowPlayingItem:[[self.nowPlayingCollection items] objectAtIndex:0]];
//				[self.systemMusicPlayer play];
//			}
//			else{
//				self.nowPlayingCollection = nil;
//			}
//		}
//	}
}

- (void)addTrackToQueue:(LMMusicTrack*)trackToAdd DEPRECATED_ATTRIBUTE {
	NSLog(@"Adding %@ to queue", trackToAdd.title);
	
#warning Todo: add track to queue
	
//	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
//
//	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
//		if([delegate respondsToSelector:@selector(trackAddedToQueue:)]){
//			[delegate trackAddedToQueue:trackToAdd];
//		}
//	}
}

- (void)removeTrackFromQueue:(LMMusicTrack*)trackToRemove DEPRECATED_ATTRIBUTE {
	NSLog(@"Removing %@ from queue", trackToRemove.title);
	
#warning Todo: remove track from queue
	
//	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
//
//	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
//		if([delegate respondsToSelector:@selector(trackRemovedFromQueue:)]){
//			[delegate trackRemovedFromQueue:trackToRemove];
//		}
//	}
}

- (void)prepareQueueModification DEPRECATED_ATTRIBUTE {
#warning Todo: prepare queue modification
}

- (void)finishQueueModification DEPRECATED_ATTRIBUTE {
#warning Todo: finish queue modification
}

- (void)moveTrackInQueueFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex DEPRECATED_ATTRIBUTE {
#warning Todo: move track in queue
	NSLog(@"Move track %d to index %d", (int)oldIndex, (int)newIndex);
}

- (NSInteger)count {
	return self.completeQueue.count;
}

- (NSArray<LMMusicTrack*>*)previousTracks {
	if(!self.musicPlayer.systemMusicPlayer.nowPlayingItem || self.numberOfItemsInSystemQueue == 0){
		return @[];
	}
	
	NSInteger indexOfNowPlayingTrack = self.musicPlayer.systemMusicPlayer.indexOfNowPlayingItem;
	
	if(indexOfNowPlayingTrack == 0){ //Nothing previous to the first track of course
		return @[];
	}
	
	return [self.completeQueue subarrayWithRange:NSMakeRange(0, indexOfNowPlayingTrack)];
}

- (NSArray<LMMusicTrack*>*)nextTracks {
	if(!self.musicPlayer.systemMusicPlayer.nowPlayingItem || (self.numberOfItemsInSystemQueue == 0)){
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

		NSMutableArray<LMMusicTrack*> *systemQueueArray = [NSMutableArray new];
		for(NSInteger i = 0; i < strongSelf.numberOfItemsInSystemQueue; i++){
			LMMusicTrack *track = [strongSelf queueTrackAtIndex:i];
			if(track){
				NSLog(@"Track %d is %@", (int)i, track.title);
				[systemQueueArray addObject:track];
			}
			else{
				NSLog(@"Track %d is nil :(", (int)i);
			}
		}

		self.completeQueue = [NSArray arrayWithArray:systemQueueArray];
		
		BOOL noCurrentQueue = ![self queueExists];
		
		NSArray *previous = [self previousTracks];
		for(NSInteger i = 0; i < previous.count; i++){
			LMMusicTrack *track = [previous objectAtIndex:i];
			NSLog(@"Previously played: %@", track.title);
		}
		
		NSLog(@"> Current track: %@", self.musicPlayer.systemMusicPlayer.nowPlayingItem.title);
		
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
