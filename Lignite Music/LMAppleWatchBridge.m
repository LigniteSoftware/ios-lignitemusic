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
	
	if(self.session.reachable){
		[self.session sendMessageData:imageData replyHandler:/*^(NSData * _Nonnull replyMessageData) {
															  
															  NSLog(@"Reply got");
															  }*/nil errorHandler:^(NSError * _Nonnull error) {
																  
																  NSLog(@"Error sending %@", error);
															  }];
	}
}

- (void)sendNowPlayingTrackToWatch {
	LMMusicTrack *nowPlayingTrack = self.musicPlayer.nowPlayingTrack;
	
	BOOL albumArtIsTheSame = (self.previousNowPlayingTrackSent.persistentID == nowPlayingTrack.persistentID)
	|| (self.previousNowPlayingTrackSent.albumPersistentID == nowPlayingTrack.albumPersistentID);
	
	if(self.session.reachable){
		if(nowPlayingTrack){
			if(self.previousNowPlayingTrackSent.persistentID == nowPlayingTrack.persistentID){
				NSLog(@"Same same, rejecting");
				return;
			}
			self.previousNowPlayingTrackSent = nowPlayingTrack;
			
			NSDictionary *nowPlayingTrackDictionary = @{
												   LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingTrack,
												   
												   LMAppleWatchCommunicationKeyNowPlayingTrack:[self dictionaryForMusicTrack:nowPlayingTrack]
												   };

			[self.session sendMessage:nowPlayingTrackDictionary
						 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
							 NSLog(@"Got a reply: %@", replyMessage);
						 }*/
						 errorHandler:^(NSError * _Nonnull error) {
							 NSLog(@"Error sending now playing track: %@", error);
						 }];
			
			if(!albumArtIsTheSame){
				[self sendNowPlayingAlbumArtToWatch];
			}
			
			[self sendNowPlayingInfoToWatch];
			[self sendUpNextToWatch];
		}
		else{
			[self.session sendMessage:@{ LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNoTrackPlaying } replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
				NSLog(@"Error sending no track currently playing: %@", error);
			}];
		}
	}
}

- (void)sendNowPlayingInfoToWatch {
	NSDictionary *nowPlayingInfoDictionary = @{
											   LMAppleWatchNowPlayingInfoKeyIsPlaying: @(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying),
											   LMAppleWatchNowPlayingInfoKeyRepeatMode: @(self.musicPlayer.repeatMode),
											   LMAppleWatchNowPlayingInfoKeyShuffleMode: @(self.musicPlayer.shuffleMode),
											   LMAppleWatchNowPlayingInfoKeyPlaybackDuration: @(self.musicPlayer.nowPlayingTrack.playbackDuration),
											   LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime: @(self.musicPlayer.currentPlaybackTime)
											   };
	
	NSDictionary *messageDictionary = @{
										   LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingInfo,
										   
										   LMAppleWatchCommunicationKeyNowPlayingInfo:nowPlayingInfoDictionary
										   };
	
	if(self.session.reachable){
		[self.session sendMessage:messageDictionary
					 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
									  NSLog(@"Got a reply: %@", replyMessage);
									  }*/
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error sending now playing track: %@", error);
					 }];
	}
}

