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
#import "LMMusicPlayer.h"

@interface LMMusicQueue()



@end

@implementation LMMusicQueue

- (NSInteger)numberOfItemsInQueue {
	return [[MPMusicPlayerController systemMusicPlayer] performSelector:@selector(numberOfItems)];;
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

- (void)rebuildQueue {
	return;
	
	__weak id weakSelf = self;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		LMMusicPlayer *strongSelf = weakSelf;

		if (!strongSelf) {
			return;
		}

		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];

		BOOL queueTooLarge = NO;

		NSMutableArray<LMMusicTrack*> *systemQueueArray = [NSMutableArray new];
		for(NSInteger i = 0; i < strongSelf.numberOfItemsInQueue; i++){
			LMMusicTrack *track = [strongSelf queueTrackAtIndex:i];
			if(track){
				NSLog(@"Track %d is %@", (int)i, track.title);
				[systemQueueArray addObject:track];
			}
			else{
				NSLog(@"Track %d is nil :(", (int)i);
			}
		}
//		if(systemQueueArray.count > 0){
//			strongSelf.nowPlayingCollectionSorted = [LMMusicTrackCollection collectionWithItems:systemQueueArray];
//		}
//		else{
//			strongSelf.nowPlayingCollectionSorted = nil;
//		}

		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		NSLog(@"Took %f seconds to load %ld tracks from the queue (out of %ld tracks).", (endTime-startTime), systemQueueArray.count, strongSelf.numberOfItemsInQueue);

//		dispatch_async(dispatch_get_main_queue(), ^{
//			strongSelf.nowPlayingTrack = strongSelf.systemMusicPlayer.nowPlayingItem;
//			strongSelf.nowPlayingQueueTooLarge = queueTooLarge;
//
//			for(id<LMMusicPlayerDelegate>delegate in strongSelf.delegates){
//				if([delegate respondsToSelector:@selector(trackAddedToQueue:)]){
//					[delegate trackAddedToQueue:[systemQueueArray firstObject]];
//				}
//			}
//
//			NSLog(@"Finished building and distributing system queue. %lu tracks loaded. Queue too large? %d", (unsigned long)systemQueueArray.count, queueTooLarge);
//		});
	});
}

- (void)prepareQueueForBackgrounding {
#warning Todo: prepare queue for backgrounding
}

- (instancetype)init {
	self = [super init];
	if(self){
		
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
