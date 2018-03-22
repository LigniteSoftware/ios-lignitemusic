//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <TargetConditionals.h>

#import "LMMusicPlayer.h"
#import "NSTimer+Blocks.h"
#import "LMPlaylist.h"
#import "LMPlaylistManager.h"
#import "LMSettings.h"

@import StoreKit;

@interface LMMusicPlayer() <AVAudioPlayerDelegate>

/**
 The audio player. Is the actual controller of the system music player contents.
 */
@property AVAudioPlayer *audioPlayer;

/**
 The delegates associated with the music player. As described in LMMusicPlayerDelegate.
 */
@property NSMutableArray *delegates;

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
 Because library changes come in quick bursts, this timer waits for the bursts to finish and then calls any delegates which are registered for library change notifications.
 */
@property NSTimer *libraryChangeTimer;
@property NSTimer *playbackStateChangeTimer; //Same thing, but for the current playback state.

/**
 The now playing collection which is sorted.
 */
@property LMMusicTrackCollection *nowPlayingCollectionSorted;

/**
 The now playing collection which is shuffled.
 */
@property LMMusicTrackCollection *nowPlayingCollectionShuffled;

/**
 The persistent ID of the last track which was played through the app. If this does not match with the system music player change, that means that the track was set outside of the app.
 */
@property MPMediaEntityPersistentID lastTrackSetInLigniteMusicPersistentID;

/**
 The last track which was moved in the queue.
 */
@property LMMusicTrack *lastTrackMovedInQueue;

/**
 I hate this issue. Essentially when you set a new queue on the system music player, it resets to the first song, so then you set the same track again to keep playing, but have to restore the track time as well. Causes some "lag" in the music. >:(
 */
@property CGFloat playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid;

@end

@implementation LMMusicPlayer

@synthesize nowPlayingTrack = _nowPlayingTrack;
@synthesize nowPlayingCollection = _nowPlayingCollection;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize repeatMode = _repeatMode;
@synthesize shuffleMode = _shuffleMode;
@synthesize systemMusicPlayer = _systemMusicPlayer;
@synthesize playbackState = _playbackState;

MPMediaGrouping associatedMediaTypes[] = {
	MPMediaGroupingTitle, //Favourites
	MPMediaGroupingArtist,
	MPMediaGroupingAlbum,
	MPMediaGroupingTitle,
	MPMediaGroupingPlaylist,
	MPMediaGroupingGenre,
	MPMediaGroupingAlbum, //Compilations, actually. Queries will adjust for this.
	MPMediaGroupingComposer
};

- (MPMusicPlayerController*)systemMusicPlayer {
#if TARGET_OS_SIMULATOR
//	NSLog(@"Simulator");
	return [MPMusicPlayerController applicationMusicPlayer];
#else
//	NSLog(@"Real device");
	return [MPMusicPlayerController systemMusicPlayer];
#endif
}

- (void)setSystemMusicPlayer:(MPMusicPlayerController *)systemMusicPlayer {
	//Do nothing
}

- (void)voiceOverStatusChanged {
	NSLog(@"[LMMusicPlayer] VoiceOver status changed to %d", UIAccessibilityIsVoiceOverRunning());
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(voiceOverStatusChanged:)]){
			[delegate voiceOverStatusChanged:UIAccessibilityIsVoiceOverRunning()];
		}
	}
}

- (NSInteger)numberOfItemsInQueue {
	return [[MPMusicPlayerController systemMusicPlayer] performSelector:@selector(numberOfItems)];;
}

- (MPMediaItem*)queueTrackAtIndex:(NSInteger)index {
	NSString *selectorString = [NSString stringWithFormat:@"n%@%@%@", @"owPlayingT",@"temA",@"tIndex:"];
	
	SEL sse = NSSelectorFromString(selectorString);
	
	if ([MPMusicPlayerController instancesRespondToSelector:sse]) {
		IMP sseimp = [MPMusicPlayerController instanceMethodForSelector:sse];
		MPMediaItem *mediaItem = sseimp([MPMusicPlayerController systemMusicPlayer], sse, index);
		NSLog(@"Object %@ title %@", mediaItem, mediaItem.title);
		return mediaItem;
	}
	
	NSLog(@"Doesn't respond :(");
	
	return nil;
}

- (instancetype)init {
	self = [super init];
	if(self){
		NSTimeInterval musicPlayerLoadStartTime = [[NSDate new] timeIntervalSince1970];
		
		[self.systemMusicPlayer beginGeneratingPlaybackNotifications];
		
		MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:@"MotherFuckingShitpost69"
																			   forProperty:MPMediaItemPropertyTitle];
		MPMediaQuery *q = [[MPMediaQuery alloc] init];
		[q addFilterPredicate: predicate];
		
		self.bullshitQuery = q;
		
		[self loadNowPlayingState];
		
		self.delegates = [NSMutableArray new];
		
		if(self.repeatMode == LMMusicRepeatModeDefault){
			self.repeatMode = LMMusicRepeatModeNone;
		}
		self.previousPlaybackTime = self.currentPlaybackTime;
		
//		self.autoPlay = (self.systemMusicPlayer.playbackState == MPMusicPlaybackStatePlaying);
		
//		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//		[[AVAudioSession sharedInstance] setActive:YES error:nil];
		
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		
		NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
		
		[notificationCentre
		 addObserver:self
		 selector:@selector(voiceOverStatusChanged)
		 name:UIAccessibilityVoiceOverStatusChanged
		 object:nil];
		
		[notificationCentre
		 addObserver:self
		 selector:@selector(audioRouteChanged:)
		 name:AVAudioSessionRouteChangeNotification
		 object:nil];
		
		[notificationCentre
		 addObserver:self
		 selector:@selector(systemMusicPlayerTrackChanged:)
		 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
		 object:self.systemMusicPlayer];
		
		[notificationCentre
		 addObserver:self
		 selector:@selector(systemMusicPlayerStateChanged:)
		 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
		 object:self.systemMusicPlayer];
		
		[notificationCentre
		 addObserver:self
		 selector:@selector(mediaLibraryContentsChanged:)
		 name:MPMediaLibraryDidChangeNotification
		 object:nil];
		
		MPMediaLibrary *mediaLibrary = [MPMediaLibrary defaultMediaLibrary];
		[mediaLibrary beginGeneratingLibraryChangeNotifications];
		
		
		NSTimeInterval musicPlayerLoadEndTime = [[NSDate new] timeIntervalSince1970];
		NSLog(@"Setup LMMusicPlayer in %f seconds.", (musicPlayerLoadEndTime-musicPlayerLoadStartTime));
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

+ (LMMusicPlayer*)sharedMusicPlayer {	
	NSAssert([self onboardingComplete], @"Onboarding isn't complete.");
	
	static LMMusicPlayer *sharedPlayer;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPlayer = [self new];
	});
	return sharedPlayer;
}

+ (BOOL)onboardingComplete {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	return [userDefaults objectForKey:LMSettingsKeyOnboardingComplete] ? YES : NO;
}

- (LMMusicPlaybackState)playbackState {
	return _playbackState;
}

- (void)setPlaybackState:(LMMusicPlaybackState)playbackState {
	if(playbackState == LMMusicPlaybackStateStopped){
		playbackState = LMMusicPlaybackStatePaused;
	}
	_playbackState = playbackState;
}

- (void)prepareForTermination {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		if(self.nowPlayingCollection){
			[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
		}
		self.systemMusicPlayer.nowPlayingItem = self.nowPlayingTrack;
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

- (void)updateNowPlayingTimeDelegates:(BOOL)userModified {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSTimeInterval playbackTime = self.currentPlaybackTime;
		
//		CFAbsoluteTime startTimeInSeconds = CFAbsoluteTimeGetCurrent();
//		NSLog(@"Updating time delegates");
		
		NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
		
		for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
			if([delegate respondsToSelector:@selector(musicCurrentPlaybackTimeDidChange:userModified:)]){
				[delegate musicCurrentPlaybackTimeDidChange:playbackTime userModified:userModified];
			}
		}
		
//		CFAbsoluteTime endTimeInSeconds = CFAbsoluteTimeGetCurrent();
//		NSLog(@"Done updating, took %f seconds", (endTimeInSeconds-startTimeInSeconds));
	});
}

