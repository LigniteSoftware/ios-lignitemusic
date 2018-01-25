//
//  LMAppleWatchBridge.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "LMAppleWatchBridge.h"
#import "LMPlaylistManager.h"
#import "NSTimer+Blocks.h"
#import "LMMusicPlayer.h"
#import "LMThemeEngine.h"
#import "LMAnswers.h"

@interface LMAppleWatchBridge()<WCSessionDelegate, LMMusicPlayerDelegate, LMThemeEngineDelegate>

/**
 The watch connectivity session.
 */
@property WCSession *session;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The last track that was sent. Stored to prevent double sending to conserve data transfer.
 */
@property LMMusicTrack *previousNowPlayingTrackSent;

/**
 The track of the previous sent album art.
 */
@property LMMusicTrack *previousTrackOfAlbumArtSent;

/**
 The previous shuffle mode that up next was sent for.
 */
@property LMMusicShuffleMode previousShuffleMode;

//For volume control
@property MPVolumeView *volumeView;
@property UISlider *volumeViewSlider;

@end

@implementation LMAppleWatchBridge

@synthesize musicPlayer = _musicPlayer;

- (LMMusicPlayer*)musicPlayer {
	static BOOL hasRegisteredAsMusicPlayerDelegate;
	
	if(LMMusicPlayer.onboardingComplete && !hasRegisteredAsMusicPlayerDelegate){
		_musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[_musicPlayer addMusicDelegate:self];
		
		hasRegisteredAsMusicPlayerDelegate = YES;
	}
	
	return _musicPlayer;
}

- (void)setMusicPlayer:(LMMusicPlayer *)musicPlayer {
	_musicPlayer = musicPlayer;
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self sendNowPlayingTrackToWatch];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	if(self.connected){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingInfoUpdate,
									LMAppleWatchCommunicationKeyNowPlayingInfoUpdate: LMAppleWatchNowPlayingInfoKeyIsPlaying,
									LMAppleWatchNowPlayingInfoKeyIsPlaying: @(newState == LMMusicPlaybackStatePlaying)
									}
					 replyHandler:nil
					 errorHandler:nil];
	}
}

- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime userModified:(BOOL)userModified {
	if(self.connected && userModified){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingInfoUpdate,
									LMAppleWatchCommunicationKeyNowPlayingInfoUpdate: LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime,
									LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime: @(newPlaybackTime),
									LMAppleWatchMusicTrackInfoKeyPlaybackDuration: @(self.musicPlayer.nowPlayingTrack.playbackDuration)
									}
					 replyHandler:nil
					 errorHandler:nil];
	}
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	if(self.connected){
		if(shuffleMode != self.previousShuffleMode){
			[self sendUpNextToWatch];
		}
		
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingInfoUpdate,
									LMAppleWatchCommunicationKeyNowPlayingInfoUpdate: LMAppleWatchNowPlayingInfoKeyShuffleMode,
									LMAppleWatchNowPlayingInfoKeyShuffleMode: @(shuffleMode),
									LMAppleWatchNowPlayingInfoKeyRepeatMode: @(repeatMode)
									}
					 replyHandler:nil
					 errorHandler:nil
		 ];
	}
}

- (void)trackAddedToQueue:(LMMusicTrack*)trackAdded {
	[self sendUpNextToWatch];
}

- (void)trackRemovedFromQueue:(LMMusicTrack*)trackRemoved {
	[self sendUpNextToWatch];
}

- (void)trackMovedInQueue:(LMMusicTrack*)trackMoved {
	[self sendUpNextToWatch];
}

- (void)trackAddedToFavourites:(LMMusicTrack*)track {
	if(self.connected){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingTrackUpdate,
									LMAppleWatchCommunicationKeyNowPlayingTrackUpdate: LMAppleWatchMusicTrackInfoKeyIsFavourite,
									LMAppleWatchMusicTrackInfoKeyIsFavourite: @(track.isFavourite)
									}
					 replyHandler:nil
					 errorHandler:nil
		 ];
	}
}

- (void)trackRemovedFromFavourites:(LMMusicTrack*)track {
	if(self.connected){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingTrackUpdate,
									LMAppleWatchCommunicationKeyNowPlayingTrackUpdate: LMAppleWatchMusicTrackInfoKeyIsFavourite,
									LMAppleWatchMusicTrackInfoKeyIsFavourite: @(track.isFavourite)
									}
					 replyHandler:nil
					 errorHandler:nil
		 ];
	}
}

