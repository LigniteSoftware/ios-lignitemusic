//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"

@interface LMMusicPlayer() <AVAudioPlayerDelegate>

/**
 The system music player. Simply provides info related to the music and does not control playback.
 */
@property MPMusicPlayerController *systemMusicPlayer;

/**
 The audio player. Is the actual controller of the system music player contents.
 */
@property AVAudioPlayer *audioPlayer;

/**
 The delegates associated with the music player. As described in LMMusicPlayerDelegate.
 */
@property NSMutableArray *delegates;

/**
 What a long variable name, I get it. This array contains all of the delegates which is a fan of knowing when the playback time changes. Tbh, I find it easier and cleaner to do this than to create a structure or enum or associated data type, etc.
 */
@property NSMutableArray *delegatesSubscribedToCurrentPlaybackTimeChange;
@property NSMutableArray *delegatesSubscribedToLibraryDidChange;

/**
 The timer for detecting changes in the current playback time.
 */
@property NSTimer *currentPlaybackTimeChangeTimer;

/**
 Whether or not the background timer for catching the current playback time should run. Set to NO when the NSTimer kicks in.
 */
@property BOOL runBackgroundTimer;

/**
 The previous playback time.
 */
@property NSTimeInterval previousPlaybackTime;

/**
 When the track is finished automatically, this is set to YES as a flag to let the system know to autoplay the next track.
 */
@property BOOL didJustFinishTrack;

/**
 For some weird reason, if the app opens with a queue which is not exposed (currently 100% of the time) and you try to play a song within the same queue from the app, it will not work. So, we have to clear the queue with a query which will most likely never be existant. Then we set the nowPlayingItem to nil and we're good to do what we want to do. 
 
	 Sometimes software is really fucking weird.
 */
@property MPMediaQuery *bullshitQuery;

/**
 It seems that sometimes even though the library change notification fires, the library is not updated. This will be called half a second after the final library change (or if a track is slow to sync that) to fire all delegates to ensure that data is properly synced.
 */
@property NSTimer *libraryChangeTimer;

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
		[self.systemMusicPlayer beginGeneratingPlaybackNotifications];
		
		//http://stackoverflow.com/questions/3059255/how-do-i-clear-the-queue-of-a-mpmusicplayercontroller
		MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:@"MotherFuckingShitpost69"
																			   forProperty:MPMediaItemPropertyTitle];
		MPMediaQuery *q = [[MPMediaQuery alloc] init];
		[q addFilterPredicate: predicate];
		
		self.bullshitQuery = q;
		
		self.nowPlayingTrack = [[LMMusicTrack alloc]initWithMPMediaItem:self.systemMusicPlayer.nowPlayingItem];
		self.playerType = LMMusicPlayerTypeSystemMusicPlayer;
		self.delegates = [[NSMutableArray alloc]init];
		self.delegatesSubscribedToCurrentPlaybackTimeChange = [[NSMutableArray alloc]init];
		self.delegatesSubscribedToLibraryDidChange = [[NSMutableArray alloc]init];
		self.shuffleMode = LMMusicShuffleModeOff;
		self.repeatMode = LMMusicRepeatModeNone;
		self.previousPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
		
		self.autoPlay = (self.systemMusicPlayer.playbackState == MPMusicPlaybackStatePlaying);
		
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
		[[AVAudioSession sharedInstance] setActive:YES error:nil];
		
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter
		 addObserver:self
			selector:@selector(systemMusicPlayerTrackChanged:)
				name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
			  object:self.systemMusicPlayer];
		
		[notificationCenter
		 addObserver:self
			selector:@selector(systemMusicPlayerStateChanged:)
				name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
			  object:self.systemMusicPlayer];
		
		[notificationCenter
		 addObserver:self
			selector:@selector(mediaLibraryContentsChanged:)
				name:MPMediaLibraryDidChangeNotification
			  object:nil];
		
		MPMediaLibrary *mediaLibrary = [MPMediaLibrary defaultMediaLibrary];
		[mediaLibrary beginGeneratingLibraryChangeNotifications];
		
		MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
		[commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
			[self pause];
			return MPRemoteCommandHandlerStatusSuccess;
		}];
		[commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
			[self play];
			return MPRemoteCommandHandlerStatusSuccess;
		}];
		[commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
			[self skipToNextTrack];
			return MPRemoteCommandHandlerStatusSuccess;
		}];
		[commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
			[self autoBackThrough];
			return MPRemoteCommandHandlerStatusSuccess;
		}];
	
		[commandCenter.changePlaybackPositionCommand addTarget:self action:@selector(handlePlaybackPositionChange:)];
	}
	else{
		NSLog(@"Fatal error! Failed to create instance of LMMusicPlayer.");
	}
	return self;
}