- (void)reloadQueueWithTrack:(LMMusicTrack*)newTrack {
	self.queueRequiresReload = NO;
	
	NSLog(@"Queue was modified and needs a refresher, here we go.");
	
//	NSLog(@"=== START QUEUE REFRESH ===");
//	
//	for(LMMusicTrack *track in self.nowPlayingCollection.items){
//		NSLog((track.persistentID == newTrack.persistentID) ? @"* %@" : @"%@", newTrack);
//	}
//	
//	NSLog(@"=== END QUEUE REFRESH ===");
	
	[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
	[self.systemMusicPlayer setNowPlayingItem:newTrack];
}

- (LMMusicTrack*)nextTrackInQueue {
	if((self.indexOfNowPlayingTrack + 1) < self.nowPlayingCollection.count){
		return [self.nowPlayingCollection.items objectAtIndex:self.indexOfNowPlayingTrack + 1];
	}
	else if(self.nowPlayingCollection.count > 0){
		return [self.nowPlayingCollection.items firstObject];
	}
	
	return nil;
}

- (LMMusicTrack*)previousTrackInQueue {
	if((self.indexOfNowPlayingTrack - 1) > 0){
		return [self.nowPlayingCollection.items objectAtIndex:self.indexOfNowPlayingTrack - 1];
	}
	else if(self.nowPlayingCollection.count > 0){
		return [self.nowPlayingCollection.items lastObject];
	}
	
	return nil;
}

- (void)currentPlaybackTimeChangeTimerCallback:(NSTimer*)timer {
	if(((self.nowPlayingTrack.playbackDuration - self.currentPlaybackTime) < 1.5) && self.queueRequiresReload){
		[self reloadQueueWithTrack:[self nextTrackInQueue]];
	}
	
	if(floorf(self.currentPlaybackTime) != floorf(self.previousPlaybackTime)){
		[self updateNowPlayingTimeDelegates:NO];
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
	[self reloadInfoCentre:self.audioPlayer.isPlaying];
	
	return MPRemoteCommandHandlerStatusSuccess;
}

- (void)keepShuffleModeInLine {
	if(self.nowPlayingWasSetWithinLigniteMusic){
		if(self.systemMusicPlayer.shuffleMode != MPMusicShuffleModeOff){
			self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeOff;
		}
	}
}

- (void)currentPlaybackTimeChangeFireTimer:(BOOL)adjustForDifference {
	__weak id weakSelf = self;
	
	[self keepShuffleModeInLine];
	
	double delayInSeconds = 0.1;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_global_queue(NSQualityOfServiceUserInitiated, 0), ^(void){
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		if(![strongSelf runBackgroundTimer]){
			return;
		}
		
//		NSLog(@"Main thread? %d", [NSThread isMainThread]);

		[strongSelf currentPlaybackTimeChangeTimerCallback:nil];

		[strongSelf currentPlaybackTimeChangeFireTimer:NO];
	});
}

- (void)reloadInfoCentre:(BOOL)isPlaying {
	if(![self hasTrackLoaded]){
		return;
	}
	
	MPNowPlayingInfoCenter *infoCentre = [MPNowPlayingInfoCenter defaultCenter];
	
	NSMutableDictionary *newInfo = [[NSMutableDictionary alloc]init];
	[newInfo setObject:self.nowPlayingTrack.title ? self.nowPlayingTrack.title : NSLocalizedString(@"UnknownTitle", nil) forKey:MPMediaItemPropertyTitle];
	[newInfo setObject:self.nowPlayingTrack.artist ? self.nowPlayingTrack.artist : NSLocalizedString(@"UnknownArtist", nil) forKey:MPMediaItemPropertyArtist];
	[newInfo setObject:self.nowPlayingTrack.albumTitle ? self.nowPlayingTrack.albumTitle : NSLocalizedString(@"UnknownAlbumTitle", nil) forKey:MPMediaItemPropertyAlbumTitle];
	[newInfo setObject:@(self.nowPlayingTrack.playbackDuration) forKey:MPMediaItemPropertyPlaybackDuration];
	[newInfo setObject:@(self.audioPlayer.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
	//	if([self.nowPlayingTrack artwork]){
	//		[newInfo setObject:[self.nowPlayingTrack artwork] forKey:MPMediaItemPropertyArtwork];
	//	}
	[newInfo setObject:@(isPlaying) forKey:MPNowPlayingInfoPropertyPlaybackRate];
	
	//	NSLog(@"Allahu is playing %d: %@", self.audioPlayer.isPlaying, newInfo);
	
	infoCentre.nowPlayingInfo = newInfo;
}

- (BOOL)nowPlayingCollectionContainsTrack:(LMMusicTrack*)track {
	for(LMMusicTrack *collectionTrack in self.nowPlayingCollection.items){
		if(track.persistentID == collectionTrack.persistentID){
			return YES;
		}
	}
	return NO;
}

//#warning track change
- (void)systemMusicPlayerTrackChanged:(id)sender {
	CFAbsoluteTime startTimeInSeconds = CFAbsoluteTimeGetCurrent();
	NSLog(@"System track changed %@ Updating...", [NSThread isMainThread] ? @"on the main thread." : @"NOT ON THE MAIN THREAD!");
	
	if(self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid > 0){
		NSLog(@"Set playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid... %f", self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid);
		[self setCurrentPlaybackTime:self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid];

		self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid = 0.0;
	}
	
	CFAbsoluteTime nextTime;

	
	[self keepShuffleModeInLine];
	
	nextTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"[Update] shuffleModeInLine: %fs", (nextTime - startTimeInSeconds));
	
//#ifndef TARGET_OS_SIMULATOR //If NOT the simulator
	if(self.lastTrackSetInLigniteMusicPersistentID != self.systemMusicPlayer.nowPlayingItem.persistentID){
		BOOL nowPlayingCollectionContainsTrack = [self nowPlayingCollectionContainsTrack:self.systemMusicPlayer.nowPlayingItem];
		if(nowPlayingCollectionContainsTrack){
			[self setNowPlayingTrack:self.systemMusicPlayer.nowPlayingItem];
		}
		else{
			NSLog(@"WAS SYSTEM SET: %@", self.nowPlayingCollection);
			self.nowPlayingCollectionShuffled = nil;
			self.nowPlayingCollectionSorted = nil;
			self.nowPlayingTrack = self.systemMusicPlayer.nowPlayingItem;
		}
	}
//#endif
	
	//	NSLog(@"System music changed %@", self.systemMusicPlayer.nowPlayingItem);
	
	LMMusicTrack *newTrack = self.systemMusicPlayer.nowPlayingItem;
	if(self.nowPlayingTrack != newTrack && newTrack != nil){
		self.nowPlayingTrack = newTrack;
	}
	
	nextTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"[Update] fixNewTrackNotEqual: %fs", (nextTime - startTimeInSeconds));
	
	self.indexOfNowPlayingTrack = self.nowPlayingWasSetWithinLigniteMusic ? self.systemMusicPlayer.indexOfNowPlayingItem : 0;
//	if(self.systemMusicPlayer.currentPlaybackTime != 0){
//		self.currentPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
//	}
	
	nextTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"[Update] setCurrentPlaybackTime: %fs", (nextTime - startTimeInSeconds));
	
	[self notifyDelegatesOfNowPlayingTrack];
	
	nextTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"[Update] notifyDelegates: %fs", (nextTime - startTimeInSeconds));
	
//	if(self.didJustFinishTrack && (self.indexOfNowPlayingTrack != 0 || self.repeatMode != LMMusicRepeatModeNone)){
//		self.autoPlay = YES;
//		self.didJustFinishTrack = NO;
//	}
	
//	nextTime = CFAbsoluteTimeGetCurrent();
//	NSLog(@"[Update] setAutoAndDidFinish: %fs", (nextTime - startTimeInSeconds));
	
	if(self.autoPlay){
		self.autoPlay = NO;
		[self play];
	}
	
//	nextTime = CFAbsoluteTimeGetCurrent();
//	NSLog(@"[Update] markPlay: %fs", (nextTime - startTimeInSeconds));
//
//	[self reloadInfoCentre:autoPlay];
	
	nextTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"[Update] infoCentre: %fs", (nextTime - startTimeInSeconds));
	
	CFAbsoluteTime endTimeInSeconds = CFAbsoluteTimeGetCurrent();
	NSLog(@"Done updating from music track change, took %f seconds", (endTimeInSeconds-startTimeInSeconds));
}

- (void)notifyDelegatesOfPlaybackState {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(musicPlaybackStateDidChange:)]){
			[delegate musicPlaybackStateDidChange:self.playbackState];
		}
	}
}

- (void)notifyDelegatesOfNowPlayingTrack {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(musicTrackDidChange:)]){
			[delegate musicTrackDidChange:self.nowPlayingTrack];
		}
	}
}

