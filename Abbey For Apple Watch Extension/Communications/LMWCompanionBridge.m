//
//  LMWCompanionBridge.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "LMWCompanionBridge.h"

@interface LMWCompanionBridge()<WCSessionDelegate>

/**
 The watch communication session.
 */
@property WCSession *session;

/**
 The delegates for this bridge.
 */
@property NSMutableArray<id<LMWCompanionBridgeDelegate>> *delegates;

@end

@implementation LMWCompanionBridge

- (void)debug:(NSString*)debug {
	for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
		if([delegate respondsToSelector:@selector(companionDebug:)]){
			[delegate companionDebug:debug];
		}
	}
}

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
	
//	[self.titleLabel setText:[NSString stringWithFormat:@"%d", activationState]];
//	[self.subtitleLabel setText:error.description];
}


- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
	NSString *key = [message objectForKey:LMAppleWatchCommunicationKey];
	
	if(!key){ //There MUST be a key contained in the dictionary.
		return;
	}
	
	if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingTrack]){
		NSDictionary *trackDictionary = [message objectForKey:LMAppleWatchCommunicationKeyNowPlayingTrack];
		
		if(!self.nowPlayingInfo.nowPlayingTrack){
			self.nowPlayingInfo.nowPlayingTrack = [LMWMusicTrackInfo new];
		}
		
		self.nowPlayingInfo.nowPlayingTrack.title = [trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyTitle];
		self.nowPlayingInfo.nowPlayingTrack.subtitle = [trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeySubtitle];
		self.nowPlayingInfo.nowPlayingTrack.isFavourite = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyIsFavourite] boolValue];
		self.nowPlayingInfo.nowPlayingTrack.playbackDuration = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyPlaybackDuration] integerValue];
		self.nowPlayingInfo.nowPlayingTrack.persistentID = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyPersistentID] longLongValue];
		self.nowPlayingInfo.nowPlayingTrack.albumPersistentID = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyAlbumPersistentID] longLongValue];
		
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(musicTrackDidChange:)]){
				[delegate musicTrackDidChange:self.nowPlayingInfo.nowPlayingTrack];
			}
		}
	}
	else if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingInfo]){
		NSDictionary *infoDictionary = [message objectForKey:LMAppleWatchCommunicationKeyNowPlayingInfo];
		
		self.nowPlayingInfo.playing = [[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyIsPlaying] boolValue];
		self.nowPlayingInfo.repeatMode = (LMMusicRepeatMode)[[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyRepeatMode] integerValue];
		self.nowPlayingInfo.shuffleMode = (LMMusicShuffleMode)[[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyShuffleMode] integerValue];
		self.nowPlayingInfo.playbackDuration = [[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyPlaybackDuration] integerValue];
		self.nowPlayingInfo.currentPlaybackTime = [[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime] integerValue];
		
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(nowPlayingInfoDidChange:)]){
				[delegate nowPlayingInfoDidChange:self.nowPlayingInfo];
			}
		}
	}
	else if([key isEqualToString:LMAppleWatchCommunicationKeyNoTrackPlaying]){
		self.nowPlayingInfo.nowPlayingTrack = nil;
		
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(musicTrackDidChange:)]){
				[delegate musicTrackDidChange:nil];
			}
		}
	}
	else if([key isEqualToString:LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue]){
		NSArray *tracksArray = [message objectForKey:LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue];
		
		NSMutableArray<LMWMusicTrackInfo*> *tracksInfoArray = [NSMutableArray new];
		for(NSDictionary *trackInfoDictionary in tracksArray){
			LMWMusicTrackInfo *trackInfo = [LMWMusicTrackInfo new];
			trackInfo.title = [trackInfoDictionary objectForKey:@"title"];
			trackInfo.subtitle = [trackInfoDictionary objectForKey:@"subtitle"];
			trackInfo.persistentID = [[trackInfoDictionary objectForKey:@"persistentID"] longLongValue];
			trackInfo.indexInCollection = [[trackInfoDictionary objectForKey:@"indexInCollection"] integerValue];
			[tracksInfoArray addObject:trackInfo];
		}
		
		NSArray<LMWMusicTrackInfo*>* finalTracksInfoArray = [NSArray arrayWithArray:tracksInfoArray];
		
		self.nowPlayingInfo.nextUpTracksArray = finalTracksInfoArray;
		
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(nowPlayingUpNextDidChange:)]){
				[delegate nowPlayingUpNextDidChange:finalTracksInfoArray];
			}
		}
	}
}