- (void)themeChanged:(LMTheme)theme {
	if(self.connected){
		[self.session sendMessage:@{
									LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingInfoUpdate,
									LMAppleWatchCommunicationKeyNowPlayingInfoUpdate: LMAppleWatchNowPlayingInfoKeyTheme,
									LMAppleWatchNowPlayingInfoKeyTheme: [LMThemeEngine mainColourHexStringForTheme:theme]
									}
					 replyHandler:nil
					 errorHandler:nil];
	}
}

- (BOOL)connected {
	return self.session.reachable && LMMusicPlayer.onboardingComplete;
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
	LMMusicTrack *nowPlayingTrack = self.musicPlayer.nowPlayingTrack;
	
	//It's the same if the track is the same or if the album & artist has not changed
	BOOL albumArtIsTheSame = (self.previousTrackOfAlbumArtSent.persistentID == nowPlayingTrack.persistentID)
	|| ((self.previousTrackOfAlbumArtSent.albumPersistentID == nowPlayingTrack.albumPersistentID) && (self.previousTrackOfAlbumArtSent.artistPersistentID == nowPlayingTrack.artistPersistentID));
	
	if(albumArtIsTheSame){
		return;
	}
	
	UIImage *image = nowPlayingTrack.albumArt;
	
	CGFloat compressionFactor = 1.0;
	
	NSData *imageData = [self compressImageForThreshhold:image];
	
	NSLog(@"Image is %lu bytes with a compression factor of %f.", imageData.length, compressionFactor);
	
	if(self.connected){
		[self.session sendMessageData:imageData
						 replyHandler:^(NSData * _Nonnull replyMessageData) {
							NSLog(@"Reply got, the watch sucessfully got the image!");
							self.previousTrackOfAlbumArtSent = self.musicPlayer.nowPlayingTrack;
						 }
						 errorHandler:^(NSError * _Nonnull error) {
							NSLog(@"Error sending %@", error);
						 }];
	}
}

- (void)sendOnboardingStatusToWatch {
	if(self.connected){
		[self.session sendMessage:@{ 
									LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyOnboardingComplete,
									LMAppleWatchCommunicationKeyOnboardingComplete: @(LMMusicPlayer.onboardingComplete)
									}
					 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
						 NSLog(@"Got reply %@", replyMessage);
					 }
					 errorHandler:^(NSError * _Nonnull error) {
						 NSLog(@"Error sending onboarding status: %@", error);
					 }];
	}
}

- (void)sendNowPlayingTrackToWatch {
	[self sendNowPlayingTrackToWatch:NO];
}

- (void)sendNowPlayingTrackToWatch:(BOOL)overrideDoubleSending {
	LMMusicTrack *nowPlayingTrack = self.musicPlayer.nowPlayingTrack;
	
	if(self.connected){
		if(nowPlayingTrack){
			if((self.previousNowPlayingTrackSent.persistentID == nowPlayingTrack.persistentID) && !overrideDoubleSending){
				NSLog(@"Same same, rejecting");
				return;
			}
			self.previousNowPlayingTrackSent = nowPlayingTrack;
			
			NSDictionary *nowPlayingTrackDictionary = @{
												   LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingTrack,
												   LMAppleWatchNowPlayingInfoKeyTheme: [LMThemeEngine mainColourHexStringForTheme:LMThemeEngine.currentTheme],
												   LMAppleWatchCommunicationKeyNowPlayingTrack:[self dictionaryForMusicTrack:nowPlayingTrack]
												   };

			[self.session sendMessage:nowPlayingTrackDictionary
						 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
							 NSLog(@"Got a reply: %@", replyMessage);
						 }*/
						 errorHandler:^(NSError * _Nonnull error) {
							 NSLog(@"Error sending now playing track: %@", error);
						 }];
			
//			if(!albumArtIsTheSame){
				[self sendNowPlayingAlbumArtToWatch];
//			}
			
//			if(!overrideDoubleSending){
				[self sendNowPlayingInfoToWatch];
				[self sendUpNextToWatch];
//			}
		}
		else{
			[self.session sendMessage:@{
										LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNoTrackPlaying,
										LMAppleWatchNowPlayingInfoKeyTheme: [LMThemeEngine mainColourHexStringForTheme:LMThemeEngine.currentTheme]
										}
						 replyHandler:nil
						 errorHandler:^(NSError * _Nonnull error) {
							 NSLog(@"Error sending no track currently playing: %@", error);
						 }
			 ];
		}
	}
}