- (void)systemMusicPlayerStateChanged:(id)sender {
	[self keepShuffleModeInLine];
	
	NSLog(@"System playback state changed to %d", (int)self.systemMusicPlayer.playbackState);
	
	if(self.systemMusicPlayer.playbackState == MPMusicPlaybackStateInterrupted
	   || self.systemMusicPlayer.playbackState == MPMusicPlaybackStateStopped){
		self.playbackState = LMMusicPlaybackStatePaused;
	}
	else{
		if(self.systemMusicPlayer.playbackState == MPMusicPlaybackStateSeekingForward || self.systemMusicPlayer.playbackState == MPMusicPlaybackStateSeekingBackward){ //what even are these fucking playback states
			self.playbackState = LMMusicPlaybackStatePlaying;
		}
		else{ //paused or playing directly
			self.playbackState = (LMMusicPlaybackState)self.systemMusicPlayer.playbackState;
		}
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
	
	if(self.playbackStateChangeTimer){
		[self.playbackStateChangeTimer invalidate];
	}
	
	static BOOL firstChange = YES;
	static LMMusicPlaybackState previouslyNotifiedState = LMMusicPlaybackStateInterrupted;
	
	if(firstChange){
		firstChange = NO;
		previouslyNotifiedState = self.playbackState;
		[self notifyDelegatesOfPlaybackState];
	}
	else{
		//Slight timer delay fixes any tiny gaps in between playing back music
		self.playbackStateChangeTimer = [NSTimer scheduledTimerWithTimeInterval:0.15f block:^{
			NSLog(@"Holy smoekss");
			if(previouslyNotifiedState != self.playbackState){
				previouslyNotifiedState = self.playbackState;
				[self notifyDelegatesOfPlaybackState];
			}
		} repeats:NO];
	}
}

- (void)changeMusicPlayerState:(LMMusicPlaybackState)newState {
	[self keepShuffleModeInLine];
	
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
	
	[self notifyDelegatesOfPlaybackState];
}

- (void)audioRouteChanged:(id)notification {
	NSDictionary *info = [notification userInfo];
	
	NSLog(@"Audio route changed %@", info);
	
	AVAudioSessionRouteChangeReason changeReason = [[info objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
	dispatch_async(dispatch_get_main_queue(), ^{
		if(changeReason == 2){ //Audio jack removed or BT headset removed
			[self pause];
		}
		
		AVAudioSession* audioSession = [AVAudioSession sharedInstance];
		AVAudioSessionRouteDescription* currentRoute = audioSession.currentRoute;
		for(AVAudioSessionPortDescription* outputPort in currentRoute.outputs){
			for(NSInteger i = 0; i < self.delegates.count; i++){
				id<LMMusicPlayerDelegate> delegate = [self.delegates objectAtIndex:i];
				if([delegate respondsToSelector:@selector(musicOutputPortDidChange:)]){
					[delegate musicOutputPortDidChange:outputPort];
				}
			}
		}
	});
}

+ (BOOL)outputPortIsWireless:(AVAudioSessionPortDescription *)outputPort {
	if(   [outputPort.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]
	   || [outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]
	   || [outputPort.portType isEqualToString:AVAudioSessionPortBluetoothLE]
	   || [outputPort.portType isEqualToString:AVAudioSessionPortBluetoothHFP]){
		
		return YES;
	}
	
	return NO;
}

- (void)notifyLibraryChangeDelegatesOfLibraryChange:(BOOL)finished {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(musicLibraryChanged:)]){
			[delegate musicLibraryChanged:finished];
		}
	}
}

- (void)mediaLibraryContentsChanged:(id)notification {
	NSLog(@"Library changed");
	
//	if(!self.nowPlayingWasSetWithinLigniteMusic){
//		//Because music that is started outside our app seems to cause a fuckton of syncing.
//		NSLog(@"The user's listening to music that was started outside of our app, rejecting library change.");
//		return;
//	}
	
	if(self.libraryChangeTimer){
		[self.libraryChangeTimer invalidate];
	}
	
	[self notifyLibraryChangeDelegatesOfLibraryChange:NO];
	
	self.libraryChangeTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f block:^{
		NSLog(@"Done syncing library");
		
		[[LMPlaylistManager sharedPlaylistManager] reloadCachedPlaylists];
		
		[self notifyLibraryChangeDelegatesOfLibraryChange:YES];
	} repeats:NO];
}

- (void)addMusicDelegate:(id<LMMusicPlayerDelegate>)newDelegate {
	[self.delegates addObject:newDelegate];
}

- (void)removeMusicDelegate:(id<LMMusicPlayerDelegate>)delegateToRemove {
	[self.delegates removeObject:delegateToRemove];
}

BOOL shuffleForDebug = NO;

