//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"
#import "NSTimer+Blocks.h"

@import StoreKit;

@interface LMMusicPlayer() <AVAudioPlayerDelegate
#ifdef SPOTIFY
, SPTAudioStreamingDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate
#endif

>

//All Spotify-only variables
#ifdef SPOTIFY

/**
 The Spotify audio player.
 */
@property SPTAudioStreamingController *spotifyPlayer;

/**
 The current playback time of the Spotify player, made into a variable since a delegate function provides the info.
 */
@property NSTimeInterval spotifyPlayerCurrentPlaybackTime;

#endif
//End all Spotify-only variables


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

/**
 Whether or not the user has set music within the app. If NO, the app should reject requests to change the song and whatnot from the system music player. Gotta love walled gardens.
 */
@property BOOL musicWasUserSet;

/**
 The now playing collection which is sorted.
 */
@property LMMusicTrackCollection *nowPlayingCollectionSorted;

/**
 The now playing collection which is shuffled.
 */
@property LMMusicTrackCollection *nowPlayingCollectionShuffled;

@end

@implementation LMMusicPlayer

@synthesize nowPlayingTrack = _nowPlayingTrack;
@synthesize nowPlayingCollection = _nowPlayingCollection;
@synthesize playerType = _playerType;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize repeatMode = _repeatMode;
@synthesize shuffleMode = _shuffleMode;
@synthesize systemMusicPlayer = _systemMusicPlayer;

MPMediaGrouping associatedMediaTypes[] = {
	MPMediaGroupingArtist,
	MPMediaGroupingAlbum,
	MPMediaGroupingTitle,
	MPMediaGroupingPlaylist,
	MPMediaGroupingGenre,
	MPMediaGroupingComposer,
	MPMediaGroupingAlbum //Compilations, actually. The queries adjust for this.
};

- (MPMusicPlayerController*)systemMusicPlayer {
#ifdef SPOTIFY
	NSLog(@"!!!\n!!!\n!!! Someone called upon the system music player... Disappointing. !!!\n!!!\n!!!");
	return nil;
#else
	return [MPMusicPlayerController systemMusicPlayer];
#endif
}

- (void)setSystemMusicPlayer:(MPMusicPlayerController *)systemMusicPlayer {
	//Do nothing
}

#ifdef SPOTIFY
- (void)activateSpotifyPlayer {
	NSLog(@"Attempting to activate Spotify audio player...");
	
	SPTAuth *authorization = [SPTAuth defaultInstance];
	SPTSession *session = authorization.session;
	if(!session.isValid){
		NSLog(@"Session isn't valid, renewing session before activating audio player.");
		[authorization renewSession:session callback:^(NSError *error, SPTSession *newSession) {
			if(error){
				NSLog(@"Error renewing session: %@", error);
				return;
			}
			
			authorization.session = newSession;
			
			[self activateSpotifyPlayer];
		}];
	}
	else{
		NSLog(@"Session valid. Now attempting to activate.");
		
		NSError *error = nil;
		self.spotifyPlayer = [SPTAudioStreamingController sharedInstance];
		if ([self.spotifyPlayer startWithClientId:authorization.clientID audioController:nil allowCaching:NO error:&error]) {
			self.spotifyPlayer.delegate = self;
			self.spotifyPlayer.playbackDelegate = self;
//			self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
			[self.spotifyPlayer loginWithAccessToken:session.accessToken];
		} else {
			self.spotifyPlayer = nil;
			
			NSLog(@"Error activating Spotify audio player: %@", [error description]);
		}
	}
}

