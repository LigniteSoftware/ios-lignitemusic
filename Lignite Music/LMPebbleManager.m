//
//  LMPebbleManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PebbleKit/PebbleKit.h>
#import <YYImage/YYImage.h>
#import "LMPebbleSettingsView.h"
#import "LMNowPlayingViewController.h"
#import "LMPebbleImage.h"
#import "LMPebbleManager.h"
#import "LMPebbleMessageQueue.h"

@interface LMPebbleManager()<PBPebbleCentralDelegate>

@property (weak, nonatomic) PBWatch *pebbleWatch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property LMPebbleMessageQueue *messageQueue;

//Watch related info
@property WatchInfoModel watchModel;
@property NowPlayingRequestType requestType;
@property uint8_t imageParts;
@property int appMessageSize;
@property BOOL firstPebbleAppOpen;

//The last album art image ID which was sent
@property MPMediaEntityPersistentID lastAlbumArtImage;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPebbleManager

- (void)sendMessageToPebble:(NSDictionary*)toSend {
	[self.messageQueue enqueue:toSend];
}

- (void)pushNowPlayingItemToWatch {
	if(!self.pebbleWatch){
		return;
	}
	
	if(self.watchModel == WATCH_INFO_MODEL_UNKNOWN || self.watchModel == WATCH_INFO_MODEL_MAX){
		self.watchModel = WATCH_INFO_MODEL_PEBBLE_ORIGINAL;
	}
	LMMusicTrack *track = self.musicPlayer.nowPlayingTrack;
	NSString *title = track.title ? track.title : @"";
	NSString *artist = track.artist ? track.artist : @"";
	NSString *album = track.albumTitle ? track.albumTitle : @"";

	NSLog(@"Pushing now playing details to watch.");
	NSDictionary *titleDict = @{MessageKeyNowPlaying: title, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingTitle]};
	[self sendMessageToPebble:titleDict];
	
	NSDictionary *artistDict = @{MessageKeyNowPlaying: artist, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingArtist]};
	[self sendMessageToPebble:artistDict];
	
	NSDictionary *albumDict = @{MessageKeyNowPlaying: album, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingAlbum]};
	[self sendMessageToPebble:albumDict];
	
	//[self pushCurrentStateToWatch];
	
	[NSTimer scheduledTimerWithTimeInterval:0.25
									 target:self
								   selector:@selector(sendAlbumArtImage)
								   userInfo:nil
									repeats:NO];
}

- (BOOL)watchIsRoundScreen {
	switch(self.watchModel){
		case WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_14:
		case WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_20:
			return true;
		default:
			return false;
	}
}

- (BOOL)watchIsBlackAndWhite {
	switch(self.watchModel){
		case WATCH_INFO_MODEL_PEBBLE_ORIGINAL:
		case WATCH_INFO_MODEL_PEBBLE_STEEL:
		case WATCH_INFO_MODEL_PEBBLE_2_HR:
		case WATCH_INFO_MODEL_PEBBLE_2_SE:
			return true;
		default:
			return false;
	}
}

- (CGSize)albumArtSize {
	if([self watchIsRoundScreen]){
		return CGSizeMake(180, 180);
	}
	return CGSizeMake(144, 144);
}

- (void)sendAlbumArtImage {
	if(self.imageParts == 0){
		NSLog(@"Setting to 1");
		self.imageParts = 1;
	}
	
	//TODO: Do not call this on the main thread maybe?
	UIImage *albumArtImage = [self.musicPlayer.nowPlayingTrack albumArt];
	
	//NSLog(@"%d, %d, %d", self.musicPlayer.nowPlayingItem.albumPersistentID == self.lastAlbumArtImage, self.requestType, self.firstPebbleAppOpen);
	
	if(self.musicPlayer.nowPlayingTrack.albumPersistentID == self.lastAlbumArtImage && self.requestType != NowPlayingRequestTypeOnlyTrackInfo && !self.firstPebbleAppOpen){
		NSLog(@"The album art is literally samezies...");
		return;
	}
	else if(self.requestType == NowPlayingRequestTypeOnlyTrackInfo){
		NSLog(@"Only track info, rejecting");
		return;
	}
	self.lastAlbumArtImage = self.musicPlayer.nowPlayingTrack.albumPersistentID;
	self.requestType = NowPlayingRequestTypeOnlyTrackInfo;
	self.firstPebbleAppOpen = NO;
	
	for(uint8_t index = 0; index < self.imageParts; index++){
		
		NSString *imageString = [LMPebbleImage ditherImage:albumArtImage
												  withSize:[self albumArtSize]
											 forTotalParts:self.imageParts
										   withCurrentPart:index
										   isBlackAndWhite:[self watchIsBlackAndWhite]
											  isRoundWatch:[self watchIsRoundScreen]];
		
		if(self.pebbleWatch){
			if(!albumArtImage) {
				NSLog(@"No image!");
				[self sendMessageToPebble:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint16:1], MessageKeyImagePart:[NSNumber numberWithUint8:index]}];
			}
			else {
				NSData *bitmap = [NSData dataWithContentsOfFile:imageString];
				NSLog(@"Got data file %@ with bitmap length %lu", imageString, (unsigned long)[bitmap length]);
				
				size_t length = [bitmap length];
				
				NSDictionary *sizeDict = @{MessageKeyAlbumArtLength: [NSNumber numberWithUint16:length], MessageKeyImagePart:[NSNumber numberWithUint8:index]};
				NSLog(@"Album art size message: %@", sizeDict);
				
				[self sendMessageToPebble:sizeDict];
				
				uint8_t j = 0;
				for(size_t i = 0; i < length; i += self.appMessageSize-1) {
					NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:self.appMessageSize];
					
					NSRange rangeOfBytes = NSMakeRange(i, MIN(self.appMessageSize-1, length - i));
					[outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
					
					NSDictionary *dict = @{MessageKeyAlbumArt: outgoing, MessageKeyAlbumArtIndex:[NSNumber numberWithUint16:j], MessageKeyImagePart:[NSNumber numberWithUint8:index]};
					NSLog(@"Sending index %d", j);
					[self sendMessageToPebble:dict];
					j++;
				}
			}
		}
	}
}