- (void)shuffleArrayOfTracks:(NSMutableArray<LMMusicTrack*>*)array {
	NSUInteger count = [array count];
	if(count < 1){
		return;
	}
	
	for(NSUInteger i = 0; i < count - 1; ++i) {
//		NSInteger remainingCount = count - i;
		NSInteger exchangeIndex = arc4random_uniform((u_int32_t)count);
		
		LMMusicTrack *firstTrack = [array objectAtIndex:i];
		LMMusicTrack *otherTrack = [array objectAtIndex:exchangeIndex];
		LMMusicTrack *trackInFrontOfOtherTrack =
			[array objectAtIndex:((exchangeIndex + 1) >= count) ? 0 : (exchangeIndex + 1)];
		LMMusicTrack *trackBehindOfOtherTrack =
			[array objectAtIndex:((exchangeIndex - 1) < 0) ? (count - 1) : (exchangeIndex - 1)];
		
		int triesToMakeQuoteOnQuoteRandom = 0;
		while(((firstTrack.artistPersistentID == trackInFrontOfOtherTrack.artistPersistentID)
			  || (firstTrack.artistPersistentID == trackBehindOfOtherTrack.artistPersistentID))
			  	&& triesToMakeQuoteOnQuoteRandom < 10){

			exchangeIndex = arc4random_uniform((u_int32_t)count);
//			otherTrack = [array objectAtIndex:exchangeIndex];
			
			trackInFrontOfOtherTrack =
				[array objectAtIndex:((exchangeIndex + 1) >= count) ? 0 : (exchangeIndex + 1)];
			trackBehindOfOtherTrack =
				[array objectAtIndex:((exchangeIndex - 1) < 0) ? (count - 1) : (exchangeIndex - 1)];

			triesToMakeQuoteOnQuoteRandom++;
		}

		if(triesToMakeQuoteOnQuoteRandom > 0){
			NSLog(@"- Shuffled -\n%@/%@\n%@/%@", firstTrack.artist, otherTrack.artist, firstTrack.albumTitle, otherTrack.albumTitle);
		}
		
		[array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
	}
}

- (NSString*)firstLetterForString:(NSString*)string {
	if(string == nil || string.length < 1){
		return @"?";
	}
	return [[NSString stringWithFormat:@"%C", [string characterAtIndex:0]] uppercaseString];
}

+ (NSArray<LMMusicTrackCollection*>*)arrayOfTrackCollectionsForMusicTrackCollection:(LMMusicTrackCollection*)collection {
	NSMutableArray *trackCollectionsArray = [NSMutableArray new];
	for(LMMusicTrack *track in collection.items){
		[trackCollectionsArray addObject:[[LMMusicTrackCollection alloc] initWithItems:@[ track ]]];
	}
	return [NSArray arrayWithArray:trackCollectionsArray];
}

+ (LMMusicTrackCollection*)trackCollectionForArrayOfTrackCollections:(NSArray<LMMusicTrackCollection*>*)arrayOfTrackCollections {
	NSMutableArray *trackCollectionsArray = [NSMutableArray new];
	for(LMMusicTrackCollection *trackCollection in arrayOfTrackCollections){
		for(LMMusicTrack *track in trackCollection.items){
			[trackCollectionsArray addObject:track];
		}
	}
	return [[LMMusicTrackCollection alloc] initWithItems:[NSArray arrayWithArray:trackCollectionsArray]];
}

+ (BOOL)trackCollection:(LMMusicTrackCollection*)trackCollection isEqualToOtherTrackCollection:(LMMusicTrackCollection*)otherTrackCollection {
	
	if(trackCollection.count != otherTrackCollection.count){
		return NO;
	}
	
	for(NSInteger i = 0; i < trackCollection.count; i++){
		LMMusicTrack *track = [trackCollection.items objectAtIndex:i];
		
		BOOL containsOtherTrack = NO;
		
		for(LMMusicTrack *otherTrack in otherTrackCollection.items){
			if(track.persistentID == otherTrack.persistentID){
				containsOtherTrack = YES;
				break;
			}
		}
		
		if(!containsOtherTrack){
			return NO;
		}
	}
	
	return YES;
}

+ (NSString*)persistentIDPropertyStringForMusicType:(LMMusicType)musicType {
	switch(musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return MPMediaItemPropertyPersistentID;
		case LMMusicTypeComposers:
			return MPMediaItemPropertyComposerPersistentID;
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
			return MPMediaItemPropertyAlbumPersistentID;
		case LMMusicTypeArtists:
			return MPMediaItemPropertyArtistPersistentID;
		case LMMusicTypeGenres:
			return MPMediaItemPropertyGenrePersistentID;
		default:
			NSAssert(true, @"This music type (%d) is not supported", musicType);
			return @"";
	}
}

+ (MPMediaEntityPersistentID)persistentIDForMusicTrackCollection:(LMMusicTrackCollection*)trackCollection withMusicType:(LMMusicType)musicType {
	
	return [[trackCollection.representativeItem valueForProperty:[LMMusicPlayer persistentIDPropertyStringForMusicType:musicType]] longLongValue];
}

- (NSDictionary*)lettersAvailableDictionaryForMusicTrackCollectionArray:(NSArray<LMMusicTrackCollection*>*)collectionArray
												withAssociatedMusicType:(LMMusicType)musicType {
	NSUInteger lastCollectionIndex = 0;
	
	NSMutableDictionary *lettersDictionary = [NSMutableDictionary new];
	
	BOOL isTitles = (musicType == LMMusicTypeTitles);
	
	LMMusicTrackCollection *firstTrackCollection = nil;
	if(isTitles && collectionArray.count > 0){
		firstTrackCollection = [collectionArray objectAtIndex:0];
	}
	
	NSArray<LMPlaylist*> *playlists = nil;
	if(musicType == LMMusicTypePlaylists){
		playlists = [[LMPlaylistManager sharedPlaylistManager] playlists];
	}
	
	NSUInteger countToUse = isTitles ? firstTrackCollection.count : collectionArray.count;
	
	NSString *letters = @"#ABCDEFGHIJKLMNOPQRSTUVWXYZ?";
	for(int i = 0; i < letters.length; i++){
		NSString *locationLetter = [NSString stringWithFormat: @"%C", [letters characterAtIndex:i]];
		
		for(NSUInteger collectionIndex = lastCollectionIndex; collectionIndex < countToUse; collectionIndex++){
			NSString *trackLetter = @"?";
			
			LMMusicTrackCollection *musicCollection = nil;
			LMMusicTrack *musicTrack = nil;
			LMPlaylist *playlist = nil;
			
			if(isTitles){
				musicCollection = firstTrackCollection;
				musicTrack = [firstTrackCollection.items objectAtIndex:collectionIndex];
			}
			else if(musicType == LMMusicTypePlaylists){
				playlist = [playlists objectAtIndex:collectionIndex];
			}
			else{
				musicCollection = [collectionArray objectAtIndex:collectionIndex];
				musicTrack = musicCollection.representativeItem;
			}
			
			switch(musicType){
				case LMMusicTypeArtists:
					if(musicTrack.artist){
						trackLetter = [self firstLetterForString:musicTrack.artist];
					}
					break;
				case LMMusicTypeAlbums:
					if(musicTrack.albumTitle){
						trackLetter = [self firstLetterForString:musicTrack.albumTitle];
					}
					break;
				case LMMusicTypeFavourites:
				case LMMusicTypeTitles:
					if(musicTrack.title){
						NSLog(@"Letter scan for %@ %lu %lu", musicTrack.title, collectionIndex, lastCollectionIndex);
						trackLetter = [self firstLetterForString:musicTrack.title];
					}
					break;
				case LMMusicTypePlaylists: {
					if(playlist.title){
						trackLetter = [self firstLetterForString:playlist.title];
					}
					break;
				}
				case LMMusicTypeCompilations:{
					NSString *title = [musicCollection titleForMusicType:musicType];
					if(title){
						trackLetter = [self firstLetterForString:title];
					}
					break;
				}
				case LMMusicTypeComposers:
					if(musicTrack.composer){
						trackLetter = [self firstLetterForString:musicTrack.composer];
					}
					break;
				case LMMusicTypeGenres:
					if(musicTrack.genre){
						trackLetter = [self firstLetterForString:musicTrack.genre];
					}
					break;
			}
			
			trackLetter = [trackLetter uppercaseString];
			//			NSLog(@"%d: %@: %@", (int)collectionIndex, trackLetter, musicTrack.title);
			
			BOOL doesntContainLetter = ![[lettersDictionary allKeys] containsObject:locationLetter];
			BOOL letterIsDigit = isdigit([trackLetter characterAtIndex:0]);
			
			//If the character is a number and we're scanning for the first pound sign index
			if((letterIsDigit
				&& [locationLetter isEqualToString:@"#"]
				&& doesntContainLetter)
			   //Or, if the letter is not yet in the dictionary and the letter matches the one being searched for
			   || ([locationLetter isEqualToString:trackLetter]
				   && doesntContainLetter)
			   //Or if it's an unknown letter/character and no question mark index has been logged yet and it's not a digit
			   || (![letters containsString:[NSString stringWithFormat: @"%C", [trackLetter characterAtIndex:0]]]
				   && ![[lettersDictionary allKeys] containsObject:@"?"]
				   && [locationLetter isEqualToString:@"?"]
				   && !letterIsDigit))
			{
				//Log that bitch
				[lettersDictionary setObject:[NSNumber numberWithUnsignedInteger:collectionIndex] forKey:locationLetter];
				
				lastCollectionIndex = collectionIndex;
				
				//				NSLog(@"%d/%d: Logging %@ (%@)", (int)i, (int)collectionIndex, locationLetter, musicTrack.title);
				break;
			}
			//If we're on the last index and there's no hope set the letter's index to the last index that was found
			else if(collectionIndex == countToUse-1){
				[lettersDictionary setObject:[NSNumber numberWithUnsignedInteger:lastCollectionIndex] forKey:locationLetter];
				
				//				NSLog(@"%d/%d: No hope for %@ (%@)", (int)i, (int)collectionIndex, locationLetter, musicTrack.title);
			}
		}
	}
	
	return [NSDictionary dictionaryWithDictionary:lettersDictionary];
}

- (NSSortDescriptor*)alphabeticalSortDescriptorForSortKey:(NSString*)sortKey {
	return [NSSortDescriptor sortDescriptorWithKey:sortKey
										 ascending:YES
										comparator:
			^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
				 NSString *cleanString1 = [obj1 stringByReplacingOccurrencesOfString:@"the " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [obj1 length])];
				 NSString *cleanString2 = [obj2 stringByReplacingOccurrencesOfString:@"the " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [obj2 length])];
									 
				 return [cleanString1 compare:cleanString2 options:NSCaseInsensitiveSearch];
			}];
}

- (NSArray<LMMusicTrackCollection*>*)trackCollectionsForMediaQuery:(id)mediaQuery withMusicType:(LMMusicType)musicType {
	//	MPMediaGrouping associatedGrouping = associatedMediaTypes[musicType];
	
	NSMutableArray *collections =
	[[NSMutableArray alloc]initWithArray:(musicType == LMMusicTypeTitles) ? @[[MPMediaItemCollection collectionWithItems:[mediaQuery items]]] : [mediaQuery collections]];
	
	NSString *sortKey = nil;
	
	switch(musicType){
		case LMMusicTypeArtists:
			sortKey = @"representativeItem.artist";
			break;
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums:
			sortKey = @"representativeItem.albumTitle";
			break;
		case LMMusicTypeTitles:
			sortKey = @"representativeItem.title";
			break;
		case LMMusicTypePlaylists:
			sortKey = @"";
			break;
		case LMMusicTypeComposers:
			sortKey = @"representativeItem.composer";
			break;
		case LMMusicTypeGenres:
			sortKey = @"representativeItem.genre";
			break;
		case LMMusicTypeFavourites:
			return @[ [self favouritesTrackCollection] ];
	}
	
	//	sortKey = @"representativeItem";
	
	//	NSLog(@"Loading sort");
	
	NSSortDescriptor *albumSort;
	
	if(musicType == LMMusicTypePlaylists) {
		albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
			MPMediaPlaylist *firstPlaylist = obj1;
			MPMediaPlaylist *secondPlaylist = obj2;
			
			NSString *firstPlaylistName = [firstPlaylist valueForProperty:MPMediaPlaylistPropertyName];
			NSString *secondPlaylistName = [secondPlaylist valueForProperty:MPMediaPlaylistPropertyName];
			
			return [firstPlaylistName compare:secondPlaylistName];
		}];
	}
	else{
//		albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
		albumSort = [self alphabeticalSortDescriptorForSortKey:sortKey];
	}
	
	NSMutableArray *fixedCollections = [NSMutableArray arrayWithArray:[collections sortedArrayUsingDescriptors:@[albumSort]]];
	
	int i = 0; //for debugging
	for(LMMusicTrackCollection *collection in fixedCollections){
		//		NSLog(@"Checking collection %d of %d", i, (int)collection.count);
		if(collection.count == 0){
			[collections removeObject:collection];
		}
		i++;
	}
	
	//		NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	if(shuffleForDebug){
		NSLog(@"--- Warning: Query is being automatically shuffled. ---");
//		[self shuffleArray:collections];
	}
	
	//		NSLog(@"[LMMusicPlayer]: Took %f seconds to complete query.", endingTime-startingTime);
	
	//	NSLog(@"Returning sort");
	
	//	NSLog(@"%ld before %ld after", [mediaQuery collections].count, [collections sortedArrayUsingDescriptors:@[albumSort]].count);
	
	return [collections sortedArrayUsingDescriptors:@[albumSort]];
}