- (void)deinit {
	NSLog(@"Deinit on LMMusicPlayer called. Warning: Releasing notification center hooks to track playing changes!");
	
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

+ (id)sharedMusicPlayer {
	static LMMusicPlayer *sharedPlayer;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPlayer = [[self alloc] init];
		sharedPlayer.pebbleManager = [LMPebbleManager sharedPebbleManager];
		[sharedPlayer.pebbleManager setManagerMusicPlayer:sharedPlayer];
	});
	return sharedPlayer;
}

- (void)prepareForTermination {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		if(self.nowPlayingCollection){
			[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection.sourceCollection];
		}
		self.systemMusicPlayer.nowPlayingItem = self.nowPlayingTrack.sourceTrack;
		self.systemMusicPlayer.currentPlaybackTime = self.currentPlaybackTime;
		
		if(self.audioPlayer.isPlaying){
			[self.audioPlayer stop];
			[self.systemMusicPlayer play];
		}
	}
	
	[self deinit];
}

- (void)prepareForActivation {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		NSLog(@"Preparing for activation, state %d", (int)self.systemMusicPlayer.playbackState);
		if(self.systemMusicPlayer.playbackState == MPMusicPlaybackStatePlaying || self.systemMusicPlayer.playbackState == MPMusicPlaybackStateInterrupted){
			[self.systemMusicPlayer pause];
			[self play];
			NSLog(@"Playing...");
		}
	}
}

- (void)updateNowPlayingTimeDelegates {
	for(int i = 0; i < self.delegatesSubscribedToCurrentPlaybackTimeChange.count; i++){
		id<LMMusicPlayerDelegate> delegate = [self.delegatesSubscribedToCurrentPlaybackTimeChange objectAtIndex:i];
		[delegate musicCurrentPlaybackTimeDidChange:self.currentPlaybackTime];
	}
}

- (void)currentPlaybackTimeChangeTimerCallback:(NSTimer*)timer {
	if(floorf(self.currentPlaybackTime) != floorf(self.previousPlaybackTime)){
		[self updateNowPlayingTimeDelegates];
	}
	
	if(![self.currentPlaybackTimeChangeTimer isValid] || !self.currentPlaybackTimeChangeTimer){
		self.currentPlaybackTimeChangeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
																			   target:self
																			 selector:@selector(currentPlaybackTimeChangeTimerCallback:)
																			 userInfo:nil
																			  repeats:YES];
	}
	
	if(timer){
		self.runBackgroundTimer = NO;
	}
	
	self.previousPlaybackTime = self.currentPlaybackTime;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag {
	NSLog(@"Finished");
	self.didJustFinishTrack = YES;
	if(self.repeatMode == LMMusicRepeatModeOne){
		[self skipToBeginning];
	}
	else{
		[self skipToNextTrack];
	}
}

- (MPRemoteCommandHandlerStatus)handlePlaybackPositionChange:(MPChangePlaybackPositionCommandEvent*)positionEvent {
	NSLog(@"New time %f", positionEvent.positionTime);
	self.audioPlayer.currentTime = positionEvent.positionTime;
	[self reloadInfoCenter:self.audioPlayer.isPlaying];
	return MPRemoteCommandHandlerStatusSuccess;
}

- (void)currentPlaybackTimeChangeFireTimer:(BOOL)adjustForDifference {
	__weak id weakSelf = self;

	double delayInSeconds = 0.1;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		if(![strongSelf runBackgroundTimer]){
			return;
		}
		
		[strongSelf currentPlaybackTimeChangeTimerCallback:nil];
		
		[strongSelf currentPlaybackTimeChangeFireTimer:NO];
	});
}

