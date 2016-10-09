//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"

@interface LMMusicPlayer()

/**
 The system music player.
 */
@property MPMusicPlayerController *systemMusicPlayer;

/**
 The delegates associated with the music player. As described in LMMusicPlayerDelegate.
 */
@property NSMutableArray *delegates;

/**
 What a long variable name, I get it. This array contains all of the delegates which is a fan of knowing when the playback time changes. Tbh, I find it easier and cleaner to do this than to create a structure or enum or associated data type, etc.
 */
@property NSMutableArray *delegatesSubscribedToCurrentPlaybackTimeChange;

/**
 The timer for detecting changes in the current playback time.
 */
@property NSTimer *currentPlaybackTimeChangeTimer;

/**
 The previous playback time.
 */
@property NSTimeInterval previousPlaybackTime;

@end

@implementation LMMusicPlayer

@synthesize nowPlayingTrack = _nowPlayingTrack;
@synthesize nowPlayingCollection = _nowPlayingCollection;
@synthesize playerType = _playerType;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize repeatMode = _repeatMode;
@synthesize shuffleMode = _shuffleMode;

- (instancetype)init {
	self = [super init];
	if(self){
		self.systemMusicPlayer = [MPMusicPlayerController systemMusicPlayer];
		self.nowPlayingTrack = [[LMMusicTrack alloc]initWithMPMediaItem:self.systemMusicPlayer.nowPlayingItem];
		self.playerType = LMMusicPlayerTypeSystemMusicPlayer;
		self.delegates = [[NSMutableArray alloc]init];
		self.delegatesSubscribedToCurrentPlaybackTimeChange = [[NSMutableArray alloc]init];x
		self.shuffleMode = LMMusicShuffleModeOff;
		self.repeatMode = LMMusicRepeatModeNone;
		self.previousPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
		
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

- (void)currentPlaybackTimeChangeTimerCallback {
	NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
	NSLog(@"Hey %f", currentPlaybackTime);
	if(currentPlaybackTime != self.previousPlaybackTime){
		for(int i = 0; i < self.delegatesSubscribedToCurrentPlaybackTimeChange.count; i++){
			id<LMMusicPlayerDelegate> delegate = [self.delegatesSubscribedToCurrentPlaybackTimeChange objectAtIndex:i];
			[delegate musicCurrentPlaybackTimeDidChange:currentPlaybackTime];
		}
		
		self.previousPlaybackTime = currentPlaybackTime;
	}
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
	
	if(self.playbackState == LMMusicPlaybackStatePlaying){
		NSLog(@"Yeah");
		if(!self.currentPlaybackTimeChangeTimer || ![self.currentPlaybackTimeChangeTimer isValid]){
			NSLog(@"Register");
			self.currentPlaybackTimeChangeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
																				   target:self
																				 selector:@selector(currentPlaybackTimeChangeTimerCallback)
																				 userInfo:nil
																				  repeats:YES];
		}
	}
	else {
		NSLog(@"Invalidate");
		[self.currentPlaybackTimeChangeTimer invalidate];
		self.currentPlaybackTimeChangeTimer = nil;
	}
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicPlaybackStateDidChange:self.playbackState];
	}
}

- (void)addMusicDelegate:(id<LMMusicPlayerDelegate>)newDelegate {
	[self.delegates addObject:newDelegate];
	if([newDelegate respondsToSelector:@selector(musicCurrentPlaybackTimeDidChange:)]){
		NSLog(@"Yeah BOIIIIIIIIII");
		[self.delegatesSubscribedToCurrentPlaybackTimeChange addObject:newDelegate];
	}
}

- (void)removeMusicDelegate:(id<LMMusicPlayerDelegate>)delegateToRemove {
	[self.delegates removeObject:delegateToRemove];
	if([delegateToRemove respondsToSelector:@selector(musicCurrentPlaybackTimeDidChange:)]){
		[self.delegatesSubscribedToCurrentPlaybackTimeChange addObject:delegateToRemove];
	}
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

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
	_currentPlaybackTime = currentPlaybackTime;
}

- (NSTimeInterval)currentPlaybackTime {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		return self.systemMusicPlayer.currentPlaybackTime;
	}
	
	return _currentPlaybackTime;
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

- (void)setShuffleMode:(LMMusicShuffleMode)shuffleMode {
	_shuffleMode = shuffleMode;
	
	NSLog(@"New shuffle is %d", _shuffleMode);
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMusicShuffleMode associatedShuffleModes[] = {
			MPMusicShuffleModeOff,
			MPMusicShuffleModeSongs
		};
		self.systemMusicPlayer.shuffleMode = associatedShuffleModes[shuffleMode];
	}
}

- (LMMusicShuffleMode)shuffleMode {
	return _shuffleMode;
}

@end