/** Called on the delegate of the receiver when the sender sends a message that expects a reply. Will be called on startup if the incoming message caused the receiver to launch. */
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
	
//	[self.titleLabel setText:[message objectForKey:@"title"]];
	
	replyHandler(@{ @"whats":@"up" });
}


- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData {
	UIImage *image = [UIImage imageWithData:messageData];
	
	self.nowPlayingInfo.nowPlayingTrack.albumArt = image;
	
	for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
		if([delegate respondsToSelector:@selector(albumArtDidChange:)]){
			[delegate albumArtDidChange:image];
		}
	}
}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData replyHandler:(void (^)(NSData * _Nonnull))replyHandler {
	
//	UIImage *image = [UIImage imageWithData:messageData];
//	[self.albumArtImage setImage:image];
}


- (void)askCompanionForNowPlayingTrackInfo {
	if(self.session.reachable){
		[self.session sendMessage:@{ LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingTrack } replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
			NSLog(@"Got reply %@", replyMessage);
		} errorHandler:^(NSError * _Nonnull error) {
			NSLog(@"Error %@", error);
		}];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self askCompanionForNowPlayingTrackInfo];
			}];
		});
	}
}

- (void)sendMusicControlMessageToPhoneWithKey:(NSString*)key {
	if(self.session.reachable){
		[self.session sendMessage:@{ LMAppleWatchCommunicationKey:key }
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						NSLog(@"Got reply %@", replyMessage);
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						NSLog(@"Error %@", error);
					 }
		];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self sendMusicControlMessageToPhoneWithKey:key];
			}];
		});
	}
}

- (void)setUpNextTrack:(NSInteger)indexOfNextUpTrackSelected {
	if(self.session.reachable){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchControlKeyUpNextTrackSelected,
									LMAppleWatchControlKeyUpNextTrackSelected: @(indexOfNextUpTrackSelected)
									}
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 NSLog(@"Got reply %@", replyMessage);
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error %@", error);
					 }
		 ];
	}
}

- (void)requestTracksWithSelectedIndexes:(NSArray<NSNumber*>*)selectedIndexes
						 withPageIndexes:(NSArray<NSNumber*>*)pageIndexes
						   forMusicTypes:(NSArray<NSNumber*>*)musicTypes
					   withPersistentIDs:(NSArray<NSNumber*>*)persistentIDs
							replyHandler:(nullable void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
							errorHandler:(nullable void (^)(NSError *error))errorHandler {
	
	
	if(self.session.reachable){
		NSDictionary *messageDictionary = @{
											LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyMusicBrowsingEntries,
											LMAppleWatchBrowsingKeyMusicTypes: musicTypes,
											LMAppleWatchBrowsingKeyPersistentIDs: persistentIDs,
											LMAppleWatchBrowsingKeySelectedIndexes: selectedIndexes,
											LMAppleWatchBrowsingKeyPageIndexes: pageIndexes
											};
	
		[self.session sendMessage:messageDictionary
					 replyHandler:replyHandler
					 errorHandler:errorHandler];
	}
}

- (void)setCurrentPlaybackTime:(NSInteger)currentPlaybackTime {
	if(self.session.reachable){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchControlKeyCurrentPlaybackTime,
									LMAppleWatchControlKeyCurrentPlaybackTime:@(currentPlaybackTime)
									 }
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 NSLog(@"Got reply %@", replyMessage);
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error %@", error);
					 }
		 ];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self setCurrentPlaybackTime:currentPlaybackTime];
			}];
		});
	}
}


- (void)addDelegate:(id<LMWCompanionBridgeDelegate>)delegate {
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<LMWCompanionBridgeDelegate>)delegateToRemove {
	[self.delegates removeObject:delegateToRemove];
}


+ (LMWCompanionBridge*)sharedCompanionBridge {
	static LMWCompanionBridge *sharedCompanionBridge;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedCompanionBridge = [self new];
		sharedCompanionBridge.delegates = [NSMutableArray new];
		sharedCompanionBridge.nowPlayingInfo = [LMWNowPlayingInfo new];
		
		if ([WCSession isSupported]) {
			sharedCompanionBridge.session = [WCSession defaultSession];
			sharedCompanionBridge.session.delegate = sharedCompanionBridge;
			[sharedCompanionBridge.session activateSession];
		}
	});
	return sharedCompanionBridge;
}

@end