- (void)sendUpNextToWatch {
	if(self.session.reachable){
		LMMusicTrackCollection *nowPlayingQueue = self.musicPlayer.nowPlayingCollection;
		if(!nowPlayingQueue || nowPlayingQueue.count == 0 || nowPlayingQueue.count == 1){
			NSLog(@"Now playing queue doesn't exist or has no or 1 song in it, rejecting");
			return;
		}
		
		NSMutableArray *upNextMutableArray = [NSMutableArray new];
		NSInteger indexOfNowPlayingTrack = self.musicPlayer.indexOfNowPlayingTrack;
		
		NSArray *tracksRemainingAfterNowPlayingTrack = [nowPlayingQueue.items subarrayWithRange:NSMakeRange(indexOfNowPlayingTrack + 1, MIN(nowPlayingQueue.count-indexOfNowPlayingTrack-1, 5))];
	
		for(LMMusicTrack *track in tracksRemainingAfterNowPlayingTrack){
			NSDictionary *trackInfoDictionary = @{
												  @"title": track.title,
												  @"subtitle": track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil),
												  @"persistentID": @(track.persistentID),
												  @"indexInCollection": @([nowPlayingQueue.items indexOfObject:track]),
												  };
			[upNextMutableArray addObject:trackInfoDictionary];
		}
		
		NSLog(@"Got %d tracks up next", tracksRemainingAfterNowPlayingTrack.count);
		
		
		
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue,
									LMAppleWatchCommunicationKeyUpNextOnNowPlayingQueue: [NSArray arrayWithArray:upNextMutableArray]
									}
					 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
									  NSLog(@"Got a reply: %@", replyMessage);
									  }*/
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error sending up next: %@", error);
					 }];
	}
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
	
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
   replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
	
	NSString *key = [message objectForKey:LMAppleWatchCommunicationKey];
	
	if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingTrack]){
		[self sendNowPlayingTrackToWatch];
		
		replyHandler(@{ @"sent":@"pimp" });
	}
	else if([key isEqualToString:LMAppleWatchCommunicationKeyMusicBrowsingEntries]){
		LMMusicType musicType = (LMMusicType)[[message objectForKey:LMAppleWatchBrowsingKeyMusicType] integerValue];
		MPMediaEntityPersistentID persistentID = (MPMediaEntityPersistentID)[[message objectForKey:LMAppleWatchBrowsingKeyPersistentID] integerValue];
		NSInteger currentIndex = [[message objectForKey:LMAppleWatchBrowsingKeyCurrentIndex] integerValue];
		
		BOOL isBeginningOfBrowse = (persistentID == 0 && currentIndex == -1);
		
		NSInteger MAXIMUM_NUMBER_OF_ITEMS_IN_LIST = 15;
		
		if(currentIndex == -1){ //First page
			currentIndex = 0;
		}
		else{
			currentIndex += (currentIndex/MAXIMUM_NUMBER_OF_ITEMS_IN_LIST) + 1;
		}
		
		NSLog(@"Got a request for music tracks. Is beginning? %d", isBeginningOfBrowse);

		NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer queryCollectionsForMusicType:musicType];
		if(musicType == LMMusicTypeTitles){
			trackCollections = [LMMusicPlayer
								arrayOfTrackCollectionsForMusicTrackCollection:trackCollections.firstObject];
		}
		NSMutableArray *resultsArray = [NSMutableArray new];
	
		NSInteger maximumIndex = currentIndex + MIN(MAXIMUM_NUMBER_OF_ITEMS_IN_LIST, trackCollections.count-currentIndex);
		//If there's only a few items left, might as well add them to  the current page instead of making the user go to another page for them
		if(((trackCollections.count-maximumIndex) <= 5) && ((trackCollections.count-maximumIndex) > 0)){
			maximumIndex = trackCollections.count;
		}
	
		for(NSInteger i = currentIndex; i < maximumIndex; i++){
			LMMusicTrackCollection *collection = [trackCollections objectAtIndex:i];
			LMMusicTrack *representativeTrack = collection.representativeItem;
			
			NSString *title = NSLocalizedString(@"UnknownTitle", nil);
			NSString *subtitle = NSLocalizedString(@"UnknownArtist", nil);
			
			UIImage *imageToUse = representativeTrack.albumArt;
			if(musicType == LMMusicTypeArtists || musicType == LMMusicTypeComposers){
				imageToUse = representativeTrack.uncorrectedArtistImage;
			}
			
			UIImage *resizedImage = [self resizeImage:imageToUse toSize:CGSizeMake(64, 64)];
			NSData *iconData = resizedImage ? UIImageJPEGRepresentation(resizedImage, 0.5) : nil;
			
			NSLog(@"Size %d", (int)iconData.length);
			
			switch(musicType){
				case LMMusicTypeTitles:
					title = representativeTrack.title ? representativeTrack.title : NSLocalizedString(@"UnknownTitle", nil);
					subtitle = representativeTrack.artist ? representativeTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
					break;
				case LMMusicTypeCompilations:
				case LMMusicTypeAlbums:
					title = representativeTrack.albumTitle ? representativeTrack.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
					subtitle = representativeTrack.albumArtist ? representativeTrack.albumArtist : NSLocalizedString(@"UnknownArtist", nil);
					break;
				case LMMusicTypeComposers:
				case LMMusicTypeArtists:
					title = representativeTrack.artist ? representativeTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
					subtitle = [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
					break;
				case LMMusicTypePlaylists:
					title = @"Error";
					subtitle = [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
				default:
					break;
			}
			
			[resultsArray addObject:iconData
								   ? @{
									 LMAppleWatchBrowsingKeyEntryPersistentID: @(representativeTrack.albumPersistentID),
									 LMAppleWatchBrowsingKeyEntryTitle: title,
									 LMAppleWatchBrowsingKeyEntrySubtitle: subtitle,
									 LMAppleWatchBrowsingKeyEntryIcon: iconData
									 }
								   : @{
									  LMAppleWatchBrowsingKeyEntryPersistentID: @(representativeTrack.albumPersistentID),
									  LMAppleWatchBrowsingKeyEntryTitle: title,
									  LMAppleWatchBrowsingKeyEntrySubtitle: subtitle
									  }];
		}
		
		
		BOOL isEndOfList = (maximumIndex == trackCollections.count);
		
		NSLog(@"Results %@\n%d %d/%d", resultsArray, isEndOfList, (int)maximumIndex, (int)trackCollections.count);
		
		replyHandler(@{
					   @"results": resultsArray,
					   LMAppleWatchBrowsingKeyIsBeginningOfList: @(isBeginningOfBrowse),
					   LMAppleWatchBrowsingKeyIsEndOfList: @(isEndOfList),
					   LMAppleWatchBrowsingKeyRemainingEntries: @(trackCollections.count - maximumIndex)
					   });
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if([key isEqualToString:LMAppleWatchControlKeyPlayPause]){
			[self.musicPlayer invertPlaybackState];
		}
		else if([key isEqualToString:LMAppleWatchControlKeyNextTrack]){
			[self.musicPlayer skipToNextTrack];
		}
		else if([key isEqualToString:LMAppleWatchControlKeyPreviousTrack]){
			[self.musicPlayer skipToPreviousItem];
		}
		else if([key isEqualToString:LMAppleWatchControlKeyFavouriteUnfavourite]){
			if(self.musicPlayer.nowPlayingTrack.isFavourite){
				[self.musicPlayer removeTrackFromFavourites:self.musicPlayer.nowPlayingTrack];
			}
			else{
				[self.musicPlayer addTrackToFavourites:self.musicPlayer.nowPlayingTrack];
			}
		}
		else if([key isEqualToString:LMAppleWatchControlKeyInvertShuffleMode]){
			self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
		}
		else if([key isEqualToString:LMAppleWatchControlKeyNextRepeatMode]){
			LMMusicRepeatMode newRepeatMode = self.musicPlayer.repeatMode;
			if(self.musicPlayer.repeatMode == LMMusicRepeatModeNone){
				newRepeatMode = LMMusicRepeatModeAll;
			}
			else if(self.musicPlayer.repeatMode == LMMusicRepeatModeAll){
				newRepeatMode = LMMusicRepeatModeOne;
			}
			else{
				newRepeatMode = LMMusicRepeatModeNone;
			}
			self.musicPlayer.repeatMode = newRepeatMode;
		}
		else if([key isEqualToString:LMAppleWatchControlKeyUpNextTrackSelected]){
			NSInteger nowPlayingQueueIndex = [[message objectForKey:LMAppleWatchControlKeyUpNextTrackSelected] integerValue];
			LMMusicTrack *trackSelected = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:nowPlayingQueueIndex];
			[self.musicPlayer setNowPlayingTrack:trackSelected];
		}
		else if([key isEqualToString:LMAppleWatchControlKeyCurrentPlaybackTime]){
			NSInteger currentPlaybackTime = [[message objectForKey:LMAppleWatchControlKeyCurrentPlaybackTime] integerValue];
			[self.musicPlayer setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime];
		}
	});
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