- (void)sendCurrentStateToWatch {
	//NSLog(@"Hi");
	uint16_t current_time = (uint16_t)self.musicPlayer.currentPlaybackTime;
	uint16_t total_time = (uint16_t)self.musicPlayer.nowPlayingTrack.playbackDuration;
	uint8_t metadata[] = {
		[self.musicPlayer playbackState],
		[self.musicPlayer shuffleMode],
		[self.musicPlayer repeatMode],
		total_time >> 8, total_time & 0xFF,
		current_time >> 8, current_time & 0xFF
	};
	//NSLog(@"Current state: %@", [NSData dataWithBytes:metadata length:7]);
	[self sendMessageToPebble:@{MessageKeyCurrentState: [NSData dataWithBytes:metadata length:7]}];
	
}

- (void)pushCurrentStateToWatch {
	[self performSelector:@selector(sendCurrentStateToWatch) withObject:nil afterDelay:0.1];
}

- (void)changeState:(NowPlayingState)state {
	switch(state) {
		case NowPlayingStatePlayPause:
			[self.musicPlayer invertPlaybackState];
			break;
		case NowPlayingStateSkipNext:
			[self.musicPlayer skipToNextTrack];
			break;
		case NowPlayingStateSkipPrevious:
			[self.musicPlayer autoBackThrough];
			break;
		case NowPlayingStateVolumeUp:
//			[self.volumeViewSlider setValue:self.volumeViewSlider.value + 0.0625 animated:YES];
//			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			break;
		case NowPlayingStateVolumeDown:
//			[self.volumeViewSlider setValue:self.volumeViewSlider.value - 0.0625 animated:YES];
//			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			break;
	}
	[self pushCurrentStateToWatch];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
	if (self.pebbleWatch) {
		return;
	}
	NSLog(@"Got new watch %@", watch);
	
	self.pebbleWatch = watch;
	
	self.messageQueue.watch = self.pebbleWatch;
	
	[self.pebbleWatch appMessagesPushUpdate:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint8:1]} onSent:^(PBWatch * _Nonnull watch, NSDictionary * _Nonnull update, NSError * _Nullable error) {
		if(error){
			NSLog(@"Error sending to watch %@", error);
		}
		else{
			NSLog(@"Communications with watch opened.");
		}
	}];
	
	__weak typeof(self) welf = self;
	
	[self.pebbleWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
		__strong typeof(welf) sself = welf;
		if (!sself) {
			NSLog(@"self is destroyed!");
			return NO;
		}
		if(update[MessageKeyPlayTrack]) {
			NSLog(@"Will play track from message %@", update);
//			[self playTrackFromMessage:update withTrackPlayMode:[update[MessageKeyTrackPlayMode] uint8Value]];
		}
		else if(update[MessageKeyRequestLibrary]) {
//			if(update[MessageKeyRequestParent]) {
//				[self sublistRequest:update];
//			} else {
//				[self libraryDataRequest:update];
//			}
		}
		else if(update[MessageKeyNowPlaying]) {
			NSLog(@"Now playing key sent");
			self.requestType = [update[MessageKeyNowPlaying] uint8Value];
			self.watchModel = [update[MessageKeyWatchModel] uint8Value];
			self.imageParts = [update[MessageKeyImagePart] uint8Value];
			self.appMessageSize = [update[MessageKeyAppMessageSize] uint16Value];
			if(update[MessageKeyFirstOpen]){
				NSLog(@"\nIs first app open!\n");
				self.firstPebbleAppOpen = YES;
			}
			NSLog(@"Got request type %d, watch model %d, message size %d and image parts: %d", self.requestType, self.watchModel, self.appMessageSize, self.imageParts);
			
			[self pushNowPlayingItemToWatch];
		}
		else if(update[MessageKeyChangeState]) {
			[self changeState:(NowPlayingState)[update[MessageKeyChangeState] integerValue]];
		}
		else if(update[MessageKeyConnectionTest]){
			[self.messageQueue enqueue:@{ MessageKeyConnectionTest:[NSNumber numberWithInt8:1] }];
		}
		return YES;
	}];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
	NSLog(@"Lost watch %@", self.pebbleWatch);
	if (self.pebbleWatch == watch) {
		self.pebbleWatch = nil;
	}
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.central = [PBPebbleCentral defaultCentral];
		self.central.delegate = self;
		self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
		
		[self.central run];
		
		self.messageQueue = [LMPebbleMessageQueue new];
	}
	else{
		NSLog(@"Error creating Pebble manager!");
	}
	return self;
}

+ (id)sharedPebbleManager {
	static LMPebbleManager *sharedPebbleManager = nil;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPebbleManager = [[self alloc] init];
	});
	return sharedPebbleManager;
}

@end