#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
	NSLog(@"!!!!!!!! Got a message from Spotify, holy fuck!!! %@", message);
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
	NSLog(isPlaying ? @"Spotify is playing" : @"Spotify isn't playing");
	if (isPlaying) {
		[self activateAudioSession];
	} else {
		[self deactivateAudioSession];
	}
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeMetadata:(SPTPlaybackMetadata *)metadata {
	NSLog(@"Spotify metadata changed %@", metadata);
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceivePlaybackEvent:(SpPlaybackEvent)event withName:(NSString *)name {
	NSLog(@"didReceivePlaybackEvent: %zd %@", event, name);
	NSLog(@"isPlaying=%d isRepeating=%d isShuffling=%d isActiveDevice=%d positionMs=%f",
		  self.spotifyPlayer.playbackState.isPlaying,
		  self.spotifyPlayer.playbackState.isRepeating,
		  self.spotifyPlayer.playbackState.isShuffling,
		  self.spotifyPlayer.playbackState.isActiveDevice,
		  self.spotifyPlayer.playbackState.position);
}

- (void)audioStreamingDidLogout:(SPTAudioStreamingController *)audioStreaming {
	NSLog(@"Logout of Spotify");
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveError:(NSError* )error {
	NSLog(@"Spotify got an error, oh boy: %zd %@", error.code, error.localizedDescription);
	
//	if (error.code == SPErrorNeedsPremium) {
//		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Premium account required" message:@"Premium account is required to showcase application functionality. Please login using premium account." preferredStyle:UIAlertControllerStyleAlert];
//		[alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
//			[self closeSession];
//		}]];
//		[self presentViewController:alert animated:YES completion:nil];
//		
//	}
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePosition:(NSTimeInterval)position {
	NSLog(@"Streaming changed position to %f", position);
	
	self.spotifyPlayerCurrentPlaybackTime = position;
	
	[self updateNowPlayingTimeDelegates];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSString *)trackUri {
	NSLog(@"Starting %@", trackUri);
	NSLog(@"Source %@", self.spotifyPlayer.metadata.currentTrack.playbackSourceUri);
	// If context is a single track and the uri of the actual track being played is different
	// than we can assume that relink has happended.
	BOOL isRelinked = [self.spotifyPlayer.metadata.currentTrack.playbackSourceUri containsString:@"spotify:track"]
	&& ![self.spotifyPlayer.metadata.currentTrack.playbackSourceUri isEqualToString:trackUri];
	NSLog(@"Relinked %d", isRelinked);
	
	self.indexOfNowPlayingTrack = self.spotifyPlayer.metadata.currentTrack.indexInContext;
	if(self.spotifyPlayerCurrentPlaybackTime != 0){
		self.currentPlaybackTime = self.spotifyPlayerCurrentPlaybackTime;
	}
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicTrackDidChange:self.nowPlayingTrack];
	}
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStopPlayingTrack:(NSString *)trackUri {
	NSLog(@"Finishing: %@", trackUri);
}

- (void)audioStreamingDidLogin:(SPTAudioStreamingController *)audioStreaming {
	NSLog(@"Clear to play tunes.");
	//    [self.player playSpotifyURI:@"spotify:user:spotify:playlist:2yLXxKhhziG2xzy7eyD4TD" startingWithIndex:0 startingWithPosition:10 callback:^(NSError *error) {
	//        if (error != nil) {
	//            NSLog(@"*** failed to play: %@", error);
	//            return;
	//        }
	//    }];
}

#pragma mark - Audio Session

- (void)activateAudioSession
{
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
										   error:nil];
	[[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)deactivateAudioSession
{
	[[AVAudioSession sharedInstance] setActive:NO error:nil];
}

#endif

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
		
		self.playerType = LMMusicPlayerTypeAppleMusic;
#ifdef SPOTIFY
		self.playerType = LMMusicPlayerTypeSpotify;
		
		[self activateSpotifyPlayer];
#else
		[self loadNowPlayingState];
#endif
		self.delegates = [NSMutableArray new];
		self.delegatesSubscribedToCurrentPlaybackTimeChange = [NSMutableArray new];
		self.delegatesSubscribedToLibraryDidChange = [NSMutableArray new];
        if(self.repeatMode == LMMusicRepeatModeDefault){
            self.repeatMode = LMMusicRepeatModeNone;
        }
        self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeOff;
		self.previousPlaybackTime = self.currentPlaybackTime;
		
		self.autoPlay = (self.systemMusicPlayer.playbackState == MPMusicPlaybackStatePlaying);
		
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
		[[AVAudioSession sharedInstance] setActive:YES error:nil];
		
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter
		 addObserver:self
		 selector:@selector(audioRouteChanged:)
		 name:AVAudioSessionRouteChangeNotification
		 object:nil];
		
#ifndef SPOTIFY
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
#endif
		
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
	
#ifndef SPOTIFY
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self
	 name:           MPMusicPlayerControllerNowPlayingItemDidChangeNotification
	 object:         self.systemMusicPlayer];
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self
	 name:           MPMusicPlayerControllerPlaybackStateDidChangeNotification
	 object:         self.systemMusicPlayer];
	
	[self.systemMusicPlayer endGeneratingPlaybackNotifications];