- (BOOL)demoMode {
	return [[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDemoMode];
}

- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType {
	if(musicType == LMMusicTypeFavourites){
		return @[ [self favouritesTrackCollection] ];
	}
	else if(musicType == LMMusicTypePlaylists){
		return [[LMPlaylistManager sharedPlaylistManager] playlistTrackCollections];
	}
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		//		NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
		//		NSLog(@"Querying items for LMMusicType %d...", musicType);
		
		BOOL isCompilations = musicType == LMMusicTypeCompilations;
		
		MPMediaQuery *query = nil;
		MPMediaGrouping associatedGrouping = associatedMediaTypes[musicType];
		
		if(isCompilations){
			query = [MPMediaQuery compilationsQuery];
		}
		else{
			switch(associatedGrouping){
				case MPMediaGroupingArtist:
					query = [MPMediaQuery albumsQuery];
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
				case MPMediaGroupingGenre:
					query = [MPMediaQuery genresQuery];
					break;
				default:
					query = [MPMediaQuery songsQuery];
					NSLog(@"Defaulting to songs query!");
					break;
			}
		}
		
		query.groupingType = associatedMediaTypes[musicType];
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDemoMode] && [[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyArtistsFilteredForDemo] && musicType == LMMusicTypeArtists){
			query.groupingType = MPMediaGroupingTitle;
		}
		
		[self applyDemoModeFilterIfApplicableToQuery:query];
		
		return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
	}
	return nil;
}

- (void)applyDemoModeFilterIfApplicableToQuery:(MPMediaQuery*)query {
	if([[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDemoMode]){
		MPMediaPropertyPredicate *demoFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:@"LIGNITE_DEMO"
																						 forProperty:MPMediaItemPropertyComposer comparisonType:MPMediaPredicateComparisonEqualTo];
		[query addFilterPredicate:demoFilterPredicate];
	}
}

- (NSArray<LMMusicTrackCollection*>*)collectionsForPersistentID:(MPMediaEntityPersistentID)persistentID
												   forMusicType:(LMMusicType)musicType {
	
	NSAssert(musicType != LMMusicTypeFavourites, @"Cannot query favourites, sorry");
	
	MPMediaGrouping associatedGroupings[] = {
		MPMediaGroupingTitle,  //Favourites
		MPMediaGroupingAlbum,  //Artists
		MPMediaGroupingAlbum,  //Albums
		MPMediaGroupingTitle,  //Titles
		MPMediaGroupingTitle,  //Playlists
		MPMediaGroupingAlbum,  //Genres
		MPMediaGroupingAlbum,  //Compilations
		MPMediaGroupingAlbum   //Composers
	};
	
	NSArray<NSString*> *associatedPersistentIDProperties = @[
															 MPMediaItemPropertyPersistentID, 		  //Favourites
															 MPMediaItemPropertyArtistPersistentID,   //Artists
															 MPMediaItemPropertyAlbumPersistentID,    //Albums
															 MPMediaItemPropertyPersistentID,         //Titles
															 MPMediaPlaylistPropertyName,             //Playlists
															 MPMediaItemPropertyGenrePersistentID,    //Genres
															 MPMediaItemPropertyAlbumPersistentID,    //Compilations
															 MPMediaItemPropertyComposerPersistentID  //Composers
															 ];
	
	NSString *associatedProperty = [associatedPersistentIDProperties objectAtIndex:musicType];
	
	MPMediaQuery *query = nil;
	
	query = [MPMediaQuery new];
	query.groupingType = associatedGroupings[musicType];
	
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:@(persistentID)
																					  forProperty:associatedProperty comparisonType:MPMediaPredicateComparisonEqualTo];
	[query addFilterPredicate:musicFilterPredicate];
	
	[self applyDemoModeFilterIfApplicableToQuery:query];
	
	return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
}

- (NSArray<LMMusicTrackCollection*>*)collectionsForWatchForPersistentID:(MPMediaEntityPersistentID)persistentID
														   forMusicType:(LMMusicType)musicType {
	
	NSAssert(musicType != LMMusicTypeFavourites, @"Cannot query favourites, sorry");
	
	MPMediaGrouping associatedGroupings[] = {
		MPMediaGroupingTitle,  //Favourites
		MPMediaGroupingAlbum,  //Artists
		MPMediaGroupingAlbum,  //Albums
		MPMediaGroupingTitle,  //Titles
		MPMediaGroupingTitle,  //Playlists
		MPMediaGroupingAlbum,  //Genres
		MPMediaGroupingAlbum,  //Compilations
		MPMediaGroupingAlbum   //Composers
	};
	
	NSArray<NSString*> *associatedPersistentIDProperties = @[
															 MPMediaItemPropertyPersistentID, 		  //Favourites
															 MPMediaItemPropertyArtistPersistentID,   //Artists
															 MPMediaItemPropertyAlbumPersistentID,    //Albums
															 MPMediaItemPropertyPersistentID,         //Titles
															 MPMediaPlaylistPropertyName,             //Playlists
															 MPMediaItemPropertyGenrePersistentID,    //Genres
															 MPMediaItemPropertyAlbumPersistentID,    //Compilations
															 MPMediaItemPropertyComposerPersistentID  //Composers
															 ];
	
	NSString *associatedProperty = [associatedPersistentIDProperties objectAtIndex:musicType];
	
	MPMediaQuery *query = nil;
	
	query = [MPMediaQuery new];
	query.groupingType = associatedGroupings[musicType];
	
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:@(persistentID)
																					  forProperty:associatedProperty comparisonType:MPMediaPredicateComparisonEqualTo];
	[query addFilterPredicate:musicFilterPredicate];
	
	[self applyDemoModeFilterIfApplicableToQuery:query];
	
	return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
}

- (NSArray<LMMusicTrackCollection*>*)collectionsForRepresentativeTrack:(LMMusicTrack*)representativeTrack forMusicType:(LMMusicType)musicType {
	MPMediaGrouping associatedGroupings[] = {
		MPMediaGroupingTitle,  //Favourites
		MPMediaGroupingAlbum,  //Artists
		MPMediaGroupingAlbum,  //Albums
		MPMediaGroupingTitle,  //Titles
		MPMediaGroupingTitle,  //Playlists
		MPMediaGroupingAlbum,  //Genres
		MPMediaGroupingAlbum,  //Compilations
		MPMediaGroupingAlbum   //Composers
	};
	
	NSArray<NSString*> *associatedPersistentIDProperties = @[
															 MPMediaItemPropertyPersistentID, 		  //Favourites
															 MPMediaItemPropertyArtistPersistentID,   //Artists
															 MPMediaItemPropertyAlbumPersistentID,    //Albums
															 MPMediaItemPropertyPersistentID,         //Titles
															 MPMediaPlaylistPropertyName,             //Playlists
															 MPMediaItemPropertyGenrePersistentID,    //Genres
															 MPMediaItemPropertyAlbumPersistentID,    //Compilations
															 MPMediaItemPropertyComposerPersistentID  //Composers
															 ];
	
	NSString *associatedProperty = [associatedPersistentIDProperties objectAtIndex:musicType];
	
	MPMediaQuery *query = nil;
	
	query = [MPMediaQuery new];
	query.groupingType = associatedGroupings[musicType];
	
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:[representativeTrack valueForProperty:associatedProperty]
																					  forProperty:associatedProperty
																				   comparisonType:MPMediaPredicateComparisonEqualTo];
	[query addFilterPredicate:musicFilterPredicate];
	
	[self applyDemoModeFilterIfApplicableToQuery:query];
	
	return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
}

- (void)skipToBeginning {
	[self setCurrentPlaybackTime:0];
}

- (void)skipToPreviousTrack {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		if(self.queueRequiresReload){
			[self reloadQueueWithTrack:[self previousTrackInQueue]];
		}
		else{
			[self.systemMusicPlayer skipToPreviousItem];
		}
	}
}

- (void)skipToNextTrack {
	NSLog(@"Skip to next");
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		if(self.repeatMode == LMMusicRepeatModeOne){
			[self.systemMusicPlayer skipToBeginning];
		}
		else{
			if(self.queueRequiresReload){
				[self reloadQueueWithTrack:[self nextTrackInQueue]];
			}
			else{
				[self.systemMusicPlayer skipToNextItem];
			}
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
		[self skipToPreviousTrack];
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
		
		[self reloadInfoCentre:NO];
	});
}

- (void)play {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePlaying];
		
		//[self.systemMusicPlayer play];
		NSLog(@"Playing");
		[self.audioPlayer setVolume:1 fadeDuration:0.25];
		[self.audioPlayer play];
		[self reloadInfoCentre:YES];
		
		NSLog(@"Done");
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer play];
		//		[self changeMusicPlayerState:LMMusicPlaybackStatePlaying];
		
		NSLog(@"BPM %d", (int)self.systemMusicPlayer.nowPlayingItem.beatsPerMinute);
	}
}

- (void)pause {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePaused];
		//[self.systemMusicPlayer pause];
		[self.audioPlayer setVolume:0 fadeDuration:0.25];
		[self autoPauseAudioPlayer];
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer pause];
		//		[self changeMusicPlayerState:LMMusicPlaybackStatePaused];
	}
}

- (void)stop {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.audioPlayer stop];
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer stop];
	}
}

