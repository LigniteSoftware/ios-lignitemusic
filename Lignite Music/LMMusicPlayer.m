//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"

@interface LMMusicPlayer()

@property MPMusicPlayerController *systemMusicPlayer;
@property NSMutableArray *delegates;

@end

@implementation LMMusicPlayer

@synthesize nowPlayingTrack = _nowPlayingTrack;
@synthesize nowPlayingCollection = _nowPlayingCollection;
@synthesize playerType = _playerType;
@synthesize shuffleMode = _shuffleMode;
@synthesize repeatMode = _repeatMode;

- (instancetype)init {
	self = [super init];
	if(self){
		self.systemMusicPlayer = [MPMusicPlayerController systemMusicPlayer];
		self.nowPlayingTrack = [[LMMusicTrack alloc]initWithMPMediaItem:self.systemMusicPlayer.nowPlayingItem];
		self.playerType = LMMusicPlayerTypeSystemMusicPlayer;
		self.delegates = [[NSMutableArray alloc]init];
		self.shuffleMode = LMMusicShuffleModeOff;
		self.repeatMode = LMMusicRepeatModeNone;
		
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter
		 addObserver: self
		 selector:    @selector(systemMusicPlayerTrackChanged:)
		 name:        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		 object:      self.systemMusicPlayer];
		
		[notificationCenter
		 addObserver: self
		 selector:    @selector(systemMusicPlayerStateChanged:)
		 name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
		 object:      self.systemMusicPlayer];
		
		[self.systemMusicPlayer beginGeneratingPlaybackNotifications];
	}
	else{
		NSLog(@"Fatal error! Failed to create instance of LMMusicPlayer.");
	}
	return self;
}

- (void)deinit {
	NSLog(@"Deinit on LMMusicPlayer called. Warning: Releasing notification center hooks to track playing change!");
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self
	 name:           MPMusicPlayerControllerNowPlayingItemDidChangeNotification
	 object:         self.systemMusicPlayer];
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self
	 name:           MPMusicPlayerControllerPlaybackStateDidChangeNotification
	 object:         self.systemMusicPlayer];
	
	[self.systemMusicPlayer endGeneratingPlaybackNotifications];
}

- (void)systemMusicPlayerTrackChanged:(id)sender {
	LMMusicTrack *newTrack = [[LMMusicTrack alloc]initWithMPMediaItem:self.systemMusicPlayer.nowPlayingItem];
	self.nowPlayingTrack = newTrack;
	self.indexOfNowPlayingTrack = self.systemMusicPlayer.indexOfNowPlayingItem;
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicTrackDidChange:self.nowPlayingTrack];
	}
}

- (void)systemMusicPlayerStateChanged:(id)sender {
	self.playbackState = (LMMusicPlaybackState)self.systemMusicPlayer.playbackState;
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicPlaybackStateDidChange:self.playbackState];
	}
}

- (void)addMusicDelegate:(id)newDelegate {
	[self.delegates addObject:newDelegate];
}

- (void)removeMusicDelegate:(id)delegateToRemove {
	[self.delegates removeObject:delegateToRemove];
}

- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
		NSLog(@"Querying items for LMMusicType %d...", musicType);
		
		MPMediaQuery *query = nil;
		MPMediaGrouping associatedMediaTypes[] = {
			MPMediaGroupingArtist,
			MPMediaGroupingAlbum,
			MPMediaGroupingTitle,
			MPMediaGroupingPlaylist,
			MPMediaGroupingComposer
		};
		MPMediaGrouping associatedGrouping = associatedMediaTypes[musicType];
		
		switch(associatedGrouping){
			case MPMediaGroupingArtist:
				query = [MPMediaQuery artistsQuery];
				break;
			case MPMediaGroupingAlbum:
				query = [MPMediaQuery albumsQuery];
				break;
			case MPMediaGroupingTitle:
				query = [MPMediaQuery songsQuery];
				break;
			case MPMediaGroupingPlaylist:
				query = [MPMediaQuery playlistsQuery];
				break;
			case MPMediaGroupingComposer:
				query = [MPMediaQuery composersQuery];
				break;
			default:
				query = [MPMediaQuery songsQuery];
				NSLog(@"Defaulting to songs query!");
				break;
		}
		
		NSArray *collections = query.collections;
		NSMutableArray* musicTracks = [[NSMutableArray alloc]init];
		for(int i = 0; i < collections.count; i++){
			MPMediaItemCollection *itemCollection = [collections objectAtIndex:i];
			NSMutableArray *musicCollection = [[NSMutableArray alloc]init];
			for(int itemIndex = 0; itemIndex < itemCollection.count; itemIndex++){
				MPMediaItem *musicItem = [itemCollection.items objectAtIndex:itemIndex];
				LMMusicTrack *musicTrack = [[LMMusicTrack alloc]initWithMPMediaItem:musicItem];
				[musicCollection addObject:musicTrack];
			}
			LMMusicTrackCollection *trackCollection = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:itemCollection];
			[musicTracks addObject:trackCollection];
		}
		
		NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
		
		NSLog(@"Took %f seconds to complete query.", endingTime-startingTime);
		
		return musicTracks;
	}
	return nil;
}