- (void)reloadAudioPlayerWithNowPlayingItem {
	NSError *error = nil;
	
	NSURL *url = [self.systemMusicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyAssetURL];
	
	self.audioPlayer = nil;
	self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
	self.audioPlayer.delegate = self;
	
	if(error){
		//TODO: make sure this doesn't happen again, apply better fix
		NSLog(@"Error loading audio player with url %@: %@", url, error);
		[self skipToNextTrack];
	}
	else{
		[self.audioPlayer prepareToPlay];
		
		[self updateNowPlayingTimeDelegates];
	}
}

- (void)reloadInfoCenter:(BOOL)isPlaying {
	if(![self hasTrackLoaded]){
		return;
	}
	
	MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
	
	NSMutableDictionary *newInfo = [[NSMutableDictionary alloc]init];
	[newInfo setObject:self.nowPlayingTrack.title ? self.nowPlayingTrack.title : NSLocalizedString(@"UnknownTitle", nil) forKey:MPMediaItemPropertyTitle];
	[newInfo setObject:self.nowPlayingTrack.artist ? self.nowPlayingTrack.artist : NSLocalizedString(@"UnknownArtist", nil) forKey:MPMediaItemPropertyArtist];
	[newInfo setObject:self.nowPlayingTrack.albumTitle ? self.nowPlayingTrack.albumTitle : NSLocalizedString(@"UnknownAlbumTitle", nil) forKey:MPMediaItemPropertyAlbumTitle];
	[newInfo setObject:@(self.nowPlayingTrack.playbackDuration) forKey:MPMediaItemPropertyPlaybackDuration];
	[newInfo setObject:@(self.audioPlayer.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
	if([self.nowPlayingTrack.sourceTrack artwork]){
		[newInfo setObject:[self.nowPlayingTrack.sourceTrack artwork] forKey:MPMediaItemPropertyArtwork];
	}
	[newInfo setObject:@(isPlaying) forKey:MPNowPlayingInfoPropertyPlaybackRate];
	
//	NSLog(@"Allahu is playing %d: %@", self.audioPlayer.isPlaying, newInfo);
	
	infoCenter.nowPlayingInfo = newInfo;
}

- (void)systemMusicPlayerTrackChanged:(id)sender {
	BOOL autoPlay = self.audioPlayer.isPlaying;
	
	[self reloadAudioPlayerWithNowPlayingItem];
	
	LMMusicTrack *newTrack = [[LMMusicTrack alloc]initWithMPMediaItem:self.systemMusicPlayer.nowPlayingItem];
	self.nowPlayingTrack = newTrack;
	self.indexOfNowPlayingTrack = self.systemMusicPlayer.indexOfNowPlayingItem;
	if(self.systemMusicPlayer.currentPlaybackTime != 0){
		self.currentPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
	}

	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicTrackDidChange:self.nowPlayingTrack];
	}
	
	if(self.didJustFinishTrack && (self.indexOfNowPlayingTrack != 0 || self.repeatMode != LMMusicRepeatModeNone)){
		self.autoPlay = YES;
		self.didJustFinishTrack = NO;
	}
	
	if(autoPlay || self.autoPlay){
		[self play];
		self.autoPlay = NO;
	}
	
	[self reloadInfoCenter:autoPlay];
}

- (void)changeMusicPlayerState:(LMMusicPlaybackState)newState {
	self.playbackState = newState;
	
	if(self.playbackState == LMMusicPlaybackStatePlaying){
		if(!self.runBackgroundTimer){
			self.runBackgroundTimer = YES;
			[self currentPlaybackTimeChangeFireTimer:YES];
		}
	}
	else {
		self.runBackgroundTimer = NO;
		
		//[self.currentPlaybackTimeChangeTimer invalidate];
		//self.currentPlaybackTimeChangeTimer = nil;
	}
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicPlaybackStateDidChange:self.playbackState];
	}
}

- (void)systemMusicPlayerStateChanged:(id)sender {	
	if(self.systemMusicPlayer.playbackState == MPMusicPlaybackStateInterrupted){
		self.playbackState = LMMusicPlaybackStatePlaying;
		self.autoPlay = YES;
	}
	else{
		self.playbackState = (LMMusicPlaybackState)self.systemMusicPlayer.playbackState;
	}
	
	if(self.playbackState == LMMusicPlaybackStatePlaying){
		if(!self.runBackgroundTimer){
			self.runBackgroundTimer = YES;
			[self currentPlaybackTimeChangeFireTimer:YES];
		}
	}
	else {
		self.runBackgroundTimer = NO;
		
		//[self.currentPlaybackTimeChangeTimer invalidate];
		//self.currentPlaybackTimeChangeTimer = nil;
	}
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicPlaybackStateDidChange:self.playbackState];
	}
}

