//
//  TestViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <PebbleKit/PebbleKit.h>
#import <YYImage/YYImage.h>
#import "LMPebbleSettingsView.h"
#import "LMNowPlayingViewController.h"
#import "LMPebbleImage.h"
#import "LMPebbleMessageQueue.h"

@interface LMNowPlayingViewController () <UIGestureRecognizerDelegate, PBPebbleCentralDelegate>

@property BOOL loadedSubviews;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property MPMediaEntityPersistentID lastAlbumArtImage;

@property LMPebbleMessageQueue *messageQueue;

@property MPMediaItemCollection *currentlyPlayingQueue;

@property WatchInfoModel watchModel;

@property NowPlayingRequestType requestType;

@property uint8_t imageParts;

@property int appMessageSize;

@property BOOL firstPebbleAppOpen;

@property LMPebbleSettingsView *rootSettingsViewController;

@property MPVolumeView *volumeView;
@property UISlider *volumeViewSlider;

@end

@implementation LMNowPlayingViewController

- (void)nowPlayingItemChanged:(id)sender {
	self.requestType = NowPlayingRequestTypeAllData;
    [self pushNowPlayingItemToWatch];
}

- (void)nowPlayingStateChanged:(id) sender {
    [self pushCurrentStateToWatch];
}

- (void)sendMessageToPebble:(NSDictionary*)toSend {
    [self.messageQueue enqueue:toSend];
}