#endif
}

+ (LMMusicPlayer*)sharedMusicPlayer {
//    return nil;
    
	static LMMusicPlayer *sharedPlayer;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPlayer = [self new];
		sharedPlayer.pebbleManager = [LMPebbleManager sharedPebbleManager];
		[sharedPlayer.pebbleManager setManagerMusicPlayer:sharedPlayer];
	});
	return sharedPlayer;
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

- (void)updateNowPlayingTimeDelegates {
	for(int i = 0; i < self.delegatesSubscribedToCurrentPlaybackTimeChange.count; i++){
		id<LMMusicPlayerDelegate> delegate = [self.delegatesSubscribedToCurrentPlaybackTimeChange objectAtIndex:i];
#ifdef SPOTIFY
		[delegate musicCurrentPlaybackTimeDidChange:self.spotifyPlayerCurrentPlaybackTime];
#else
		[delegate musicCurrentPlaybackTimeDidChange:self.currentPlaybackTime];
#endif
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
#ifdef SPOTIFY
	NSLog(@"Can't change time on Spotify yet");
#else
	self.audioPlayer.currentTime = positionEvent.positionTime;
	[self reloadInfoCenter:self.audioPlayer.isPlaying];
#endif
	return MPRemoteCommandHandlerStatusSuccess;
}

- (void)keepShuffleModeInLine {
    if(self.systemMusicPlayer.shuffleMode != MPMusicShuffleModeOff){
        self.systemMusicPlayer.shuffleMode = MPMusicShuffleModeOff;
    }
}

- (void)currentPlaybackTimeChangeFireTimer:(BOOL)adjustForDifference {
	__weak id weakSelf = self;
	
    [self keepShuffleModeInLine];
    
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
//	if([self.nowPlayingTrack artwork]){
//		[newInfo setObject:[self.nowPlayingTrack artwork] forKey:MPMediaItemPropertyArtwork];
//	}
	[newInfo setObject:@(isPlaying) forKey:MPNowPlayingInfoPropertyPlaybackRate];
	
	//	NSLog(@"Allahu is playing %d: %@", self.audioPlayer.isPlaying, newInfo);
	
	infoCenter.nowPlayingInfo = newInfo;
}

- (void)systemMusicPlayerTrackChanged:(id)sender {
	BOOL autoPlay = self.audioPlayer.isPlaying;
	
    [self keepShuffleModeInLine];
    
	if(!self.musicWasUserSet){
		return;
	}
	
//	NSLog(@"System music changed %@", self.systemMusicPlayer.nowPlayingItem);
	
	LMMusicTrack *newTrack = self.systemMusicPlayer.nowPlayingItem;
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

- (void)systemMusicPlayerStateChanged:(id)sender {
    [self keepShuffleModeInLine];
    
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
	
	for(int i = 0; i < self.delegates.count; i++){
		id delegate = [self.delegates objectAtIndex:i];
		[delegate musicPlaybackStateDidChange:self.playbackState];
	}
}

- (void)audioRouteChanged:(id)notification {
	NSDictionary *info = [notification userInfo];
	
	NSLog(@"Audio route changed %@", info);
	
	AVAudioSessionRouteChangeReason changeReason = [[info objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
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

#ifndef SPOTIFY
- (void)mediaLibraryContentsChanged:(id)notification {
	NSLog(@"Library changed, called by %@!!!", [[notification class] description]);
	
	for(int i = 0; i < self.delegatesSubscribedToLibraryDidChange.count; i++){
		[[self.delegatesSubscribedToLibraryDidChange objectAtIndex:i] musicLibraryDidChange];
	}
}
#endif

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

- (NSString*)firstLetterForString:(NSString*)string {
	if(string == nil || string.length < 1){
		return @"?";
	}
	return [[NSString stringWithFormat:@"%C", [string characterAtIndex:0]] uppercaseString];
}

- (NSDictionary*)lettersAvailableDictionaryForMusicTrackCollectionArray:(NSArray<LMMusicTrackCollection*>*)collectionArray
												withAssociatedMusicType:(LMMusicType)musicType {
#ifdef SPOTIFY
	return @{};
#else
	NSUInteger lastCollectionIndex = 0;
	
	NSMutableDictionary *lettersDictionary = [NSMutableDictionary new];
	
	BOOL isTitles = (musicType == LMMusicTypeTitles);
	
	LMMusicTrackCollection *firstTrackCollection = nil;
	if(isTitles && collectionArray.count > 0){
		firstTrackCollection = [collectionArray objectAtIndex:0];
	}
	
	NSUInteger countToUse = isTitles ? firstTrackCollection.count : collectionArray.count;
	
	NSString *letters = @"#ABCDEFGHIJKLMNOPQRSTUVWXYZ?";
	for(int i = 0; i < letters.length; i++){
		NSString *locationLetter = [NSString stringWithFormat: @"%C", [letters characterAtIndex:i]];
		
		for(NSUInteger collectionIndex = lastCollectionIndex; collectionIndex < countToUse; collectionIndex++){
			NSString *trackLetter = @"?";
			
			LMMusicTrackCollection *musicCollection = nil;
			LMMusicTrack *musicTrack = nil;
			
			if(isTitles){
				musicCollection = firstTrackCollection;
				musicTrack = [firstTrackCollection.items objectAtIndex:collectionIndex];
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
				case LMMusicTypeTitles:
					if(musicTrack.title){
						trackLetter = [self firstLetterForString:musicTrack.title];
					}
					break;
				case LMMusicTypeCompilations:
				case LMMusicTypePlaylists: {
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
#endif
}

- (NSArray<LMMusicTrackCollection*>*)trackCollectionsForMediaQuery:(id)mediaQuery withMusicType:(LMMusicType)musicType {
	
#ifdef SPOTIFY
	NSArray *sortedArray;
	
	sortedArray = [mediaQuery sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *firstCollection, NSDictionary *secondCollection) {
		
		NSDictionary *first = [firstCollection representativeItem];
		NSDictionary *second = [secondCollection representativeItem];
		
		NSString *firstTitle = [first albumTitle];
		NSString *secondTitle = [second albumTitle];
		
		switch(musicType){
			case LMMusicTypeArtists:
				firstTitle = [first artist];
				secondTitle = [second artist];
				break;
			case LMMusicTypeTitles:
				firstTitle = [first title];
				secondTitle = [second title];
				break;
			default:
				break;
		}
		
		return [firstTitle compare:secondTitle];
	}];
	
	return sortedArray;
#else
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
		albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
	}
	
	NSMutableArray *fixedCollections = [NSMutableArray arrayWithArray:[collections sortedArrayUsingDescriptors:@[albumSort]]];
	
	for(LMMusicTrackCollection *collection in fixedCollections){
		if(collection.count == 0){
			[collections removeObject:collection];
		}
	}
	
	//		NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	if(shuffleForDebug){
		NSLog(@"--- Warning: Query is being automatically shuffled. ---");
		[self shuffleArray:collections];
	}
	
	//		NSLog(@"[LMMusicPlayer]: Took %f seconds to complete query.", endingTime-startingTime);
	
	//	NSLog(@"Returning sort");
	
//	NSLog(@"%ld before %ld after", [mediaQuery collections].count, [collections sortedArrayUsingDescriptors:@[albumSort]].count);
	
	return [collections sortedArrayUsingDescriptors:@[albumSort]];
#endif
}

- (NSArray<LMMusicTrackCollection*>*)queryCollectionsForMusicType:(LMMusicType)musicType {
#ifdef SPOTIFY
	NSArray *queryArray = nil;
	switch(musicType) {
		case LMMusicTypeAlbums:
			queryArray = [[LMSpotifyLibrary sharedLibrary] albums];
			break;
		case LMMusicTypeArtists:
			queryArray = [[LMSpotifyLibrary sharedLibrary] artists];
			break;
		case LMMusicTypeTitles:
			queryArray = [[LMSpotifyLibrary sharedLibrary] musicTracks];
			break;
		default:
			NSLog(@"\n\nSpooked! Unknown shitpost\n\n");
			break;
	}
	return [self trackCollectionsForMediaQuery:queryArray withMusicType:musicType];
#else
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
		
		return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
	}
	return nil;
#endif
}

- (NSArray<LMMusicTrackCollection*>*)collectionsForRepresentativeTrack:(LMMusicTrack*)representativeTrack forMusicType:(LMMusicType)musicType {
#ifdef SPOTIFY
	return @[];
#else
	MPMediaGrouping associatedGroupings[] = {
		MPMediaGroupingAlbum, //Artists
		MPMediaGroupingTitle, //Albums
		MPMediaGroupingTitle, //Titles
		MPMediaGroupingTitle, //Playlists
		MPMediaGroupingAlbum, //Genres
		MPMediaGroupingAlbum, //Composers
		MPMediaGroupingTitle  //Compilations
	};
	
	NSArray<NSString*> *associatedPersistentIDProperties = @[
															 MPMediaItemPropertyArtistPersistentID,   //Artists
															 MPMediaItemPropertyAlbumPersistentID,    //Albums
															 MPMediaItemPropertyPersistentID,         //Titles
															 MPMediaPlaylistPropertyName,             //Playlists
															 MPMediaItemPropertyGenrePersistentID,    //Genres
															 MPMediaItemPropertyComposerPersistentID, //Composers
															 MPMediaItemPropertyIsCompilation         //Compilations
															 ];
	
	NSString *associatedProperty = [associatedPersistentIDProperties objectAtIndex:musicType];
	
	MPMediaQuery *query = nil;
	
	query = [MPMediaQuery new];
	query.groupingType = associatedGroupings[musicType];
	
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:[representativeTrack valueForProperty:associatedProperty]
																					  forProperty:associatedProperty
																				   comparisonType:MPMediaPredicateComparisonEqualTo];
	[query addFilterPredicate:musicFilterPredicate];
	
	return [self trackCollectionsForMediaQuery:query withMusicType:musicType];
#endif
}

- (void)skipToNextTrack {
#ifdef SPOTIFY
	[self.spotifyPlayer skipNext:^(NSError *error) {
		if(error){
			NSLog(@"Error skipping to next %@", error);
			return;
		}
		NSLog(@"Good to go (skipped to next)");
	}];
#else
	NSLog(@"Skip to next");
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
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
#endif
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
#ifdef SPOTIFY
	if(self.spotifyPlayerCurrentPlaybackTime > 5){
#else
	if(self.currentPlaybackTime > 5){
#endif
		NSLog(@"Skipping to beginning");
		[self skipToBeginning];
	}
	else{
		NSLog(@"Skipping to previous");
		[self skipToPreviousItem];
	}
}

- (void)skipToBeginning {
	[self setCurrentPlaybackTime:0];
}

- (void)skipToPreviousItem {
#ifdef SPOTIFY
	[self.spotifyPlayer skipPrevious:^(NSError *error) {
		if(error){
			NSLog(@"Error skipping to previous %@", error);
			return;
		}
		NSLog(@"Good to go (skipped to previous)");
	}];
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer skipToPreviousItem];
	}
#endif
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
#ifdef SPOTIFY
	[self.spotifyPlayer setIsPlaying:YES callback:^(NSError *error) {
		if(error){
			NSLog(@"Error setting to playing %@", error);
			return;
		}
		NSLog(@"Success playing Spotify player");
	}];
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePlaying];
		
		//[self.systemMusicPlayer play];
		NSLog(@"Playing");
		[self.audioPlayer setVolume:1 fadeDuration:0.25];
		[self.audioPlayer play];
		[self reloadInfoCenter:YES];
		
		NSLog(@"Done");
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer play];
		
		NSLog(@"BPM %d", (int)self.systemMusicPlayer.nowPlayingItem.beatsPerMinute);
	}
#endif
}

