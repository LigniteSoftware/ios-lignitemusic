//
//  LMAppleWatchBridge.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "LMAppleWatchBridge.h"
#import "LMMusicPlayer.h"

@interface LMAppleWatchBridge()<WCSessionDelegate>

/**
 The watch connectivity session.
 */
@property WCSession *session;

/**
 The music player.
 */
@property (readonly) LMMusicPlayer *musicPlayer;

/**
 The last track that was sent. Stored to prevent double sending to conserve data transfer.
 */
@property LMMusicTrack *previousNowPlayingTrackSent;

@end

@implementation LMAppleWatchBridge

@synthesize musicPlayer = _musicPlayer;

- (LMMusicPlayer*)musicPlayer {
	return [LMMusicPlayer sharedMusicPlayer];
}

- (NSDictionary*)dictionaryForMusicTrack:(LMMusicTrack*)musicTrack {
	NSMutableDictionary *mutableMusicTrackDictionary = [NSMutableDictionary new];
	
	[mutableMusicTrackDictionary setObject:musicTrack.title
	 										? musicTrack.title
										  	: NSLocalizedString(@"UnknownTitle", nil)
									forKey:LMAppleWatchMusicTrackInfoKeyTitle];
		
	[mutableMusicTrackDictionary setObject:musicTrack.artist
	 										? musicTrack.artist
										  	: NSLocalizedString(@"UnknownArtist", nil)
									forKey:LMAppleWatchMusicTrackInfoKeySubtitle];
	
	[mutableMusicTrackDictionary setObject:@(musicTrack.playbackDuration)
									forKey:LMAppleWatchMusicTrackInfoKeyPlaybackDuration];
	
	[mutableMusicTrackDictionary setObject:@(self.musicPlayer.currentPlaybackTime)
									forKey:LMAppleWatchMusicTrackInfoKeyCurrentPlaybackTime];
	
	[mutableMusicTrackDictionary setObject:@(musicTrack.isFavourite)
									forKey:LMAppleWatchMusicTrackInfoKeyIsFavourite];
	
	[mutableMusicTrackDictionary setObject:@(musicTrack.persistentID)
									forKey:LMAppleWatchMusicTrackInfoKeyPersistentID];
	
	[mutableMusicTrackDictionary setObject:@(musicTrack.albumPersistentID)
									forKey:LMAppleWatchMusicTrackInfoKeyAlbumPersistentID];
	
	return [NSDictionary dictionaryWithDictionary:mutableMusicTrackDictionary];
}

- (UIImage*)resizeImage:(UIImage*)orginalImage toSize:(CGSize)size {
	CGFloat actualHeight = orginalImage.size.height;
	CGFloat actualWidth = orginalImage.size.width;
	
	CGFloat oldRatio = actualWidth/actualHeight;
	CGFloat newRatio = size.width/size.height;
	
	if(oldRatio < newRatio){
		oldRatio = size.height/actualHeight;
		actualWidth = oldRatio * actualWidth;
		actualHeight = size.height;
	}
	else {
		oldRatio = size.width/actualWidth;
		actualHeight = oldRatio * actualHeight;
		actualWidth = size.width;
	}
	
	CGRect rect = CGRectMake(0.0,0.0,actualWidth,actualHeight);
	
	UIGraphicsBeginImageContext(rect.size);
	[orginalImage drawInRect:rect];
	orginalImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return orginalImage;
}

- (NSData*)compressImageForThreshhold:(UIImage*)image {
	UIImage *sendingImage = image;
	
	CGFloat compressionFactor = 1.0;
	NSData *imageData = UIImageJPEGRepresentation(sendingImage, compressionFactor);
	while(imageData.length > 61000 && compressionFactor > 0.0){
		compressionFactor -= (compressionFactor < 0.10) ? 0.01 : 0.05;
		if(compressionFactor < 0){ //After a round of compression, the image is still too large. Let's cut its size in half and then try the same loop.
			compressionFactor = 0.1;
			sendingImage = [self resizeImage:[UIImage imageWithData:imageData] toSize:CGSizeMake(sendingImage.size.width/2.0, sendingImage.size.height/2.0)];
		}
		else{
			imageData = UIImageJPEGRepresentation(sendingImage, compressionFactor);
		}
	}
	return imageData;
}