- (void)audioRouteChanged:(id)notification {
	NSDictionary *info = [notification userInfo];
	
	AVAudioSessionRouteChangeReason changeReason = [[info objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
	if(changeReason == 2){ //Audio jack removed or BT headset removed
		[self pause];
	}
}

- (void)mediaLibraryContentsChanged:(id)notification {
	NSLog(@"Library changed!!!");
	for(int i = 0; i < self.delegatesSubscribedToLibraryDidChange.count; i++){
		[[self.delegatesSubscribedToLibraryDidChange objectAtIndex:i] musicLibraryDidChange];
	}
	
	if([self.libraryChangeTimer isValid]){
		[self.libraryChangeTimer invalidate];
	}
	if([[[notification class] description] isEqualToString:@"NSDictionary"]){
		self.libraryChangeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
																   target:self
																 selector:@selector(mediaLibraryContentsChanged:)
																 userInfo:nil
																  repeats:NO];
	}
}

- (void)setSourceTitle:(NSString*)title {
	if(self.sourceSelector){
		[self.sourceSelector setSourceTitle:title];
	}
}

- (void)setSourceSubtitle:(NSString*)subtitle {
	if(self.sourceSelector){
		[self.sourceSelector setSourceSubtitle:subtitle];
	}
}

- (void)addMusicDelegate:(id<LMMusicPlayerDelegate>)newDelegate {
	[self.delegates addObject:newDelegate];
	if([newDelegate respondsToSelector:@selector(musicCurrentPlaybackTimeDidChange:)]){
		[self.delegatesSubscribedToCurrentPlaybackTimeChange addObject:newDelegate];
	}
	if([newDelegate respondsToSelector:@selector(musicLibraryDidChange)]){
		[self.delegatesSubscribedToLibraryDidChange addObject:newDelegate];
	}
}

- (void)removeMusicDelegate:(id<LMMusicPlayerDelegate>)delegateToRemove {
	[self.delegates removeObject:delegateToRemove];
	if([delegateToRemove respondsToSelector:@selector(musicCurrentPlaybackTimeDidChange:)]){
		[self.delegatesSubscribedToCurrentPlaybackTimeChange removeObject:delegateToRemove];
	}
	if([delegateToRemove respondsToSelector:@selector(musicLibraryDidChange)]){
		[self.delegatesSubscribedToLibraryDidChange removeObject:delegateToRemove];
	}
}

BOOL shuffleForDebug = NO;

- (void)shuffleArray:(NSMutableArray*)array {
	NSUInteger count = [array count];
	if(count < 1){
		return;
	}
	for(NSUInteger i = 0; i < count - 1; ++i) {
		NSInteger remainingCount = count - i;
		NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
		[array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
	}
}

+ (LMMusicTrackCollection*)musicTrackCollectionFromMediaItemCollection:(MPMediaItemCollection*)itemCollection {
	NSMutableArray *musicCollection = [[NSMutableArray alloc]init];
	for(int itemIndex = 0; itemIndex < itemCollection.count; itemIndex++){
		MPMediaItem *musicItem = [itemCollection.items objectAtIndex:itemIndex];
		LMMusicTrack *musicTrack = [[LMMusicTrack alloc]initWithMPMediaItem:musicItem];
		[musicCollection addObject:musicTrack];
	}
	LMMusicTrackCollection *trackCollection = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:itemCollection];
	return trackCollection;
}

- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
//		NSLog(@"Querying items for LMMusicType %d...", musicType);
		
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
		
		if(shuffleForDebug){
			NSLog(@"--- Warning: Query is being automatically shuffled. ---");
			[self shuffleArray:musicTracks];
		}
		
		NSLog(@"[LMMusicPlayer]: Took %f seconds to complete query.", endingTime-startingTime);
		
		return musicTracks;
	}
	return nil;
}

- (void)skipToNextTrack {
	NSLog(@"Skip to next");
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		if(self.repeatMode == LMMusicRepeatModeOne){
			[self.systemMusicPlayer skipToBeginning];
		}
		else{
			[self.systemMusicPlayer skipToNextItem];
		}
		if(self.repeatMode != LMMusicRepeatModeNone){
			[self systemMusicPlayerTrackChanged:self];
		}
	}
}