- (void)pause {
#ifdef SPOTIFY
	[self.spotifyPlayer setIsPlaying:NO callback:^(NSError *error) {
		if(error){
			NSLog(@"Error setting to paused %@", error);
			return;
		}
		NSLog(@"Success pausing Spotify player");
	}];
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self changeMusicPlayerState:LMMusicPlaybackStatePaused];
		//[self.systemMusicPlayer pause];
		[self.audioPlayer setVolume:0 fadeDuration:0.25];
		[self autoPauseAudioPlayer];
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer pause];
	}
#endif
}

- (void)stop {
#ifdef SPOTIFY
	NSError *error = nil;
	[self.spotifyPlayer stopWithError:&error];
	
	if(error){
		NSLog(@"Error in stopping player: %@", error);
	}
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		[self.audioPlayer stop];
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		[self.systemMusicPlayer stop];
	}
#endif
}

- (LMMusicPlaybackState)invertPlaybackState {
#ifdef SPOTIFY
	if(self.spotifyPlayer.playbackState.isPlaying){
		[self pause];
		return LMMusicPlaybackStatePaused;
	}
	else{
		[self play];
		return LMMusicPlaybackStatePlaying;
	}
#else
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
			case LMMusicPlaybackStatePlaying:
				[self pause];
				return LMMusicPlaybackStatePaused;
			default:
				[self play];
				return LMMusicPlaybackStatePlaying;
		}
	}