- (LMMusicPlaybackState)invertPlaybackState {
	NSLog(@"Playback state %lu", self.systemMusicPlayer.playbackState);
	
	if(self.systemMusicPlayer.playbackState == MPMusicPlaybackStateStopped || self.systemMusicPlayer.playbackState == LMMusicPlaybackStateInterrupted){
		NSLog(@"Gotem");
		self.playbackState = LMMusicPlaybackStatePaused;
	}
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer) {
		switch(self.audioPlayer.isPlaying){
			case LMMusicPlaybackStatePlaying:
				[self pause];
				return LMMusicPlaybackStatePaused;
			default:
				[self play];
				return LMMusicPlaybackStatePlaying;
		}
	}
	else{
		switch(self.systemMusicPlayer.playbackState){
			case MPMusicPlaybackStatePlaying:
			case MPMusicPlaybackStateSeekingBackward:
			case MPMusicPlaybackStateSeekingForward:{
				[self pause];
				return LMMusicPlaybackStatePaused;
			}
			case MPMusicPlaybackStateInterrupted:
			case MPMusicPlaybackStateStopped:{
				[self pause];
				[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
					[self play];
				} repeats:NO];
				return LMMusicPlaybackStatePlaying;
			}
			case MPMusicPlaybackStatePaused:{
				[self play];
				return LMMusicPlaybackStatePlaying;
			}
		}
	}
}

- (BOOL)hasTrackLoaded {
	return (self.nowPlayingTrack != nil);
}

- (BOOL)nowPlayingWasSetWithinLigniteMusic {
	if(!self.nowPlayingCollection && self.systemMusicPlayer.nowPlayingItem){
		return NO;
	}
	return YES;
}

- (void)setNowPlayingTrack:(LMMusicTrack*)nowPlayingTrack {
	self.lastTrackSetInLigniteMusicPersistentID = nowPlayingTrack.persistentID;
	
	NSLog(@"Setting now playing track (in Lignite Music) to %@", nowPlayingTrack.title);
//	self.nowPlayingWasSetWithinLigniteMusic = YES;
	for(int i = 0; i < self.nowPlayingCollection.count; i++){
		LMMusicTrack *track = [self.nowPlayingCollection.items objectAtIndex:i];
		if([nowPlayingTrack isEqual:track]){
			self.indexOfNowPlayingTrack = i;
			break;
		}
	}
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		MPMediaItem *associatedMediaItem = nowPlayingTrack;
		if(self.systemMusicPlayer.nowPlayingItem.persistentID != associatedMediaItem.persistentID){
			NSLog(@"Setting %@ compared to %@", self.systemMusicPlayer.nowPlayingItem.title, associatedMediaItem.title);
			if(self.queueRequiresReload){
				[self reloadQueueWithTrack:associatedMediaItem];
			}
			else{
				[self.systemMusicPlayer setNowPlayingItem:associatedMediaItem];
			}
		}
	}
	
	_nowPlayingTrack = nowPlayingTrack;
	
	if(nowPlayingTrack == nil){
		[self notifyDelegatesOfNowPlayingTrack];
		
		[self reloadInfoCentre:NO];
	}
	
#if TARGET_OS_SIMULATOR
	[self systemMusicPlayerTrackChanged:nowPlayingTrack];
#endif
}

- (LMMusicTrack*)nowPlayingTrack {
#ifndef TARGET_OS_SIMULATOR //If NOT the simulator
	if(!_nowPlayingTrack || !self.nowPlayingWasSetWithinLigniteMusic){
		return self.systemMusicPlayer.nowPlayingItem;
	}
#endif
	return _nowPlayingTrack;
}

- (void)saveNowPlayingState {
	return;
	
//	if(!self.nowPlayingCollection){
//		NSLog(@"Not gonna save the now playing state because there's no now playing collection");
//		return;
//	}
//
//	NSLog(@"Saving now playing state...");
//
//	//Save the now playing collection to storage
//	NSMutableString *persistentIDString = [NSMutableString new];
//	for(LMMusicTrack *track in self.nowPlayingCollectionSorted.items) {
//		[persistentIDString appendString:[NSString stringWithFormat:@"%lld,", track.persistentID]];
//	}
//
//	persistentIDString = [NSMutableString stringWithString:[persistentIDString substringToIndex:persistentIDString.length-1]];
//
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//	[userDefaults setObject:persistentIDString forKey:DEFAULTS_KEY_NOW_PLAYING_COLLECTION];
//
//
//	//Save the now playing track and its state to storage
//	NSDictionary *nowPlayingTrackInfo = @{
//										  @"persistentID":@(self.nowPlayingTrack.persistentID),
//										  @"playbackTime":@((NSInteger)floorf(self.currentPlaybackTime)),
//										  @"shuffleMode":@(self.shuffleMode),
//										  @"repeatMode":@(self.repeatMode)
//										  };
//	[userDefaults setObject:nowPlayingTrackInfo forKey:DEFAULTS_KEY_NOW_PLAYING_TRACK];
//
//	[userDefaults synchronize];
//
//	NSLog(@"Saved! %@ %@", persistentIDString, nowPlayingTrackInfo);
}

- (void)loadNowPlayingState {
	return;
	
//	self.musicWasUserSet = NO;
	
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//
//
////	NSString *allPersistentIDsString = nil;
//	NSString *allPersistentIDsString = [userDefaults objectForKey:DEFAULTS_KEY_NOW_PLAYING_COLLECTION];
//	NSDictionary *nowPlayingTrackInfo = [userDefaults objectForKey:DEFAULTS_KEY_NOW_PLAYING_TRACK];
//
//	NSLog(@"Got info %@", nowPlayingTrackInfo);
//
//	LMMusicTrack *systemNowPlayingTrack = self.systemMusicPlayer.nowPlayingItem;
//	MPMediaEntityPersistentID systemNowPlayingPersistentID = systemNowPlayingTrack.persistentID;
//	BOOL preservedQueueContainsSystemNowPlayingTrack = NO;
//	NSTimeInterval playbackTime = self.systemMusicPlayer.currentPlaybackTime;
//
//	NSNumber *preservedNowPlayingTrackPersistentID = [nowPlayingTrackInfo objectForKey:@"persistentID"];
//	NSNumber *preservedNowPlayingTrackPlaybackTime = [nowPlayingTrackInfo objectForKey:@"playbackTime"];
//	NSNumber *preservedShuffleMode = [nowPlayingTrackInfo objectForKey:@"shuffleMode"];
//	NSNumber *preservedRepeatMode = [nowPlayingTrackInfo objectForKey:@"repeatMode"];
//	LMMusicShuffleMode nowPlayingShuffleMode = ([preservedShuffleMode integerValue] == 1) ? LMMusicShuffleModeOn : LMMusicShuffleModeOff;
//	LMMusicRepeatMode nowPlayingRepeatMode = (LMMusicRepeatMode)[preservedRepeatMode integerValue];
//	NSLog(@"shuffle mode %d repeat %d", nowPlayingShuffleMode, nowPlayingRepeatMode);
//	LMMusicTrack *nowPlayingTrack = nil;
//
//
//	if(!allPersistentIDsString || !nowPlayingTrackInfo){
//		NSLog(@"Rejecting load, '%@' '%@'", allPersistentIDsString, nowPlayingTrackInfo);
//		self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeOff;
////		self.nowPlayingWasSetWithinLigniteMusic = NO;
//		return;
//	}
//
//	if(!systemNowPlayingTrack){
//		playbackTime = [preservedNowPlayingTrackPlaybackTime integerValue];
//	}
//
//	NSArray *persistentIDsArray = [allPersistentIDsString componentsSeparatedByString:@","];
//
//
//
//	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
//	NSMutableArray *nowPlayingArray = [NSMutableArray new];
//	NSInteger itemCount = 0;
//
//	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//	formatter.numberStyle = NSNumberFormatterDecimalStyle;
//
//	for(NSString *persistentIDString in persistentIDsArray){
//		NSNumber *persistentID = [formatter numberFromString:persistentIDString];
//
//		if(persistentID){
//			MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:persistentID forProperty:MPMediaItemPropertyPersistentID];
//
//			MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];
//
//			NSArray *items = mediaQuery.items;
//			for(MPMediaItem *item in items){
//				itemCount++;
//				[nowPlayingArray addObject:item];
//
//				if([persistentID isEqual:preservedNowPlayingTrackPersistentID]){
//					NSLog(@"This was the now playing track: %@ (below)", item.title);
////					nowPlayingTrack = item;
//				}
//
//				if(persistentID.longLongValue == systemNowPlayingPersistentID){
//					preservedQueueContainsSystemNowPlayingTrack = YES;
//
//					nowPlayingTrack = item;
//
//					NSLog(@"Got system track from queue: %@", item.title);
//				}
//
//				//			NSLog(@"Got item %@", item.title);
//			}
//		}
//		else{ //The saved collection is broken, don't load it
////			self.nowPlayingWasSetWithinLigniteMusic = NO;
//			return;
//		}
//	}
//
//
//
//	if(!preservedQueueContainsSystemNowPlayingTrack){
//		NSLog(@"The preserved queue does not contain the now playing track. I'm going to dump it all, sorry.");
////		[self stop];
//		return;
//	}
//
//	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
//
//	NSLog(@"Got %ld items in %f seconds.", (long)itemCount, endTime-startTime);
//
//	self.shuffleMode = nowPlayingShuffleMode;
//	self.repeatMode = nowPlayingRepeatMode;
//
//	MPMediaItemCollection *oldNowPlayingCollection = [MPMediaItemCollection collectionWithItems:nowPlayingArray];
//
//	if(!nowPlayingTrack){
//		nowPlayingTrack = [oldNowPlayingCollection.items objectAtIndex:0];
//	}
//
//	NSUInteger indexOfNowPlayingTrack = [oldNowPlayingCollection.items indexOfObject:nowPlayingTrack];
//
//	NSLog(@"Got the queue from storage successfully with %d items. The now playing track is: %@.", (int)oldNowPlayingCollection.count, nowPlayingTrack.title);
//
//	self.lastTrackSetInLigniteMusicPersistentID = nowPlayingTrack.persistentID;
//
//	[self restoreNowPlayingCollection:oldNowPlayingCollection
//					  nowPlayingTrack:nowPlayingTrack
//						 playbackTime:playbackTime
//				   collectionIsSorted:YES
//						 inBackground:NO];
//	[self setIndexOfNowPlayingTrack:indexOfNowPlayingTrack];
}