- (void)pushNowPlayingItemToWatch {
    if(!self.watch){
        return;
    }
    
    if(self.watchModel == WATCH_INFO_MODEL_UNKNOWN || self.watchModel == WATCH_INFO_MODEL_MAX){
        self.watchModel = WATCH_INFO_MODEL_PEBBLE_ORIGINAL;
    }
    MPMediaItem *item = [self.musicPlayer nowPlayingItem];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    if(!title) title = @"";
    if(!artist) artist = @"";
    if(!album) album = @"";
    
    NSLog(@"Pushing now playing details to watch.");
    NSDictionary *titleDict = @{MessageKeyNowPlaying: title, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingTitle]};
    [self sendMessageToPebble:titleDict];
    
    NSDictionary *artistDict = @{MessageKeyNowPlaying: artist, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingArtist]};
    [self sendMessageToPebble:artistDict];
    
    NSDictionary *albumDict = @{MessageKeyNowPlaying: album, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingAlbum]};
    [self sendMessageToPebble:albumDict];
    
    [self pushCurrentStateToWatch];
	
    [NSTimer scheduledTimerWithTimeInterval:0.25
                                     target:self
                                   selector:@selector(sendAlbumArtImage)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)sendCurrentStateToWatch {
    //NSLog(@"Hi");
    uint16_t current_time = (uint16_t)[self.musicPlayer currentPlaybackTime];
    uint16_t total_time = (uint16_t)[[[self.musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
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

- (void)handleVolumeChanged:(id)sender{
	NSLog(@"%s - %f", __PRETTY_FUNCTION__, self.volumeViewSlider.value);
}

- (void)changeState:(NowPlayingState)state {
    switch(state) {
        case NowPlayingStatePlayPause:
            //[self playPauseMusic];
            break;
        case NowPlayingStateSkipNext:
            [self.musicPlayer skipToNextItem];
            break;
        case NowPlayingStateSkipPrevious:
            if([self.musicPlayer currentPlaybackTime] < 3) {
                [self.musicPlayer skipToPreviousItem];
            } else {
                [self.musicPlayer skipToBeginning];
            }
            break;
        case NowPlayingStateVolumeUp:
			/*
            [volumeViewSlider setValue:self.musicPlayer.volume + 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			 */
			[self.volumeViewSlider setValue:self.volumeViewSlider.value + 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            //[self.musicPlayer setVolume:[self.musicPlayer volume] + 0.0625];
            break;
        case NowPlayingStateVolumeDown:
			[self.volumeViewSlider setValue:self.volumeViewSlider.value - 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			/*
            [volumeViewSlider setValue:self.musicPlayer.volume - 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			 */
            //[self.musicPlayer setVolume:[self.musicPlayer volume] - 0.0625];
            break;
    }
    [self pushCurrentStateToWatch];
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
    
    CGSize imageSize = [self albumArtSize];
	MPMediaItemArtwork *currentArtwork = [self.musicPlayer.nowPlayingItem artwork];
    UIImage *albumArtImage = [currentArtwork imageWithSize:imageSize];
	
	//NSLog(@"%d, %d, %d", self.musicPlayer.nowPlayingItem.albumPersistentID == self.lastAlbumArtImage, self.requestType, self.firstPebbleAppOpen);
	
	if(self.musicPlayer.nowPlayingItem.albumPersistentID == self.lastAlbumArtImage && self.requestType != NowPlayingRequestTypeOnlyTrackInfo && !self.firstPebbleAppOpen){
        NSLog(@"The album art is literally samezies...");
        return;
    }
	else if(self.requestType == NowPlayingRequestTypeOnlyTrackInfo){
		NSLog(@"Only track info, rejecting");
		return;
	}
    self.lastAlbumArtImage = self.musicPlayer.nowPlayingItem.albumPersistentID;
    self.requestType = NowPlayingRequestTypeOnlyTrackInfo;
	self.firstPebbleAppOpen = NO;
    
    for(uint8_t index = 0; index < self.imageParts; index++){
        
        NSString *imageString = [LMPebbleImage ditherImage:albumArtImage
                                           withSize:imageSize
                                      forTotalParts:self.imageParts
                                    withCurrentPart:index
                                    isBlackAndWhite:[self watchIsBlackAndWhite]
                                       isRoundWatch:[self watchIsRoundScreen]];
        
        if(self.watch){
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

- (void)sendHeaderIconImage:(UIImage*)albumArtImage {
    NSLog(@"sending image %@", albumArtImage);
    CGSize imageSize = CGSizeMake(36, 36);

    NSString *imageString = [LMPebbleImage ditherImage:albumArtImage
                                              withSize:imageSize
                                         forTotalParts:1
                                       withCurrentPart:0
                                       isBlackAndWhite:[self watchIsBlackAndWhite]
                                          isRoundWatch:NO];
    
    if(!albumArtImage) {
        NSLog(@"No image!");
        [self sendMessageToPebble:@{MessageKeyHeaderIconLength:[NSNumber numberWithUint8:1]}];
    }
    else {
        NSData *bitmap = [NSData dataWithContentsOfFile:imageString];
        
        size_t length = [bitmap length];
        NSDictionary *sizeDict = @{MessageKeyHeaderIconLength: [NSNumber numberWithUint16:[bitmap length]]};
        NSLog(@"Album art size message: %@", sizeDict);
        [self sendMessageToPebble:sizeDict];
        
        uint8_t j = 0;
        for(size_t i = 0; i < length; i += self.appMessageSize-1) {
            NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:self.appMessageSize];
            
            NSRange rangeOfBytes = NSMakeRange(i, MIN(self.appMessageSize-1, length - i));
            [outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
            
            NSDictionary *dict = @{MessageKeyHeaderIcon: outgoing, MessageKeyHeaderIconIndex:[NSNumber numberWithUint16:j]};
            [self sendMessageToPebble:dict];
            j++;
        }
    }
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
    if (self.watch) {
        return;
    }
    self.watch = watch;
    
    NSLog(@"Got watch %@", self.watch);
    
    self.messageQueue.watch = self.watch;
    
    [self.watch appMessagesPushUpdate:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint8:1]} onSent:^(PBWatch * _Nonnull watch, NSDictionary * _Nonnull update, NSError * _Nullable error) {
        if(error){
            NSLog(@"Error sending to watch %@", error);
        }
        else{
            NSLog(@"Communications with watch opened.");
        }
    }];
    
    __weak typeof(self) welf = self;

    [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        __strong typeof(welf) sself = welf;
        if (!sself) {
            NSLog(@"self is destroyed!");
            return NO;
        }
        if(update[MessageKeyPlayTrack]) {
            NSLog(@"Will play track from message %@", update);
            [self playTrackFromMessage:update withTrackPlayMode:[update[MessageKeyTrackPlayMode] uint8Value]];
        }
        else if(update[MessageKeyRequestLibrary]) {
            if(update[MessageKeyRequestParent]) {
                [self sublistRequest:update];
            } else {
                [self libraryDataRequest:update];
            }
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
	
	if(self.rootSettingsViewController){
		self.rootSettingsViewController.messageQueue = self.messageQueue;
		[self.rootSettingsViewController.tableView reloadData];
	}
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    NSLog(@"Lost watch %@", self.watch);
    if (self.watch == watch) {
        self.watch = nil;
    }
	
	if(self.rootSettingsViewController){
		self.rootSettingsViewController.messageQueue = nil;
		[self.rootSettingsViewController.tableView reloadData];
	}
}

- (void)playTrackFromMessage:(NSDictionary *)message withTrackPlayMode:(TrackPlayMode)trackPlayMode {
    MPMediaItemCollection *queue = [self getCollectionFromMessage:message][0];
	MPMediaItem *track = [queue items][[[message[MessageKeyPlayTrack] int16Value] < 0 ? 0 : message[MessageKeyPlayTrack] int16Value]];
    NSLog(@"Got index %d", [message[MessageKeyPlayTrack] int16Value]);
    for(int i = 0; i < [[queue items] count]; i++){
        NSLog(@"Got item %@: %d", [[[queue items] objectAtIndex:i]valueForProperty:MPMediaItemPropertyTitle], i);
    }
    NSLog(@"track %@", [track valueForProperty:MPMediaItemPropertyTitle]);
    [self.musicPlayer stop];
    self.currentlyPlayingQueue = queue;
    [self.musicPlayer setQueueWithItemCollection:queue];
    if(trackPlayMode == TrackPlayModeShuffleAll){
        self.musicPlayer.shuffleMode = MPMusicShuffleModeSongs;
    }
    else{
		self.musicPlayer.shuffleMode = MPMusicShuffleModeOff;
		
		MPMusicRepeatMode newRepeatMode = (trackPlayMode-TrackPlayModeRepeatModeNone)+1;
		if(newRepeatMode == MPMusicRepeatModeNone){
			self.musicPlayer.repeatMode = MPMusicRepeatModeNone;
			[self.musicPlayer setNowPlayingItem:track];
		}
		else{
			[self.musicPlayer setNowPlayingItem:track];
			self.musicPlayer.repeatMode = newRepeatMode;
		}
//		self.repeatMode = self.musicPlayer.repeatMode;
		
        NSLog(@"Setting repeat mdoe as %ld", (long)self.musicPlayer.repeatMode);
    }
    [self.musicPlayer play];
    //[self.musicPlayer setCurrentPlaybackTime:0];
    NSLog(@"Now playing %@", [self.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyTitle]);
}

- (void)libraryDataRequest:(NSDictionary *)request {
    NSUInteger request_type = [request[MessageKeyRequestLibrary] unsignedIntegerValue];
    NSUInteger offset = [request[MessageKeyRequestOffset] integerValue];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query setGroupingType:request_type];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
    NSArray* results = [query collections];
    [self pushLibraryResults:results withOffset:offset type:request_type isSubtitle:0];
}

- (void)sublistRequest:(NSDictionary*)request {
    NSArray *results = [self getCollectionFromMessage:request];
    MPMediaGrouping request_type = [request[MessageKeyRequestLibrary] integerValue];
    uint16_t offset = [request[MessageKeyRequestOffset] uint16Value];
    if(request_type == MPMediaGroupingTitle) {
        results = [results[0] items];
    }
    [self pushLibraryResults:results withOffset:offset type:request_type isSubtitle:0];
}

- (NSArray*)getCollectionFromMessage:(NSDictionary*)request {
    // Find what we're subsetting by iteratively grabbing the sets.
    MPMediaItemCollection *collection = nil;
    MPMediaGrouping parent_type;
    uint16_t parent_index;
    NSString *persistent_id;
    NSString *id_prop;
    NSData *data = request[MessageKeyRequestParent];
    uint8_t *bytes = (uint8_t*)[data bytes];
    for(uint8_t i = 0; i < bytes[0]; ++i) {
        parent_type = bytes[i*3+1];
        parent_index = *(uint16_t*)&bytes[i*3+2];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query setGroupingType:parent_type];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
        if(collection) {
            [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistent_id forProperty:id_prop]];
        }
        if(parent_index >= [[query collections] count]) {
            NSLog(@"Out of bounds: %d", parent_index);
            return nil;
        }
        collection = [query collections][parent_index];
        id_prop = [MPMediaItem persistentIDPropertyForGroupingType:parent_type];
        persistent_id = [[collection representativeItem] valueForProperty:id_prop];
    }
    
    // Complete the lookup
    NSUInteger request_type = [request[MessageKeyRequestLibrary] unsignedIntegerValue];
    if(request_type == MPMediaGroupingTitle) {
        return @[collection];
    } else {
        NSLog(@"Got persistent ID: %@", persistent_id);
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query setGroupingType:request_type];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistent_id forProperty:id_prop]];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
        return [query collections];
    }
}

- (void)pushLibraryResults:(NSArray *)results withOffset:(NSInteger)offset type:(MPMediaGrouping)type isSubtitle:(uint8_t)subtitleType {
    switch(subtitleType){
        case 1: //Album artist
            break;
        case 2: //Track subtitle
        case 3: //Playlist subtitle
            type = MPMediaGroupingPodcastTitle;
            break;
    }
    
    NSArray* subset;
    if(offset < [results count]) {
        NSInteger count = MAX_RESPONSE_COUNT;
        if([results count] <= offset + MAX_RESPONSE_COUNT) {
            count = [results count] - offset;
        }
        subset = [results subarrayWithRange:NSMakeRange(offset, count)];
    }
    NSMutableData *result = [[NSMutableData alloc] init];
    // Response format: header of one byte containing library data type, two bytes containing
    // the total number of results, and two bytes containing our current offset. Little endian.
    // This is followed by a sequence of entries, which consist of one length byte followed by UTF-8 data
    // (pascal style)
    uint8_t type_byte = (uint8_t)type;
    uint16_t metabytes[] = {[results count], offset};
    // Include the type of library
    [result appendBytes:&type_byte length:1];
    [result appendBytes:metabytes length:4];
    MPMediaItem *representativeItem;
    int i = 0;
    for (MPMediaItemCollection* item in subset) {
        NSString *value;
        if(type == MPMediaGroupingPodcastTitle && subtitleType == 3){
            value = [NSString stringWithFormat:@"%lu songs", (unsigned long)item.count];
        }
        else if([item isKindOfClass:[MPMediaPlaylist class]]) {
            value = [item valueForProperty:MPMediaPlaylistPropertyName];
        }
        //If this happens, it's tracks asking for its artist and duration.
        else if(type == MPMediaGroupingPodcastTitle && subtitleType == 2){
//            NSNumber *trackLength = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
//            NSString *artistName = [item valueForProperty:MPMediaItemPropertyArtist];
			
//            if(artistName){
//                value = [NSString stringWithFormat:@"%@ | %@",
//                         [LMNowPlayingViewController durationStringTotalPlaybackTime:[trackLength longValue]],
//                         artistName];
//            }
//            else{
//                value = [NSString stringWithFormat:@"%@",
//                         [LMNowPlayingViewController durationStringTotalPlaybackTime:[trackLength longValue]]];
//            }
        }
        else if(type == MPMediaGroupingAlbumArtist){
            value = [[item representativeItem] valueForProperty:MPMediaItemPropertyArtist];
        }
        else {
            representativeItem = [item representativeItem];
            value = [[item representativeItem] valueForProperty:[MPMediaItem titlePropertyForGroupingType:type]];
        }
        if([value length] > MAX_LABEL_LENGTH) {
            value = [value substringToIndex:MAX_LABEL_LENGTH];
        }
        NSData *value_data = [value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        uint8_t length = [value_data length];
        if(([result length] + length) > self.appMessageSize){
            NSLog(@"Cutting off length at %lu", (unsigned long)[result length]);
            break;
        }
        [result appendBytes:&length length:1];
        [result appendData:value_data];
        NSLog(@"Value for %d: %@", i, value);
        i++;
    }
    [self.messageQueue enqueue:@{MessageKeyLibraryResponse: result}];

    if(type == MPMediaGroupingAlbum){
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingAlbumArtist isSubtitle:1];
    }
    else if(type == MPMediaGroupingTitle){
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingPodcastTitle isSubtitle:2];
        if(![self watchIsBlackAndWhite]){
            [self sendHeaderIconImage:[[representativeItem artwork] imageWithSize:CGSizeMake(36, 36)]];
        }
    }
    else if(type == MPMediaGroupingPlaylist){
        NSLog(@"Pushing playlist subtitles");
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingPodcastTitle isSubtitle:3];
    }
    
    NSLog(@"Sent message: %@ with length %lu", result, (unsigned long)[result length]);
}


- (void)viewDidLayoutSubviews {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if([defaults objectForKey:@"pebble_coldstart"]){
//        [self.central run];
//    }
//    else{
//        UIAlertController * alert = [UIAlertController
//									 alertControllerWithTitle:NSLocalizedString(@"PebbleConnectionRequestTitle", nil)
//                                     message:NSLocalizedString(@"PebbleConnectionRequestDescription", nil)
//                                     preferredStyle:UIAlertControllerStyleAlert];
//        
//        UIAlertAction* yesButton = [UIAlertAction
//									actionWithTitle:NSLocalizedString(@"Okay", nil)
//                                    style:UIAlertActionStyleDefault
//                                    handler:^(UIAlertAction * action) {
//                                        [self.central run];
//                                        [defaults setBool:YES forKey:@"pebble_coldstart"];
//                                    }];
//        
//        [alert addAction:yesButton];
//        
//        // [self presentViewController:alert animated:YES completion:nil];
//        
//    }
	
//	self.volumeView = [[MPVolumeView alloc] init];
//	self.volumeView.showsRouteButton = NO;
//	self.volumeView.showsVolumeSlider = NO;
//	[self.view addSubview:self.volumeView];
//	
//	//find the volumeSlider
//	self.volumeViewSlider = nil;
//	for (UIView *view in [self.volumeView subviews]){
//		if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
//			self.volumeViewSlider = (UISlider*)view;
//			break;
//		}
//	}
//	
//	[self.volumeViewSlider addTarget:self action:@selector(handleVolumeChanged:) forControlEvents:UIControlEventValueChanged];
	
	[self nowPlayingItemChanged:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.central = [PBPebbleCentral defaultCentral];
    self.central.delegate = self;
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
    
    self.messageQueue = [[LMPebbleMessageQueue alloc]init];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];

}

@end