- (void)sendNowPlayingAlbumArtToWatch {
	UIImage *image = self.musicPlayer.nowPlayingTrack.albumArt;
	
	CGFloat compressionFactor = 1.0;
	
	NSData *imageData = [self compressImageForThreshhold:image];
	
	NSLog(@"Image is %lu bytes with a compression factor of %f.", imageData.length, compressionFactor);
	
	[self.session sendMessageData:imageData replyHandler:/*^(NSData * _Nonnull replyMessageData) {
														  
														  NSLog(@"Reply got");
														  }*/nil errorHandler:^(NSError * _Nonnull error) {
															  
															  NSLog(@"Error sending %@", error);
														  }];
}

- (void)sendNowPlayingTrackInfoToWatch {
	LMMusicTrack *nowPlayingTrack = self.musicPlayer.nowPlayingTrack;
	
	BOOL albumArtIsTheSame = (self.previousNowPlayingTrackSent.persistentID == nowPlayingTrack.persistentID)
	|| (self.previousNowPlayingTrackSent.albumPersistentID == nowPlayingTrack.albumPersistentID);
	
	if(self.session.reachable){
		NSDictionary *nowPlayingDictionary = @{
											   LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingTrack,
											   
											   LMAppleWatchCommunicationKeyNowPlayingTrack:[self dictionaryForMusicTrack:nowPlayingTrack]
											   };

		[self.session sendMessage:nowPlayingDictionary
					 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 NSLog(@"Got a reply: %@", replyMessage);
					 }*/
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error sending now playing track: %@", error);
					 }];
		
		if(!albumArtIsTheSame){
			[self sendNowPlayingAlbumArtToWatch];
		}
		
		self.previousNowPlayingTrackSent = nowPlayingTrack;
	}
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
	
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
	
	NSString *key = [message objectForKey:LMAppleWatchCommunicationKey];
	
	if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingTrack]){
		[self sendNowPlayingTrackInfoToWatch];
		
		replyHandler(@{ @"sent":@"pimp" });
	}
}

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
	
	NSLog(@"Connected %d with error %@", (int)activationState, error.description);
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
	NSLog(@"Session became inactive");
}

- (void)sessionDidDeactivate:(WCSession *)session {
	NSLog(@"Session did deactivate");
}

+ (LMAppleWatchBridge*)sharedAppleWatchBridge {
	static LMAppleWatchBridge *sharedAppleWatchBridge;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedAppleWatchBridge = [self new];
		
		if ([WCSession isSupported]) {
			sharedAppleWatchBridge.session = [WCSession defaultSession];
			sharedAppleWatchBridge.session.delegate = sharedAppleWatchBridge;
			[sharedAppleWatchBridge.session activateSession];
		}
	});
	return sharedAppleWatchBridge;
}

BOOL done = NO;

- (void)test {
	return;
	
	if ([WCSession isSupported]) {
		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
			if(self.session.reachable){
				if(done){
					return;
				}
				done = YES;
				
				NSLog(@"Sending!");
				
//				[self.session sendMessage:@{ @"title":[NSString stringWithFormat:@"%ld", random()] } replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
//
//					NSLog(@"Got reply message %@", replyMessage);
//
//				} errorHandler:^(NSError * _Nonnull error) {
//
//					NSLog(@"Sent with error %@", error);
//				}];
				
				UIImage *image = [[[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums] firstObject].representativeItem.albumArt;

				NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
				
				NSLog(@"Image is %lu bytes.", imageData.length);
				
				[self.session sendMessageData:imageData replyHandler:/*^(NSData * _Nonnull replyMessageData) {
					
					NSLog(@"Reply got");
				}*/nil errorHandler:^(NSError * _Nonnull error) {
					
					NSLog(@"Error sending %@", error);
				}];
			
			}
			else{
				NSLog(@"Not reachable :(");
			}
		}];
	}
}

@end
