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

- (BOOL)requiresUnlock {
	return self.session.iOSDeviceNeedsUnlockAfterRebootForReachability;
}

- (BOOL)connected {
	return self.session.reachable;
}

- (void)sessionReachabilityDidChange:(WCSession *)session {
	dispatch_async(dispatch_get_main_queue(), ^{
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(companionConnectionStatusChanged:)]){
				[delegate companionConnectionStatusChanged:self.connected];
			}
		}
	});
}

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
		self.nowPlayingInfo.currentPlaybackTime = [[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime] integerValue];
		self.nowPlayingInfo.volume = [[infoDictionary objectForKey:LMAppleWatchNowPlayingInfoKeyVolume] floatValue];
		
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
	//A property of the now playing track was updated.
	else if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingTrackUpdate]){
		NSString *trackKey = [message objectForKey:LMAppleWatchCommunicationKeyNowPlayingTrackUpdate];
		if([trackKey isEqualToString:LMAppleWatchMusicTrackInfoKeyIsFavourite]){
			self.nowPlayingInfo.nowPlayingTrack.isFavourite = [[message objectForKey:trackKey] boolValue];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
					if([delegate respondsToSelector:@selector(nowPlayingTrackUpdate:forKey:)]){
						[delegate nowPlayingTrackUpdate:self.nowPlayingInfo.nowPlayingTrack forKey:trackKey];
					}
				}
			});
		}
	}
	//A property of the now playing info was updated.
	else if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingInfoUpdate]){
		NSString *infoKey = [message objectForKey:LMAppleWatchCommunicationKeyNowPlayingInfoUpdate];
		if([infoKey isEqualToString:LMAppleWatchNowPlayingInfoKeyIsPlaying]){
			self.nowPlayingInfo.playing = [[message objectForKey:infoKey] boolValue];
		}
		else if([infoKey isEqualToString:LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime]){
			self.nowPlayingInfo.nowPlayingTrack.playbackDuration = [[message objectForKey:LMAppleWatchMusicTrackInfoKeyPlaybackDuration] integerValue];
			self.nowPlayingInfo.currentPlaybackTime = [[message objectForKey:infoKey] integerValue];
		}
		else if([infoKey isEqualToString:LMAppleWatchNowPlayingInfoKeyVolume]){
			self.nowPlayingInfo.volume = [[message objectForKey:LMAppleWatchNowPlayingInfoKeyVolume] floatValue];
		}
		else if([infoKey isEqualToString:LMAppleWatchNowPlayingInfoKeyShuffleMode]){
			self.nowPlayingInfo.shuffleMode = [[message objectForKey:LMAppleWatchNowPlayingInfoKeyShuffleMode] integerValue];
			self.nowPlayingInfo.repeatMode = [[message objectForKey:LMAppleWatchNowPlayingInfoKeyRepeatMode] integerValue];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
				if([delegate respondsToSelector:@selector(nowPlayingInfoUpdate:forKey:)]){
					[delegate nowPlayingInfoUpdate:self.nowPlayingInfo forKey:infoKey];
				}
			}
		});
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
	static int attempts = 0;
	
	if(self.session.reachable){
		[self.session sendMessage:@{ LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingTrack } replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
			NSLog(@"Got reply %@", replyMessage);
			attempts = 0;
		} errorHandler:^(NSError * _Nonnull error) {
			NSLog(@"Error getting companion info %@", error);
			attempts++;
			if(attempts < 3){
				NSLog(@"Trying again...");
				[self askCompanionForNowPlayingTrackInfo]; //Keep trying lol
			}
			else{
				attempts = 0;
			}
		}];
	}
	else if(attempts < 3){
		attempts++;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self askCompanionForNowPlayingTrackInfo];
			}];
		});
	}
	else if(attempts >= 3){
		attempts = 0;
	}
}