- (void)sendNowPlayingInfoToWatch {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSDictionary *nowPlayingInfoDictionary = @{
												   LMAppleWatchNowPlayingInfoKeyIsPlaying: @(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying),
												   LMAppleWatchNowPlayingInfoKeyRepeatMode: @(self.musicPlayer.repeatMode),
												   LMAppleWatchNowPlayingInfoKeyShuffleMode: @(self.musicPlayer.shuffleMode),
												   LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime: @(self.musicPlayer.currentPlaybackTime),
												   LMAppleWatchNowPlayingInfoKeyVolume: @(self.volumeViewSlider.value),
												   LMAppleWatchNowPlayingInfoKeyTheme: [LMThemeEngine mainColourHexStringForTheme:LMThemeEngine.currentTheme]
												   };
		
		NSDictionary *messageDictionary = @{
											LMAppleWatchCommunicationKey: LMAppleWatchCommunicationKeyNowPlayingInfo,
											LMAppleWatchCommunicationKeyNowPlayingInfo:nowPlayingInfoDictionary
											};
		
		if(self.connected){
			[self.session sendMessage:messageDictionary
						 replyHandler:nil/* ^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
										  NSLog(@"Got a reply: %@", replyMessage);
										  }*/
						 errorHandler:^(NSError * _Nonnull error) {
							 NSLog(@"Error sending now playing track: %@", error);
						 }];
		}
	});
}

