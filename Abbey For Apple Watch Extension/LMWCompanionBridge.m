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

/**
 The now playing track.
 */
@property LMWMusicTrackInfo *nowPlayingTrack;

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
		
		UIImage *previousAlbumArt = self.nowPlayingTrack.albumArt;
		
		LMWMusicTrackInfo *trackInfo = [LMWMusicTrackInfo new];
		trackInfo.title = [trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyTitle];
		trackInfo.subtitle = [trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeySubtitle];
		trackInfo.isFavourite = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyIsFavourite] boolValue];
		trackInfo.playbackDuration = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyPlaybackDuration] integerValue];
		trackInfo.persistentID = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyPersistentID] longLongValue];
		trackInfo.albumPersistentID = [[trackDictionary objectForKey:LMAppleWatchMusicTrackInfoKeyAlbumPersistentID] longLongValue];
		
		if(trackInfo.persistentID == self.nowPlayingTrack.persistentID
		   || trackInfo.albumPersistentID == self.nowPlayingTrack.albumPersistentID){
			trackInfo.albumArt = previousAlbumArt;
		}
		
		self.nowPlayingTrack = trackInfo;
		
		for(id<LMWCompanionBridgeDelegate> delegate in self.delegates){
			if([delegate respondsToSelector:@selector(musicTrackDidChange:)]){
				[delegate musicTrackDidChange:trackInfo];
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
	
	self.nowPlayingTrack.albumArt = image;
	
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
		[self debug:@"not yet"];
		[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self askCompanionForNowPlayingTrackInfo];
			[self debug:@"again"];
		}];
	}
}


- (void)addDelegate:(id<LMWCompanionBridgeDelegate>)delegate {
	[self.delegates addObject:delegate];
	
	LMWMusicTrackInfo *trackInfo = [[LMWMusicTrackInfo alloc]init];
	trackInfo.title = @"delegate added";
	trackInfo.subtitle = [NSString stringWithFormat:@"%p", delegate];
	[delegate musicTrackDidChange:trackInfo];
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
		
		if ([WCSession isSupported]) {
			sharedCompanionBridge.session = [WCSession defaultSession];
			sharedCompanionBridge.session.delegate = sharedCompanionBridge;
			[sharedCompanionBridge.session activateSession];
		}
	});
	return sharedCompanionBridge;
}

@end