#endif
}

- (BOOL)hasTrackLoaded {
	return (self.nowPlayingTrack.title != nil);
}

- (void)setNowPlayingTrack:(LMMusicTrack*)nowPlayingTrack {
	self.musicWasUserSet = YES;
#ifdef SPOTIFY
	[self.spotifyPlayer playSpotifyURI:[nowPlayingTrack objectForKey:@"uri"] startingWithIndex:0 startingWithPosition:0 callback:^(NSError *playbackError) {
		if(playbackError){
			NSLog(@"Playback error %@", playbackError);
			return;
		}
		NSLog(@"Playing!");
	}];
#else
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
			[self.systemMusicPlayer setNowPlayingItem:associatedMediaItem];
		}
	}
#endif
	_nowPlayingTrack = nowPlayingTrack;
}

- (LMMusicTrack*)nowPlayingTrack {    
	return _nowPlayingTrack;
}
	
- (void)saveNowPlayingState {
	if(!self.nowPlayingCollection){
		NSLog(@"Rejecting save");
		return;
	}
	
	//Save the now playing collection to storage
	NSMutableString *persistentIDString = [NSMutableString new];
	for(LMMusicTrack *track in self.nowPlayingCollectionSorted.items) {
		[persistentIDString appendString:[NSString stringWithFormat:@"%lld,", track.persistentID]];
	}
	
	persistentIDString = [NSMutableString stringWithString:[persistentIDString substringToIndex:persistentIDString.length-1]];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:persistentIDString forKey:DEFAULTS_KEY_NOW_PLAYING_COLLECTION];
	
	
	//Save the now playing track and its state to storage
	NSDictionary *nowPlayingTrackInfo = @{
										  @"persistentID":@(self.nowPlayingTrack.persistentID),
										  @"playbackTime":@((NSInteger)floorf(self.currentPlaybackTime)),
                                          @"shuffleMode":@(self.shuffleMode),
                                          @"repeatMode":@(self.repeatMode)
										  };
	[userDefaults setObject:nowPlayingTrackInfo forKey:DEFAULTS_KEY_NOW_PLAYING_TRACK];
	
	[userDefaults synchronize];
	
	NSLog(@"Saved! %@ %@", persistentIDString, nowPlayingTrackInfo);
}
	