- (void)skipToNextTrack {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer skipToNextItem];
	}
}

- (void)skipToBeginning {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer skipToBeginning];
	}
}

- (void)skipToPreviousItem {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer skipToPreviousItem];
	}
}

- (void)play {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer play];
	}
}

- (void)pause {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer pause];
	}
}

- (void)stop {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer stop];
	}
}

- (LMMusicPlaybackState)invertPlaybackState {
	switch(self.playbackState){
		case LMMusicPlaybackStatePlaying:
			[self pause];
			return LMMusicPlaybackStatePaused;
		default:
			[self play];
			return LMMusicPlaybackStatePlaying;
	}
}

- (void)setNowPlayingTrack:(LMMusicTrack*)nowPlayingTrack {
	for(int i = 0; i < self.nowPlayingCollection.count; i++){
		LMMusicTrack *track = [self.nowPlayingCollection.items objectAtIndex:i];
		if([nowPlayingTrack isEqual:track]){
			self.indexOfNowPlayingTrack = i;
			break;
		}
	}
	
	NSLog(@"Setting to %@.", nowPlayingTrack.title);
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMediaItem *associatedMediaItem = nowPlayingTrack.sourceTrack;
		self.systemMusicPlayer.nowPlayingItem = associatedMediaItem;
	}
	_nowPlayingTrack = nowPlayingTrack;
}

- (LMMusicTrack*)nowPlayingTrack {
	return _nowPlayingTrack;
}

- (void)setNowPlayingCollection:(LMMusicTrackCollection*)nowPlayingCollection {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer setQueueWithItemCollection:nowPlayingCollection.sourceCollection];
	}
	_nowPlayingCollection = nowPlayingCollection;
}

- (void)setPlayerType:(LMMusicPlayerType)playerType {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:playerType forKey:DEFAULTS_KEY_PLAYER_TYPE];
	[defaults synchronize];
	
	_playerType = playerType;
}

- (LMMusicPlayerType)playerType {
	return _playerType;
}

+ (LMMusicPlayerType)savedPlayerType {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	LMMusicPlayerType type = LMMusicPlayerTypeSystemMusicPlayer;
	if([defaults objectForKey:DEFAULTS_KEY_PLAYER_TYPE]){
		type = (LMMusicPlayerType)[defaults integerForKey:DEFAULTS_KEY_PLAYER_TYPE];
	}
	return type;
}

- (LMMusicTrackCollection*)nowPlayingCollection {
	return _nowPlayingCollection;
}

- (void)setShuffleMode:(LMMusicShuffleMode)shuffleMode {
	_shuffleMode = shuffleMode;
	
	NSLog(@"New shuffle is %d", _shuffleMode);
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMusicShuffleMode associatedShuffleModes[] = {
			MPMusicShuffleModeDefault,
			MPMusicShuffleModeOff,
			MPMusicShuffleModeSongs,
			MPMusicShuffleModeAlbums
		};
		self.systemMusicPlayer.shuffleMode = associatedShuffleModes[shuffleMode];
	}
}

- (LMMusicShuffleMode)shuffleMode {
	return _shuffleMode;
}

- (void)setRepeatMode:(LMMusicRepeatMode)repeatMode {
	_repeatMode = repeatMode;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		self.systemMusicPlayer.repeatMode = (MPMusicRepeatMode)repeatMode;
	}
}

- (LMMusicRepeatMode)repeatMode {
	return _repeatMode;
}

@end