- (void)autoSkipAudioPlayer {
	NSLog(@"Autoskip");
	__weak id weakSelf = self;
	
	float delayInSeconds = 0.50;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		LMMusicPlayer *player = strongSelf;
		player.currentPlaybackTime = 0;
		[player play];
	});
}

- (void)autoBackThrough {
	if(self.currentPlaybackTime > 5){
		NSLog(@"Skipping to beginning");
		[self skipToBeginning];
	}
	else{
		NSLog(@"Skipping to previous");
		[self skipToPreviousItem];
	}
}

- (void)skipToBeginning {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self pause];
		[self autoSkipAudioPlayer];
	}
}

- (void)skipToPreviousItem {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.systemMusicPlayer skipToPreviousItem];
	}
}

- (void)autoPauseAudioPlayer {
	__weak id weakSelf = self;
	
	float delayInSeconds = 0.25;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		LMMusicPlayer *player = strongSelf;
		
		[player.audioPlayer pause];
		
		[self reloadInfoCenter:NO];
	});
}

- (void)play {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePlaying];
		
		//[self.systemMusicPlayer play];
		NSLog(@"Playing");
		[self.audioPlayer setVolume:1 fadeDuration:0.25];
		[self.audioPlayer play];
		[self reloadInfoCenter:YES];
		
		NSLog(@"Done");
	}
}

- (void)pause {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePaused];
		//[self.systemMusicPlayer pause];
		[self.audioPlayer setVolume:0 fadeDuration:0.25];
		[self autoPauseAudioPlayer];
	}
}

- (void)stop {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.audioPlayer stop];
	}
}

- (LMMusicPlaybackState)invertPlaybackState {
	switch(self.audioPlayer.isPlaying){
		case LMMusicPlaybackStatePlaying:
			[self pause];
			return LMMusicPlaybackStatePaused;
		default:
			[self play];
			return LMMusicPlaybackStatePlaying;
	}
}

- (BOOL)hasTrackLoaded {
	return (self.nowPlayingTrack.title != nil);
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
		if(self.systemMusicPlayer.nowPlayingItem.persistentID != associatedMediaItem.persistentID){
			[self.systemMusicPlayer setNowPlayingItem:associatedMediaItem];
		}
	}
	_nowPlayingTrack = nowPlayingTrack;
}

- (LMMusicTrack*)nowPlayingTrack {
	return _nowPlayingTrack;
}

- (void)clearNowPlayingCollection {
	[self.systemMusicPlayer setQueueWithQuery:self.bullshitQuery];
	[self.systemMusicPlayer setNowPlayingItem:nil];
}

- (void)setNowPlayingCollection:(LMMusicTrackCollection*)nowPlayingCollection {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		if(!self.nowPlayingCollection){
			[self clearNowPlayingCollection];
		}
		[self.systemMusicPlayer setQueueWithItemCollection:nowPlayingCollection.sourceCollection];
		[self.systemMusicPlayer setNowPlayingItem:[[nowPlayingCollection.sourceCollection items] objectAtIndex:0]];
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
	NSLog(@"Setting current playback time to %f", currentPlaybackTime);
	
	self.audioPlayer.currentTime = currentPlaybackTime;
		
	_currentPlaybackTime = currentPlaybackTime;
	
	[self updateNowPlayingTimeDelegates];
	
	[self reloadInfoCenter:self.audioPlayer.isPlaying];
}

- (NSTimeInterval)currentPlaybackTime {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		return self.audioPlayer.currentTime;
	}
	
	return _currentPlaybackTime;
}

- (void)setRepeatMode:(LMMusicRepeatMode)repeatMode {
	_repeatMode = repeatMode;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMusicRepeatMode systemRepeatModes[4] = {
			MPMusicRepeatModeNone,
			MPMusicRepeatModeNone,
			MPMusicRepeatModeAll,
			MPMusicRepeatModeOne
		};
		self.systemMusicPlayer.repeatMode = systemRepeatModes[repeatMode];
	}
}

- (LMMusicRepeatMode)repeatMode {
	return _repeatMode;
}

- (void)setShuffleMode:(LMMusicShuffleMode)shuffleMode {
	_shuffleMode = shuffleMode;
	
//	NSLog(@"New shuffle is %d", _shuffleMode);
	
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