- (void)loadNowPlayingState {
	self.musicWasUserSet = YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *allPersistentIDsString = @"";
//	NSString *allPersistentIDsString = [userDefaults objectForKey:DEFAULTS_KEY_NOW_PLAYING_COLLECTION];
	
	NSDictionary *nowPlayingTrackInfo = [userDefaults objectForKey:DEFAULTS_KEY_NOW_PLAYING_TRACK];
	
	NSLog(@"Got info %@", nowPlayingTrackInfo);
	
	NSNumber *nowPlayingTrackPersistentID = [nowPlayingTrackInfo objectForKey:@"persistentID"];
	NSNumber *nowPlayingTrackPlaybackTime = [nowPlayingTrackInfo objectForKey:@"playbackTime"];
    NSNumber *shuffleMode = [nowPlayingTrackInfo objectForKey:@"shuffleMode"];
    NSNumber *repeatMode = [nowPlayingTrackInfo objectForKey:@"repeatMode"];
    LMMusicShuffleMode nowPlayingShuffleMode = ([shuffleMode integerValue] == 1) ? LMMusicShuffleModeOn : LMMusicShuffleModeOff;
    LMMusicRepeatMode nowPlayingRepeatMode = (LMMusicRepeatMode)[repeatMode integerValue];
    NSLog(@"shuffle mode %d repeat %d", nowPlayingShuffleMode, nowPlayingRepeatMode);
	LMMusicTrack *nowPlayingTrack = nil;
	
	if(!allPersistentIDsString || !nowPlayingTrackInfo){
		NSLog(@"Rejecting load, '%@' '%@'", allPersistentIDsString, nowPlayingTrackInfo);
		self.musicWasUserSet = NO;
		return;
	}
	
	NSArray *persistentIDsArray = [allPersistentIDsString componentsSeparatedByString:@","];
	
	
	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
	NSMutableArray *nowPlayingArray = [NSMutableArray new];
	NSInteger itemCount = 0;
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	
	for(NSString *persistentIDString in persistentIDsArray){
		NSNumber *persistentID = [formatter numberFromString:persistentIDString];
		
		if(persistentID){
			MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:persistentID forProperty:MPMediaItemPropertyPersistentID];
			
			MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];
			
			NSArray *items = mediaQuery.items;
			for(MPMediaItem *item in items){
				itemCount++;
				[nowPlayingArray addObject:item];
				
				if([persistentID isEqual:nowPlayingTrackPersistentID]){
					NSLog(@"This was the now playing track (below)");
					nowPlayingTrack = item;
				}
				
	//			NSLog(@"Got item %@", item.title);
			}
		}
		else{ //The saved collection is broken, don't load it
			self.musicWasUserSet = NO;
			return;
		}
	}
	
	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
	
	NSLog(@"Got %ld items in %f seconds.", (long)itemCount, endTime-startTime);
    
    self.shuffleMode = nowPlayingShuffleMode;
    self.repeatMode = nowPlayingRepeatMode;
	
	MPMediaItemCollection *oldNowPlayingCollection = [MPMediaItemCollection collectionWithItems:nowPlayingArray];
    [self setNowPlayingCollection:oldNowPlayingCollection];
	
	if(!nowPlayingTrack){
		nowPlayingTrack = [oldNowPlayingCollection.items objectAtIndex:0];
	}
	if(!nowPlayingTrackPlaybackTime){
		nowPlayingTrackPlaybackTime = @(0);
	}
	
	NSUInteger indexOfNowPlayingTrack = [oldNowPlayingCollection.items indexOfObject:nowPlayingTrack];
	
	NSLog(@"The previous playing track was %@ with playback time %ld, it's position was %ld", nowPlayingTrack.title, [nowPlayingTrackPlaybackTime integerValue], indexOfNowPlayingTrack);
	
	[self setNowPlayingTrack:nowPlayingTrack];
    if(nowPlayingShuffleMode != LMMusicShuffleModeOn){
        [self setCurrentPlaybackTime:[nowPlayingTrackPlaybackTime integerValue]];
    }
	[self setIndexOfNowPlayingTrack:indexOfNowPlayingTrack];
}
	