- (void)sendMusicControlMessageToPhoneWithKey:(NSString*)key
							   successHandler:(nullable void (^)(NSDictionary *response))successHandler
								 errorHandler:(nullable void (^)(NSError *error))errorHandler {
	
	if(self.session.reachable){
		[self.session sendMessage:@{ LMAppleWatchCommunicationKey:key }
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 dispatch_async(dispatch_get_main_queue(), ^{
							successHandler(replyMessage);
						 });
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						 dispatch_async(dispatch_get_main_queue(), ^{
							 errorHandler(error);
						 });
					 }
		 ];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			NSError *notRespondingError = [NSError errorWithDomain:@"The phone is not responding"
															  code:503
														  userInfo:nil];
			
			errorHandler(notRespondingError);
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
							replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
							errorHandler:(nonnull void (^)(NSError *error))errorHandler {
	
	
	static int attempts = 0;
	
	if(self.session.reachable){
		NSDictionary *messageDictionary = @{
											LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyMusicBrowsingEntries,
											LMAppleWatchBrowsingKeyMusicTypes: musicTypes,
											LMAppleWatchBrowsingKeyPersistentIDs: persistentIDs,
											LMAppleWatchBrowsingKeySelectedIndexes: selectedIndexes,
											LMAppleWatchBrowsingKeyPageIndexes: pageIndexes
											};
		
		[self.session sendMessage:messageDictionary
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 attempts = 0;
						 replyHandler(replyMessage);
						 NSLog(@"Noice");
					 } errorHandler:^(NSError * _Nonnull error) {
						 attempts++;
						 if(attempts < 3){
							 NSLog(@"Error fetching. Trying again: %@", error);
							 
							 [self requestTracksWithSelectedIndexes:selectedIndexes
													withPageIndexes:pageIndexes
													  forMusicTypes:musicTypes
												  withPersistentIDs:persistentIDs
													   replyHandler:replyHandler
													   errorHandler:errorHandler];
						 }
						 else{
							 attempts = 0;
							 errorHandler(error);
							 
							 NSLog(@"Errors are too much, sorry %@", error);
						 }
					 }];
	}
	else if(attempts < 3){
		attempts++;
		
		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self requestTracksWithSelectedIndexes:selectedIndexes
								   withPageIndexes:pageIndexes
									 forMusicTypes:musicTypes
								 withPersistentIDs:persistentIDs
									  replyHandler:replyHandler
									  errorHandler:errorHandler];
		}];
	}
	else if(attempts >= 3){
		NSError *notReplyingError = [NSError errorWithDomain:@"Phone isn't replying"
														code:503
													userInfo:nil];
		errorHandler(notReplyingError);
		
		attempts = 0;
	}
}

- (void)shuffleTracksWithSelectedIndexes:(NSArray<NSNumber*>*)selectedIndexes
						 withPageIndexes:(NSArray<NSNumber*>*)pageIndexes
						   forMusicTypes:(NSArray<NSNumber*>*)musicTypes
					   withPersistentIDs:(NSArray<NSNumber*>*)persistentIDs
							replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
							errorHandler:(nonnull void (^)(NSError *error))errorHandler {
	
	static int attempts = 0;
	
	if(self.session.reachable){
		NSDictionary *messageDictionary = @{
											LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyBrowsingShuffleAll,
											LMAppleWatchBrowsingKeyMusicTypes: musicTypes,
											LMAppleWatchBrowsingKeyPersistentIDs: persistentIDs,
											LMAppleWatchBrowsingKeySelectedIndexes: selectedIndexes,
											LMAppleWatchBrowsingKeyPageIndexes: pageIndexes
											};
		
		[self.session sendMessage:messageDictionary
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 attempts = 0;
						 replyHandler(replyMessage);
					 } errorHandler:^(NSError * _Nonnull error) {
						 attempts++;
						 if(attempts < 3){
							 [self shuffleTracksWithSelectedIndexes:selectedIndexes
													withPageIndexes:pageIndexes
													  forMusicTypes:musicTypes
												  withPersistentIDs:persistentIDs
													   replyHandler:replyHandler
													   errorHandler:errorHandler];
						 }
						 else{
							 attempts = 0;
							 errorHandler(error);
						 }
					 }];
	}
	else if(attempts < 3){
		attempts++;
		
		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self shuffleTracksWithSelectedIndexes:selectedIndexes
								   withPageIndexes:pageIndexes
									 forMusicTypes:musicTypes
								 withPersistentIDs:persistentIDs
									  replyHandler:replyHandler
									  errorHandler:errorHandler];
		}];
	}
	else if(attempts >= 3){
		NSError *notReplyingError = [NSError errorWithDomain:@"Phone isn't replying"
														code:503
													userInfo:nil];
		errorHandler(notReplyingError);
		
		attempts = 0;
	}
}