- (void)prepareQueueForBackgrounding {
	if(self.queueRequiresReload){
		NSLog(@"Queue requires reload for the background. Reloading...");
		self.queueRequiresReload = NO;
		
		[self restoreNowPlayingCollection:self.nowPlayingCollection
						  nowPlayingTrack:self.nowPlayingTrack
							 playbackTime:self.currentPlaybackTime
					   collectionIsSorted:NO
							 inBackground:YES];
		NSLog(@"Done reloading queue for the background.");
	}
}

- (void)addTrackToQueue:(LMMusicTrack*)trackToAdd {
	if(!self.nowPlayingWasSetWithinLigniteMusic){
		NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
		
		for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
			if([delegate respondsToSelector:@selector(userAttemptedToModifyQueueThatIsManagedByiOS)]){
				[delegate userAttemptedToModifyQueueThatIsManagedByiOS];
			}
		}
		return;
	}
	
	BOOL isNewQueue = self.nowPlayingCollectionSorted.count == 0;
	if(isNewQueue){
		LMMusicTrackCollection *newQueue = [[LMMusicTrackCollection alloc]initWithItems:@[ trackToAdd ]];
		LMMusicTrackCollection *newQueue1 = [[LMMusicTrackCollection alloc]initWithItems:@[ trackToAdd ]];
		self.nowPlayingCollectionSorted = newQueue;
		self.nowPlayingCollectionShuffled = newQueue1;
	}
	else{
		NSMutableArray *currentListOfSortedTracks = [NSMutableArray arrayWithArray:self.nowPlayingCollectionSorted.items];
		[currentListOfSortedTracks insertObject:trackToAdd atIndex:self.indexOfNowPlayingTrack + 1];
		self.nowPlayingCollectionSorted = [[LMMusicTrackCollection alloc] initWithItems:[NSArray arrayWithArray:currentListOfSortedTracks]];
		
		NSMutableArray *currentListOfShuffledTracks = [NSMutableArray arrayWithArray:self.nowPlayingCollectionShuffled.items];
		[currentListOfShuffledTracks insertObject:trackToAdd atIndex:self.indexOfNowPlayingTrack + 1];
		self.nowPlayingCollectionShuffled = [[LMMusicTrackCollection alloc] initWithItems:[NSArray arrayWithArray:currentListOfShuffledTracks]];
	}
	
	if(isNewQueue){
		[self setNowPlayingCollection:self.nowPlayingCollection];
		[self play];
	}
	else{
		self.queueRequiresReload = YES;
	}
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackAddedToQueue:)]){
			[delegate trackAddedToQueue:trackToAdd];
		}
	}
}

- (void)removeTrackFromQueue:(LMMusicTrack*)trackToRemove {
	BOOL wasNowPlayingTrack = [self.nowPlayingTrack isEqual:trackToRemove];
	
	NSMutableArray *currentListOfSortedTracks = [NSMutableArray arrayWithArray:self.nowPlayingCollectionSorted.items];
	NSMutableArray *currentListOfShuffledTracks = [NSMutableArray arrayWithArray:self.nowPlayingCollectionShuffled.items];
	
	[currentListOfSortedTracks removeObject:trackToRemove];
	[currentListOfShuffledTracks removeObject:trackToRemove];
	
	self.nowPlayingCollectionSorted = [[LMMusicTrackCollection alloc]initWithItems:currentListOfSortedTracks];
	self.nowPlayingCollectionShuffled = [[LMMusicTrackCollection alloc]initWithItems:currentListOfShuffledTracks];
	
	if(wasNowPlayingTrack){
		[self setNowPlayingCollection:self.nowPlayingCollection];
	}
	else{
		self.indexOfNowPlayingTrack = [self.nowPlayingCollection.items indexOfObject:self.nowPlayingTrack];
		self.queueRequiresReload = YES;
	}
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackRemovedFromQueue:)]){
			[delegate trackRemovedFromQueue:trackToRemove];
		}
	}
}

- (void)prepareQueueModification {
	self.lastTrackMovedInQueue = nil;
}

- (void)finishQueueModification {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackMovedInQueue:)]){
			[delegate trackMovedInQueue:self.lastTrackMovedInQueue];
		}
	}
}

- (void)moveTrackInQueueFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex {
	NSMutableArray *moveArray = self.shuffleMode ? [NSMutableArray arrayWithArray:self.nowPlayingCollectionShuffled.items] : [NSMutableArray arrayWithArray:self.nowPlayingCollectionSorted.items];
	
	LMMusicTrack *currentMusicTrack = [moveArray objectAtIndex:oldIndex];
	[moveArray removeObjectAtIndex:oldIndex];
	[moveArray insertObject:currentMusicTrack atIndex:newIndex];
	
	if(self.shuffleMode){
		self.nowPlayingCollectionShuffled = [[LMMusicTrackCollection alloc]initWithItems:moveArray];
	}
	else{
		self.nowPlayingCollectionSorted = [[LMMusicTrackCollection alloc]initWithItems:moveArray];
	}
	
	//	[self setNowPlayingCollection:self.shuffleMode ? self.nowPlayingCollectionShuffled : self.nowPlayingCollectionSorted];
//	[self.systemMusicPlayer setQueueWithItemCollection:self.shuffleMode ? self.nowPlayingCollectionShuffled : self.nowPlayingCollectionSorted];
	self.queueRequiresReload = YES;
	
	self.indexOfNowPlayingTrack = [moveArray indexOfObject:self.nowPlayingTrack];
}

- (NSString*)favouriteKeyForTrack:(LMMusicTrack*)track {
	return [NSString stringWithFormat:@"favourite_%llu", track.persistentID];
}

- (LMMusicTrackCollection*)favouritesTrackCollection {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSArray *allKeys = [userDefaults.dictionaryRepresentation allKeys];
	NSMutableArray<LMMusicTrack*>* favouritesTracks = [NSMutableArray new];
	for(NSString *key in allKeys){
		if([key containsString:@"favourite_"]){
			if([userDefaults boolForKey:key] == YES){ //Is a favourite
				NSRange range = [key rangeOfString:@"favourite_"];
				
				NSString *persistentIDString = [key substringFromIndex:range.location + range.length];
				
				NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
				formatter.numberStyle = NSNumberFormatterDecimalStyle;
				NSNumber *persistentIDNumber = [formatter numberFromString:persistentIDString];
				
				MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:persistentIDNumber
																					   forProperty:MPMediaItemPropertyPersistentID];
				MPMediaQuery *query = [[MPMediaQuery alloc] init];
				[query addFilterPredicate:predicate];
				
				[favouritesTracks addObjectsFromArray:query.items];
			}
		}
	}
	
	NSLog(@"Got %ld favourites, the first being %@.", favouritesTracks.count, [favouritesTracks firstObject].title);
	
	return [[LMMusicTrackCollection alloc] initWithItems:[favouritesTracks sortedArrayUsingDescriptors:@[ [self alphabeticalSortDescriptorForSortKey:@"title"] ]]];
	//return [[self queryCollectionsForMusicType:LMMusicTypeAlbums] firstObject];
}

- (void)addTrackToFavourites:(LMMusicTrack*)track {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:YES forKey:[self favouriteKeyForTrack:track]];
	[userDefaults synchronize];
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackAddedToFavourites:)]){
			[delegate trackAddedToFavourites:track];
		}
	}
}

- (void)removeTrackFromFavourites:(LMMusicTrack*)track {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:NO forKey:[self favouriteKeyForTrack:track]];
	[userDefaults synchronize];
	
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(trackRemovedFromFavourites:)]){
			[delegate trackRemovedFromFavourites:track];
		}
	}
}