- (LMMusicTrackCollection*)nowPlayingCollection {
    if(self.shuffleMode == LMMusicShuffleModeOn){
        return self.nowPlayingCollectionShuffled;
    }
	return self.nowPlayingCollectionSorted;
}
	
- (BOOL)nowPlayingCollectionIsEqualTo:(LMMusicTrackCollection*)musicTrackCollection {
	return [self.nowPlayingCollectionShuffled isEqual:musicTrackCollection] || [self.nowPlayingCollectionSorted isEqual:musicTrackCollection];
}
	
- (void)reshuffleSortedCollection {
    NSMutableArray *shuffledArray = [NSMutableArray arrayWithArray:self.nowPlayingCollectionSorted.items];
    [self shuffleArray:shuffledArray];
	
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

- (void)setNowPlayingCollection:(LMMusicTrackCollection*)nowPlayingCollection {
	self.musicWasUserSet = YES;
#ifdef SPOTIFY
	#warning Set this up too
//	[self.spotifyPlayer ]
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
        self.nowPlayingCollectionSorted = nowPlayingCollection;
        [self reshuffleSortedCollection];
        
		if(!self.nowPlayingCollection){
			[self.systemMusicPlayer setQueueWithQuery:self.bullshitQuery];
			[self.systemMusicPlayer setNowPlayingItem:nil];
		}
		NSLog(@"Setting now playing collection to %@", nowPlayingCollection);
        [self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
		[self.systemMusicPlayer setNowPlayingItem:[[self.nowPlayingCollection items] objectAtIndex:0]];
	}
#endif
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
#ifdef SPOTIFY
	return LMMusicPlayerTypeSpotify;
#else
	NSLog(@"\n\nSaved player type called.\n\n");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	LMMusicPlayerType type = LMMusicPlayerTypeSystemMusicPlayer;
	if([defaults objectForKey:DEFAULTS_KEY_PLAYER_TYPE]){
		type = (LMMusicPlayerType)[defaults integerForKey:DEFAULTS_KEY_PLAYER_TYPE];
	}
	return type;
#endif
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
#ifdef SPOTIFY
	[self.spotifyPlayer seekTo:currentPlaybackTime callback:^(NSError *error) {
		if(error){
			NSLog(@"Error setting current playback time: %@", error);
			return;
		}
		NSLog(@"Success setting current playback time");
	}];
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		NSLog(@"Setting current playback time to %f", currentPlaybackTime);
		
		self.audioPlayer.currentTime = currentPlaybackTime;
		
		_currentPlaybackTime = currentPlaybackTime;
		
		[self updateNowPlayingTimeDelegates];
		
		[self reloadInfoCenter:self.audioPlayer.isPlaying];
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic){
		self.systemMusicPlayer.currentPlaybackTime = currentPlaybackTime;
		_currentPlaybackTime = currentPlaybackTime;
		
		[self updateNowPlayingTimeDelegates];
	}
#endif
}