- (void)playSpecificTrackWithSelectedIndexes:(NSArray<NSNumber*>*)selectedIndexes
							 withPageIndexes:(NSArray<NSNumber*>*)pageIndexes
							   forMusicTypes:(NSArray<NSNumber*>*)musicTypes
						   withPersistentIDs:(NSArray<NSNumber*>*)persistentIDs
								replyHandler:(nonnull void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
								errorHandler:(nonnull void (^)(NSError *error))errorHandler {
	
	
	static int attempts = 0;
	
	if(self.session.reachable){
		NSDictionary *messageDictionary = @{
											LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyBrowsingPlayIndividualTrack,
											LMAppleWatchBrowsingKeyMusicTypes: musicTypes,
											LMAppleWatchBrowsingKeyPersistentIDs: persistentIDs,
											LMAppleWatchBrowsingKeySelectedIndexes: selectedIndexes,
											LMAppleWatchBrowsingKeyPageIndexes: pageIndexes
											};
		
		[self.session sendMessage:messageDictionary
					 replyHandler:replyHandler
					 errorHandler:errorHandler];
	}
	else if(attempts < 3){
		attempts++;
		
		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self playSpecificTrackWithSelectedIndexes:selectedIndexes
								   withPageIndexes:pageIndexes
									 forMusicTypes:musicTypes
								 withPersistentIDs:persistentIDs
									  replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
										  attempts = 0;
										  replyHandler(replyMessage);
										  NSLog(@"Noice");
									  } errorHandler:^(NSError * _Nonnull error) {
										  attempts++;
										  if(attempts < 3){
											  NSLog(@"Error fetching. Trying again: %@", error);
											  
											  [self playSpecificTrackWithSelectedIndexes:selectedIndexes
																	 withPageIndexes:pageIndexes
																	   forMusicTypes:musicTypes
																   withPersistentIDs:persistentIDs
																		replyHandler:replyHandler
																		errorHandler:errorHandler];
										  }
										  else{
											  attempts = 0;
											  errorHandler(error);
											  
											  NSLog(@"Errors are too much, sorry %@", error);
										  }
									  }];
		}];
	}
	else if(attempts >= 3){
		NSError *notReplyingError = [NSError errorWithDomain:@"Phone isn't replying"
														code:503
													userInfo:nil];
		errorHandler(notReplyingError);
		
		attempts = 0;
	}
}

- (void)setCurrentPlaybackTime:(NSInteger)currentPlaybackTime
				successHandler:(nullable void (^)(NSDictionary *response))successHandler
				  errorHandler:(nullable void (^)(NSError *error))errorHandler {
	
	if(self.session.reachable){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchControlKeyCurrentPlaybackTime,
									LMAppleWatchControlKeyCurrentPlaybackTime:@(currentPlaybackTime)
									 }
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 dispatch_async(dispatch_get_main_queue(), ^{
							 successHandler(replyMessage);
						 });
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						 dispatch_async(dispatch_get_main_queue(), ^{
							 errorHandler(error);
						 });
					 }
		 ];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			NSError *notRespondingError = [NSError errorWithDomain:@"The phone is not responding"
															  code:503
														  userInfo:nil];
			
			errorHandler(notRespondingError);
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