- (void)sendUpNextToWatch {
	if(self.connected){
		LMMusicTrackCollection *nowPlayingQueue = self.musicPlayer.nowPlayingCollection;
		if(!nowPlayingQueue){
			NSLog(@"Now playing queue doesn't exist, rejecting");
			return;
		}
		
		NSMutableArray *upNextMutableArray = [NSMutableArray new];
		NSInteger indexOfNowPlayingTrack = self.musicPlayer.indexOfNowPlayingTrack;
		
		if(!(nowPlayingQueue.count == 0 || nowPlayingQueue.count == 1)){
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
			
			NSLog(@"Got %d tracks up next", (int)tracksRemainingAfterNowPlayingTrack.count);
		}
		
		self.previousShuffleMode = self.musicPlayer.shuffleMode;
		
		
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
	NSLog(@"[LMAppleWatchBridge]: Unexpectedly got message: %@", message);
}

- (NSArray<LMMusicTrackCollection*>*)trackCollectionsForBrowsingDictionary:(NSDictionary*)browsingDictionary {
	NSArray<NSNumber*> *musicTypes = [browsingDictionary objectForKey:LMAppleWatchBrowsingKeyMusicTypes];
	NSArray<NSNumber*> *persistentIDs = [browsingDictionary objectForKey:LMAppleWatchBrowsingKeyPersistentIDs];
	NSArray<NSNumber*> *selectedIndexes = [browsingDictionary objectForKey:LMAppleWatchBrowsingKeySelectedIndexes];
	
	BOOL isInitialBrowsePage = (musicTypes.count == 1);
	
	NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer queryCollectionsForMusicType:(LMMusicType)musicTypes.firstObject.integerValue];
	
	if(!isInitialBrowsePage){
		for(NSInteger i = 1; i < selectedIndexes.count; i++){
			if(i == 1){
				LMMusicType subMusicType = (LMMusicType)[[musicTypes objectAtIndex:i - 1] integerValue];
				MPMediaEntityPersistentID subPersistentID = (MPMediaEntityPersistentID)[[persistentIDs objectAtIndex:i] longLongValue];
				
				if(subMusicType == LMMusicTypePlaylists){
					LMPlaylist *playlist = [[LMPlaylistManager sharedPlaylistManager] playlistForPersistentID:subPersistentID];
					trackCollections = @[ playlist.trackCollection ];
				}
				else{
					trackCollections = [self.musicPlayer collectionsForWatchForPersistentID:subPersistentID
																			   forMusicType:subMusicType];
				}
			}
			else if(i == 2){ //Always titles
				MPMediaEntityPersistentID selectedAlbumPersistentID = [[persistentIDs objectAtIndex:i] longLongValue];
				for(LMMusicTrackCollection *trackCollection in trackCollections){
					if(trackCollection.representativeItem.albumPersistentID == selectedAlbumPersistentID){
						trackCollections = @[ trackCollection ];
					}
				}
			}
			else{
				NSAssert(false, @"NSInteger i can't be past two when tree searching, sorry");
			}
		}
	}
	
	return trackCollections;
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
   replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
	
	NSString *key = [message objectForKey:LMAppleWatchCommunicationKey];
	
	if([key isEqualToString:LMAppleWatchCommunicationKeyNowPlayingTrack]){
		replyHandler(@{ LMAppleWatchCommunicationKeyOnboardingComplete:@(LMMusicPlayer.onboardingComplete) });
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		if(![userDefaults objectForKey:@"hasUsedAppleWatchApp"]){
			[LMAnswers logCustomEventWithName:@"Using Apple Watch App" customAttributes:nil];
			[userDefaults setObject:@"yeah. hey btw why the are you reading the nsuserdefaults plist. email edwin@lignite.io for a free prize." forKey:@"hasUsedAppleWatchApp"];
		}
		
		if(LMMusicPlayer.onboardingComplete){
			[self sendNowPlayingTrackToWatch:YES];
		}
	}
	else if([key isEqualToString:LMAppleWatchCommunicationKeyMusicBrowsingEntries]){
		NSArray<NSNumber*> *musicTypes = [message objectForKey:LMAppleWatchBrowsingKeyMusicTypes];
		NSArray<NSNumber*> *pageIndexes = [message objectForKey:LMAppleWatchBrowsingKeyPageIndexes];
		
		NSInteger pageIndex = pageIndexes.lastObject.integerValue;
		LMMusicType musicType = (LMMusicType)musicTypes.lastObject.integerValue;
		
		BOOL isInitialBrowsePage = (musicTypes.count == 1);
		BOOL isFirstPage = (pageIndex == 0);
		
		NSInteger MAXIMUM_NUMBER_OF_ITEMS_IN_LIST = 15;
		
		NSArray<LMMusicTrackCollection*> *trackCollections = [self trackCollectionsForBrowsingDictionary:message];
		
		NSArray<LMPlaylist*>* playlists = nil;
		
		NSInteger count = trackCollections.count;
		
		if((musicType == LMMusicTypeTitles || musicType == LMMusicTypeFavourites)){
			trackCollections = [LMMusicPlayer
								arrayOfTrackCollectionsForMusicTrackCollection:trackCollections.firstObject];
			
			count = trackCollections.count;
		}
		else if(musicType == LMMusicTypePlaylists){
			playlists = [[LMPlaylistManager sharedPlaylistManager] playlists];
			
			count = playlists.count;
		}
		
		
		NSMutableArray *resultsArray = [NSMutableArray new];
		
		NSInteger topOfPageIndex = pageIndex * MAXIMUM_NUMBER_OF_ITEMS_IN_LIST;
		NSInteger maximumIndex = topOfPageIndex + MIN(MAXIMUM_NUMBER_OF_ITEMS_IN_LIST, count - topOfPageIndex);
		
		//If there's only a few items left, might as well add them to  the current page instead of making the user go to another page for them
		if(((count-maximumIndex) <= 5) && ((count-maximumIndex) > 0)){
			maximumIndex = count;
		}
	
		for(NSInteger i = topOfPageIndex; i < maximumIndex; i++){
			LMPlaylist *playlist = nil;
			
			LMMusicTrackCollection *collection = nil;
			LMMusicTrack *representativeTrack = nil;
			
			if(musicType == LMMusicTypePlaylists){
				playlist = [playlists objectAtIndex:i];
				collection = playlist.trackCollection;
				representativeTrack = playlist.trackCollection.representativeItem;
			}
			else{
				collection = [trackCollections objectAtIndex:i];
				representativeTrack = collection.representativeItem;
			}
			
			NSString *title = nil;
			NSString *subtitle = nil;
			MPMediaEntityPersistentID newPersistentID;
			
			UIImage *imageToUse = representativeTrack.uncorrectedAlbumArt;
			if(musicType == LMMusicTypeArtists || musicType == LMMusicTypeComposers){
				imageToUse = representativeTrack.uncorrectedArtistImage;
			}
			else if(musicType == LMMusicTypePlaylists){
				imageToUse = playlist.image ? playlist.image : representativeTrack.uncorrectedAlbumArt;
			}
			
			UIImage *resizedImage = [self resizeImage:imageToUse toSize:CGSizeMake(64, 64)];
			NSData *iconData = resizedImage ? UIImageJPEGRepresentation(resizedImage, 0.5) : nil;
			
			
			switch(musicType){
				case LMMusicTypeTitles:
				case LMMusicTypeFavourites:
					title = representativeTrack.title ? representativeTrack.title : NSLocalizedString(@"UnknownTitle", nil);
					subtitle = representativeTrack.artist ? representativeTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
					newPersistentID = representativeTrack.persistentID;
					break;
				case LMMusicTypeCompilations:
				case LMMusicTypeAlbums:
					title = representativeTrack.albumTitle ? representativeTrack.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
					subtitle = representativeTrack.albumArtist ? representativeTrack.albumArtist : NSLocalizedString(@"UnknownArtist", nil);
					newPersistentID = representativeTrack.albumPersistentID;
					break;
				case LMMusicTypeComposers:
					title = representativeTrack.artist ? representativeTrack.artist : NSLocalizedString(@"UnknownComposer", nil);
					subtitle = [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
					newPersistentID = representativeTrack.composerPersistentID;
					break;
				case LMMusicTypeArtists:
					title = representativeTrack.artist ? representativeTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
					subtitle = [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
					newPersistentID = representativeTrack.artistPersistentID;
					break;
				case LMMusicTypeGenres:
					title = representativeTrack.genre ? representativeTrack.genre : NSLocalizedString(@"UnknownGenre", nil);
					subtitle = [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
					newPersistentID = representativeTrack.genrePersistentID;
					break;
				case LMMusicTypePlaylists:
					title = playlist.title;
					subtitle = [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
					newPersistentID = playlist.persistentID;
					break;
				default:
					title = NSLocalizedString(@"UnknownTitle", nil);
					subtitle = NSLocalizedString(@"UnknownArtist", nil);
					newPersistentID = representativeTrack.albumPersistentID;
					break;
			}
			
			[resultsArray addObject:iconData
								   ? @{
									 LMAppleWatchBrowsingKeyEntryPersistentID: @(newPersistentID),
									 LMAppleWatchBrowsingKeyEntryTitle: title,
									 LMAppleWatchBrowsingKeyEntrySubtitle: subtitle,
									 LMAppleWatchBrowsingKeyEntryIcon: iconData
									 }
								   : @{
									  LMAppleWatchBrowsingKeyEntryPersistentID: @(newPersistentID),
									  LMAppleWatchBrowsingKeyEntryTitle: title,
									  LMAppleWatchBrowsingKeyEntrySubtitle: subtitle
									  }];
		}
		
		
		BOOL isEndOfList = (maximumIndex == count);
		
		NSLog(@"Results initial%d first%d end%d max%d/count%d", isInitialBrowsePage, isFirstPage, isEndOfList, (int)maximumIndex, (int)count);
		
		replyHandler(@{
					   @"results": resultsArray,
					   LMAppleWatchBrowsingKeyIsBeginningOfList: @(isFirstPage),
					   LMAppleWatchBrowsingKeyIsEndOfList: @(isEndOfList),
					   LMAppleWatchBrowsingKeyRemainingEntries: @(count - maximumIndex),
					   LMAppleWatchBrowsingKeyTotalNumberOfEntries: @(count)
					   });
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if([key isEqualToString:LMAppleWatchControlKeyPlayPause]){
			[self.musicPlayer invertPlaybackState];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchNowPlayingInfoKeyIsPlaying: @(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyNextTrack]){
			[self.musicPlayer skipToNextTrack];
			[self.musicPlayer play];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyPreviousTrack]){
			[self.musicPlayer skipToPreviousTrack];
			[self.musicPlayer play];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyFavouriteUnfavourite]){
			if(self.musicPlayer.nowPlayingTrack.isFavourite){
				[self.musicPlayer removeTrackFromFavourites:self.musicPlayer.nowPlayingTrack];
			}
			else{
				[self.musicPlayer addTrackToFavourites:self.musicPlayer.nowPlayingTrack];
			}
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchMusicTrackInfoKeyIsFavourite: @(self.musicPlayer.nowPlayingTrack.isFavourite)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyInvertShuffleMode]){
			self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;

			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchNowPlayingInfoKeyShuffleMode: @(self.musicPlayer.shuffleMode)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyNextRepeatMode]){
			LMMusicRepeatMode newRepeatMode;
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
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchNowPlayingInfoKeyRepeatMode: @(self.musicPlayer.repeatMode)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyUpNextTrackSelected]){
			NSInteger nowPlayingQueueIndex = [[message objectForKey:LMAppleWatchControlKeyUpNextTrackSelected] integerValue];
			if(nowPlayingQueueIndex >= self.musicPlayer.nowPlayingCollection.items.count){ //Up next is out of sync
				[self sendUpNextToWatch];
			}
			else{
				LMMusicTrack *trackSelected = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:nowPlayingQueueIndex];
				[self.musicPlayer setNowPlayingTrack:trackSelected];
			}
		}
		else if([key isEqualToString:LMAppleWatchControlKeyCurrentPlaybackTime]){
			NSInteger currentPlaybackTime = [[message objectForKey:LMAppleWatchControlKeyCurrentPlaybackTime] integerValue];
			[self.musicPlayer setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES)
						   });
		}
		else if([key isEqualToString:LMAppleWatchCommunicationKeyBrowsingShuffleAll]){
			LMMusicTrackCollection *collectionToShuffle = [self trackCollectionsForBrowsingDictionary:message].firstObject;
			
			self.musicPlayer.shuffleMode = LMMusicShuffleModeOn;
			[self.musicPlayer setNowPlayingCollection:collectionToShuffle];
			[self.musicPlayer play];
			
			replyHandler(@{ @"success": @(YES) });
		}
		else if([key isEqualToString:LMAppleWatchCommunicationKeyBrowsingPlayIndividualTrack]){
			LMMusicTrackCollection *collectionToPlay = [self trackCollectionsForBrowsingDictionary:message].firstObject;
			
			MPMediaEntityPersistentID persistentIDOfSpecificTrack = (MPMediaEntityPersistentID)[[[message objectForKey:LMAppleWatchBrowsingKeyPersistentIDs] lastObject] longLongValue];
			
			[self.musicPlayer setNowPlayingCollection:collectionToPlay];
			for(LMMusicTrack *track in self.musicPlayer.nowPlayingCollection.items){
				if(track.persistentID == persistentIDOfSpecificTrack){
					[self.musicPlayer setNowPlayingTrack:track];
					break;
				}
			}
			[self.musicPlayer play];
			
			replyHandler(@{ @"success": @(YES) });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyVolumeUp]){
			[self.volumeViewSlider setValue:self.volumeViewSlider.value + 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchNowPlayingInfoKeyVolume: @(self.volumeViewSlider.value)
						   });
		}
		else if([key isEqualToString:LMAppleWatchControlKeyVolumeDown]){
			[self.volumeViewSlider setValue:self.volumeViewSlider.value - 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			
			replyHandler(@{
						   LMAppleWatchCommandSuccess: @(YES),
						   LMAppleWatchNowPlayingInfoKeyVolume: @(self.volumeViewSlider.value)
						   });
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

- (void)handleVolumeChanged:(id)sender{
	NSLog(@"Volume: %f%%", self.volumeViewSlider.value * 100);
	
	
	if(self.connected){
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.session sendMessage:@{
										LMAppleWatchCommunicationKey:LMAppleWatchCommunicationKeyNowPlayingInfoUpdate,
										LMAppleWatchCommunicationKeyNowPlayingInfoUpdate: LMAppleWatchNowPlayingInfoKeyVolume,
										LMAppleWatchNowPlayingInfoKeyVolume: @(self.volumeViewSlider.value)
										}
						 replyHandler:nil
						 errorHandler:nil
			 ];
		});
	}
	
//	[self sendNowPlayingInfoToWatch];
}

- (void)attachToViewController:(UIViewController*)viewController {
	self.volumeView = [[MPVolumeView alloc] init];
	self.volumeView.showsRouteButton = NO;
	self.volumeView.showsVolumeSlider = NO;
	[viewController.view addSubview:self.volumeView];
	
	//find the volumeSlider
	self.volumeViewSlider = nil;
	for (UIView *view in [self.volumeView subviews]){
		if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
			self.volumeViewSlider = (UISlider*)view;
			break;
		}
	}
	
	[self.volumeViewSlider addTarget:self action:@selector(handleVolumeChanged:) forControlEvents:UIControlEventValueChanged];
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
			
			[[LMThemeEngine sharedThemeEngine] addDelegate:sharedAppleWatchBridge];
		}
	});
	
	return sharedAppleWatchBridge;
}

@end