- (NSTimeInterval)currentPlaybackTime {
#ifdef SPOTIY
	return self.spotifyPlayerCurrentPlaybackTime;
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer && self.audioPlayer){
		return self.audioPlayer.currentTime;
	}
	else if(self.playerType == LMMusicPlayerTypeAppleMusic) {
		return self.systemMusicPlayer.currentPlaybackTime;
	}
	return _currentPlaybackTime;
#endif
}
	
- (void)updatePlaybackModeDelegates {
	for(id<LMMusicPlayerDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(musicPlaybackModesDidChange:repeatMode:)]){
			[delegate musicPlaybackModesDidChange:self.shuffleMode repeatMode:self.repeatMode];
		}
	}
}

- (void)setRepeatMode:(LMMusicRepeatMode)repeatMode {
	_repeatMode = repeatMode;
#ifdef SPOTIFY
	SPTRepeatMode spotifyRepeatModes[4] = {
		SPTRepeatOff,
		SPTRepeatOff,
		SPTRepeatContext,
		SPTRepeatOne
	};
	[self.spotifyPlayer setRepeat:spotifyRepeatModes[repeatMode] callback:^(NSError *error) {
		if(error){
			NSLog(@"Error settings repeat: %@", error);
			return;
		}
		NSLog(@"Success setting repeat");
	}];
#else
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
		MPMusicRepeatMode systemRepeatModes[4] = {
			MPMusicRepeatModeNone,
			MPMusicRepeatModeNone,
			MPMusicRepeatModeAll,
			MPMusicRepeatModeOne
		};
		self.systemMusicPlayer.repeatMode = systemRepeatModes[repeatMode];
	}
#endif
	
	[self updatePlaybackModeDelegates];
}

- (LMMusicRepeatMode)repeatMode {
	return _repeatMode;
}

- (void)setShuffleMode:(LMMusicShuffleMode)shuffleMode {
	_shuffleMode = shuffleMode;
	
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer || self.playerType == LMMusicPlayerTypeAppleMusic){
        if(!self.nowPlayingCollection){
            return;
        }
        if(shuffleMode == LMMusicShuffleModeOn){
            [self reshuffleSortedCollection];
        }
        [self.systemMusicPlayer setQueueWithItemCollection:self.nowPlayingCollection];
		
		if(shuffleMode != LMMusicShuffleModeOn){
			for(NSInteger i = 0; i < self.nowPlayingCollection.items.count; i++){
				LMMusicTrack *musicTrack = [self.nowPlayingCollection.items objectAtIndex:i];
				if(musicTrack.persistentID == self.nowPlayingTrack.persistentID){
					CGFloat currentPlaybackTime = self.systemMusicPlayer.currentPlaybackTime;
					[self.systemMusicPlayer setNowPlayingItem:musicTrack];
					[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
						self.systemMusicPlayer.currentPlaybackTime = currentPlaybackTime;
						NSLog(@"Playback time is %f", currentPlaybackTime);
					} repeats:NO];
					break;
				}
			}
		}
	}
	
	[self updatePlaybackModeDelegates];
}

- (LMMusicShuffleMode)shuffleMode {
	return _shuffleMode;
}

@end