- (void)logArray:(NSMutableArray*)array {
	NSMutableString *string = [NSMutableString stringWithFormat:@""];
	for(LMMusicTrack *track in array){
		[string appendString:[NSString stringWithFormat:@"%@, ", track.title]];
	}
	NSLog(@"%@", string);
}

- (BOOL)nowPlayingCollectionIsEqualTo:(LMMusicTrackCollection*)musicTrackCollection {
	return [self.nowPlayingCollectionShuffled isEqual:musicTrackCollection] || [self.nowPlayingCollectionSorted isEqual:musicTrackCollection];
}

- (void)reshuffleSortedCollection {
	NSMutableArray *shuffledArray = [NSMutableArray arrayWithArray:self.nowPlayingCollectionSorted.items];
//	if(@available(iOS 10, *)){
////		NSArray *array = nil;
//		shuffledArray = [NSMutableArray arrayWithArray:[self.nowPlayingCollectionSorted.items sortedArrayUsingComparator:^NSComparisonResult(LMMusicTrack* obj1, LMMusicTrack* obj2) {
//
//			return (obj1.albumPersistentID != obj2.albumPersistentID) && (obj1.artistPersistentID != obj2.artistPersistentID);
//		}]];
//	}
//	else{
		[self shuffleArrayOfTracks:shuffledArray];
//	}
	
	if(self.nowPlayingTrack){
		NSInteger indexOfNowPlayingTrackInShuffledArray = -1;
		for(NSInteger i = 0; i < shuffledArray.count; i++){
			LMMusicTrack *musicTrack = [shuffledArray objectAtIndex:i];
			if(musicTrack.persistentID == self.nowPlayingTrack.persistentID){
				indexOfNowPlayingTrackInShuffledArray = i;
				break;
			}
		}
		
		if(indexOfNowPlayingTrackInShuffledArray > -1){
			[shuffledArray exchangeObjectAtIndex:indexOfNowPlayingTrackInShuffledArray withObjectAtIndex:0];
		}
	}
	
	self.nowPlayingCollectionShuffled = [MPMediaItemCollection collectionWithItems:shuffledArray];
}

- (LMMusicTrackCollection*)nowPlayingCollection {
//	MPMediaQuery *query = [[MPMusicPlayerController systemMusicPlayer] queueAsQuery];

//	NSLog(@"[LMMusicPlayer] Got now playing query %@ with %d songs", query, (int)query.items.count);
//
//	return [LMMusicTrackCollection collectionWithItems:query.items];
	
	if(_shuffleMode == LMMusicShuffleModeOn){
		return self.nowPlayingCollectionShuffled;
	}
	return self.nowPlayingCollectionSorted;
}

- (void)setNowPlayingCollection:(LMMusicTrackCollection*)nowPlayingCollection {
	//	self.nowPlayingWasSetWithinLigniteMusic = YES;
	
	if(!nowPlayingCollection){
		self.nowPlayingCollectionSorted = nil;
		self.nowPlayingCollectionShuffled = nil;
		self.nowPlayingTrack = nil;
		
		[self.systemMusicPlayer stop];
	}
	else{
		if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
			self.nowPlayingCollectionSorted = nowPlayingCollection;
			[self reshuffleSortedCollection];
			
			if(!self.nowPlayingCollection){
				[self.systemMusicPlayer setQueueWithQuery:self.bullshitQuery];
				[self.systemMusicPlayer setNowPlayingItem:nil];
			}
			NSLog(@"Setting now playing collection to %@", nowPlayingCollection);
			if(nowPlayingCollection.count > 0){
				[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
				[self.systemMusicPlayer setNowPlayingItem:[[self.nowPlayingCollection items] objectAtIndex:0]];
			}
			else{
				self.nowPlayingCollection = nil;
			}
		}
	}
}

- (void)restoreNowPlayingCollection:(LMMusicTrackCollection *)nowPlayingCollection
					nowPlayingTrack:(LMMusicTrack*)nowPlayingTrack
					   playbackTime:(NSTimeInterval)playbackTime
				 collectionIsSorted:(BOOL)collectionIsSorted
					   inBackground:(BOOL)background {
//	self.nowPlayingWasSetWithinLigniteMusic = YES;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		if(collectionIsSorted){ //Actual restoration instead of backgrounding of queue that needs reloading
			self.nowPlayingCollectionSorted = nowPlayingCollection;
			[self reshuffleSortedCollection];
		}
		
		if(!self.nowPlayingCollection){
			[self.systemMusicPlayer setQueueWithQuery:self.bullshitQuery];
			[self.systemMusicPlayer setNowPlayingItem:nil];
		}
		NSLog(@"Setting now playing collection to %@ with track %@ playback time %f", nowPlayingCollection, nowPlayingTrack.title, self.systemMusicPlayer.currentPlaybackTime);
		
		[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
		[self.systemMusicPlayer setNowPlayingItem:nowPlayingTrack];
//		[self setNowPlayingTrack:nowPlayingTrack];

		self.playbackTimeToRestoreBecauseQueueChangesAreFuckingStupid = playbackTime;
		
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.05 block:^{
			[self setCurrentPlaybackTime:playbackTime];
			NSLog(@"Set playback time to %f", playbackTime);
		} repeats:NO];
		
		if(background){
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
			[[NSRunLoop currentRunLoop] run];
		}
	}
}

- (LMMusicPlayerType)playerType {
	return LMMusicPlayerTypeAppleMusic;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
	self.systemMusicPlayer.currentPlaybackTime = currentPlaybackTime;
	
	_currentPlaybackTime = currentPlaybackTime;
	
	[self updateNowPlayingTimeDelegates:YES];
}

- (NSTimeInterval)currentPlaybackTime {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer && self.audioPlayer){
		return self.audioPlayer.currentTime;
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic) {
		return self.systemMusicPlayer.currentPlaybackTime;
	}
	return _currentPlaybackTime;
}

- (void)updatePlaybackModeDelegates {
	NSArray<id<LMMusicPlayerDelegate>> *safeDelegates = [[NSArray alloc]initWithArray:self.delegates];
	
	for(id<LMMusicPlayerDelegate> delegate in safeDelegates){
		if([delegate respondsToSelector:@selector(musicPlaybackModesDidChange:repeatMode:)]){
			[delegate musicPlaybackModesDidChange:self.shuffleMode repeatMode:self.repeatMode];
		}
	}
}

- (void)setRepeatMode:(LMMusicRepeatMode)repeatMode {
	_repeatMode = repeatMode;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		MPMusicRepeatMode systemRepeatModes[4] = {
			MPMusicRepeatModeNone,
			MPMusicRepeatModeNone,
			MPMusicRepeatModeAll,
			MPMusicRepeatModeOne
		};
		self.systemMusicPlayer.repeatMode = systemRepeatModes[repeatMode];
	}
	
	[self updatePlaybackModeDelegates];
}

- (LMMusicRepeatMode)repeatMode {
	return _repeatMode;
}

- (void)setShuffleMode:(LMMusicShuffleMode)shuffleMode {
	if(!self.nowPlayingWasSetWithinLigniteMusic){
		if(self.systemMusicPlayer.shuffleMode != MPMusicShuffleModeSongs){
			self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeSongs;
		}
		else{
			self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeOff;
		}
		
		[self updatePlaybackModeDelegates];
		return;
	}
	
	_shuffleMode = shuffleMode;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		if(!self.nowPlayingCollection){
			return;
		}
		if(shuffleMode == LMMusicShuffleModeOn){
			[self reshuffleSortedCollection];
		}
		
		self.queueRequiresReload = YES;
		
//		[self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
//
//		if(shuffleMode != LMMusicShuffleModeOn){
//			for(NSInteger i = 0; i < self.nowPlayingCollection.items.count; i++){
//				LMMusicTrack *musicTrack = [self.nowPlayingCollection.items objectAtIndex:i];
//				if(musicTrack.persistentID == self.nowPlayingTrack.persistentID){
//					CGFloat currentPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
//					[self.systemMusicPlayer setNowPlayingItem:musicTrack];
//					[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
//						self.systemMusicPlayer.currentPlaybackTime = currentPlaybackTime;
//						NSLog(@"Playback time is %f", currentPlaybackTime);
//					} repeats:NO];
//					break;
//				}
//			}
//		}
		
		NSUInteger indexOfNowPlayingTrack = [self.nowPlayingCollection.items indexOfObject:self.systemMusicPlayer.nowPlayingItem];
		self.indexOfNowPlayingTrack = indexOfNowPlayingTrack;
	}
	
	[self updatePlaybackModeDelegates];
}

- (LMMusicShuffleMode)shuffleMode {
	if(!self.nowPlayingWasSetWithinLigniteMusic){
		return (self.systemMusicPlayer.shuffleMode == MPMusicShuffleModeSongs) ? LMMusicShuffleModeOn : LMMusicShuffleModeOff;
	}
	return _shuffleMode;
}

@end
