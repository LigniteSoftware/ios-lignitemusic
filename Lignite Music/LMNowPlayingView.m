//
//  LMNowPlayingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "UIImage+AverageColour.h"
#import "LMProgressSlider.h"
#import "LMOperationQueue.h"
#import "UIImage+ColorArt.h"
#import "LMNowPlayingView.h"
#import "LMTrackInfoView.h"
#import "UIColor+isLight.h"
#import "NSTimer+Blocks.h"
#import "LMAlbumArtView.h"
#import "LMMusicPlayer.h"
#import "LMListEntry.h"
#import "LMTableView.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMColour.h"
#import "LMButton.h"

@interface LMNowPlayingView() <LMMusicPlayerDelegate, LMButtonDelegate, LMProgressSliderDelegate, LMTableViewSubviewDataSource, LMListEntryDelegate>

@property LMMusicPlayer *musicPlayer;

/**
 The main view of the now playing view which is separate from the now playing queue.
 */
@property UIView *mainView;

/**
 The leading constraint for the main view.
 */
@property NSLayoutConstraint *mainViewLeadingConstraint;

/**
 The background view for the now playing  queue.
 */
@property UIView *queueView;

/**
 The view that goes on top of the main view when the queue is open so that the user can drag it from left to right to close the queue.
 */
@property UIView *queueOpenDraggingOverlayView;

/**
 The items array for the now playing queue.
 */
@property NSMutableArray *itemArray;

/**
 The index of the currently highlighted item.
 */
@property NSInteger currentlyHighlighted;

/**
 The now playing queue table view.
 */
@property LMTableView *queueTableView;

/**
 The title label for nothing in queue.
 */
@property UILabel *nothingInQueueTitleLabel;

/**
 The label which will display if nothing is in queue or iOS isn't giving us a queue.
 */
@property UILabel *nothingInQueueLabel;

@property UIImageView *backgroundImageView;
//@property UIView *shadingView;
@property UIVisualEffectView *blurredBackgroundView;

/**
 Goes in front of the background image view for now while we test this new design
 */
@property UIView *colourBackgroundView;

@property UIView *albumArtRootView;
@property LMAlbumArtView *albumArtImageView;
@property UIImageView *brandNewAlbumArtImageView;

@property LMOperationQueue *queue;

@property LMTrackInfoView *trackInfoView;

@property BOOL loaded;

@property UIView *shuffleModeBackgroundView, *repeatModeBackgroundView, *queueBackgroundView, *airplayBackgroundView;
@property LMButton *shuffleModeButton, *repeatModeButton, *queueButton, *airplayButton;

@property LMProgressSlider *progressSlider;

@property CGPoint originalPoint, currentPoint;
@property CGPoint queueOriginalPoint;

@end

@implementation LMNowPlayingView

+ (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime {
	long totalHours = (totalPlaybackTime / 3600);
	int totalMinutes = (int)((totalPlaybackTime / 60) - totalHours*60);
	int totalSeconds = (totalPlaybackTime % 60);
	
	if(totalHours > 0){
		return [NSString stringWithFormat:NSLocalizedString(@"LongSongDuration", nil), (int)totalHours, totalMinutes, totalSeconds];
	}
	
	return [NSString stringWithFormat:NSLocalizedString(@"ShortSongDuration", nil), totalMinutes, totalSeconds];
}

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
	long totalPlaybackTime = self.loadedTrack.playbackDuration;
	
	long currentHours = (currentPlaybackTime / 3600);
	long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
	int currentSeconds = (currentPlaybackTime % 60);
	
	long totalHours = (totalPlaybackTime / 3600);
	
	if(totalHours > 0){
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"LongSongDurationOfDuration", nil),
									   (int)currentHours, (int)currentMinutes, currentSeconds,
									   [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
	else{
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"ShortSongDurationOfDuration", nil),
									   (int)currentMinutes, currentSeconds,
									   [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
}

- (void)progressSliderValueChanged:(CGFloat)newValue isFinal:(BOOL)isFinal {
	//NSLog(@"New value %f", newValue);
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	if(isFinal){
		[self.musicPlayer setCurrentPlaybackTime:newValue];
	}
	else{
		[self updateSongDurationLabelWithPlaybackTime:newValue];
	}
}

- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime {
    if(self.musicPlayer.nowPlayingTrack.persistentID != self.loadedTrack.persistentID){
        return;
    }
    
	if(self.progressSlider.userIsInteracting){
		return;
	}
	
	[self updateSongDurationLabelWithPlaybackTime:newPlaybackTime];
	
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.value = newPlaybackTime;
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	
	[self updateMusicModeButtons];
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
    
}

- (void)changeMusicTrack:(LMMusicTrack*)newTrack withIndex:(NSInteger)index {
    self.loadedTrack = newTrack;
    self.loadedTrackIndex = index;
    
    NSLog(@"ID is %@: %lld", newTrack.title, newTrack.persistentID);
    
	if(!self.queue){
		self.queue = [LMOperationQueue new];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *albumArt = [newTrack albumArt];
		UIImage *albumImage = (noTrackPlaying || !albumArt) ? [UIImage imageNamed:@"lignite_background_portrait.png"] : albumArt;
		
		UIColor *averageColour = [albumImage averageColour];
//		BOOL isLight = [averageColour isLight];
//		self.blurredBackgroundView.effect = [UIBlurEffect effectWithStyle:isLight ? UIBlurEffectStyleLight : UIBlurEffectStyleDark];
//		UIColor *newTextColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
		
		SLColorArt *colorArt = [albumImage colorArt];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.backgroundImageView.image = albumImage;
			self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
			
			self.albumArtImageView.albumArtImageView.image = nil;
			
//			self.trackInfoView.textColour = newTextColour;
			
			self.progressSlider.sliderBackgroundView.backgroundColor = averageColour;
			self.colourBackgroundView.backgroundColor = colorArt.backgroundColor;
			
			BOOL isLight = [self.colourBackgroundView.backgroundColor isLight];
			
			self.blurredBackgroundView.effect = [UIBlurEffect effectWithStyle:isLight ? UIBlurEffectStyleLight : UIBlurEffectStyleDark];
			
			self.trackInfoView.textColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
			self.progressSlider.lightTheme = !isLight;
			
			if(albumImage.size.height > 0){
				[self.albumArtImageView updateContentWithMusicTrack:newTrack];
			}
			
			NSLog(@"Spook me solid");
			
			self.brandNewAlbumArtImageView.image = albumArt ? albumArt : [LMAppIcon imageForIcon:LMIconNoAlbumArt];
		});
	}];
	
	[self.queue addOperation:operation];
	
	if(noTrackPlaying){
		self.trackInfoView.titleText = NSLocalizedString(@"NoMusic", nil);
		self.trackInfoView.artistText = NSLocalizedString(@"NoMusicDescription", nil);
		self.trackInfoView.albumText = @"";
		self.progressSlider.rightText = NSLocalizedString(@"BlankDuration", nil);
		self.progressSlider.leftText = NSLocalizedString(@"NoMusic", nil);
		
		UIImage *albumImage;
		albumImage = [UIImage imageNamed:@"lignite_background_portrait.png"];
		self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backgroundImageView.image = albumImage;
		
		[self.albumArtImageView updateContentWithMusicTrack:nil];
		self.brandNewAlbumArtImageView.image = nil;
		return;
	}
	
	self.trackInfoView.titleText = newTrack.title ? newTrack.title : NSLocalizedString(@"UnknownTitle", nil);
	self.trackInfoView.artistText = newTrack.artist ? newTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
	self.trackInfoView.albumText = newTrack.albumTitle ? newTrack.albumTitle : NSLocalizedString(@"UnknownAlbumTitle", nil);
	
    if(self.musicPlayer.nowPlayingCollection){
        self.progressSlider.leftText =
        [NSString stringWithFormat:NSLocalizedString(@"SongXofX", nil),
             (int)self.loadedTrackIndex+1,
             (int)self.musicPlayer.nowPlayingCollection.count];
    }
    else{
        self.progressSlider.leftText =
            [NSString stringWithFormat:NSLocalizedString(@"SongX", nil),
             (int)self.loadedTrackIndex+1];
    }
    
    CGFloat timeToUse = self.musicPlayer.nowPlayingTrack == self.loadedTrack ? self.musicPlayer.currentPlaybackTime : 0;
    
    self.progressSlider.rightText = [LMNowPlayingView durationStringTotalPlaybackTime:newTrack.playbackDuration];
    [self updateSongDurationLabelWithPlaybackTime:timeToUse];
    [self.progressSlider reset];
    self.progressSlider.value = timeToUse;
	
	self.queueTableView.totalAmountOfObjects = self.musicPlayer.nowPlayingCollection.count;
	[self.queueTableView reloadSubviewData];
	
	
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.musicPlayer.nowPlayingCollection.count; i++){
		LMMusicTrack *track = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:i];
		LMListEntry *entry = [self listEntryForIndex:i];
		LMMusicTrack *entryTrack = entry.associatedData;
		
		if(entryTrack.persistentID == newTrack.persistentID){
			highlightedEntry = entry;
		}
		
		if(track.persistentID == newTrack.persistentID){
			newHighlightedIndex = i;
		}
	}
	
	NSLog(@"New highlighted %d previous %ld", newHighlightedIndex, (long)self.currentlyHighlighted);
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	
	self.currentlyHighlighted = newHighlightedIndex;
	
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (void)musicOutputPortDidChange:(AVAudioSessionPortDescription *)outputPort {
	[UIView animateWithDuration:0.25 animations:^{
		[self.airplayButton setColour:[LMMusicPlayer outputPortIsWireless:outputPort] ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	}];
}

- (void)updateRepeatButtonImage {
	LMIcon icons[] = {
		LMIconRepeat, LMIconRepeat, LMIconRepeat, LMIconRepeatOne
	};
	NSLog(@"Repeat mode %d", self.musicPlayer.repeatMode);
	UIImage *icon = [LMAppIcon imageForIcon:icons[self.musicPlayer.repeatMode]];
	[self.repeatModeButton setImage:icon];
}

- (void)setNowPlayingQueueOpen:(BOOL)open {
    if(!open){
        [NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
            self.queueView.hidden = YES;
        } repeats:NO];
    }
    else{
        self.queueView.hidden = NO;
    }
    
	[self layoutIfNeeded];
	
	NSLog(open ? @"Open queue" : @"Close queue");
	
	self.queueOpenDraggingOverlayView.hidden = !open;
	
	self.mainViewLeadingConstraint.constant = open ? -self.queueView.frame.size.width : 0;
	
	self.originalPoint = CGPointZero;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self.queueButton setColour:open ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
		[self layoutIfNeeded];
	}];
}

- (void)queueCloseTap {
	[self setNowPlayingQueueOpen:NO];
}

- (BOOL)nowPlayingQueueOpen {
	return self.mainViewLeadingConstraint.constant < 0;
}

- (void)updateMusicModeButtons {
	[UIView animateWithDuration:0.25 animations:^{
		[self.shuffleModeButton setColour:self.musicPlayer.shuffleMode ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	}];
	
	[UIView animateWithDuration:0.25 animations:^{
		[self.repeatModeButton setColour:(self.musicPlayer.repeatMode != LMMusicRepeatModeNone) ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	}];
}

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Hey button %@", button);
	if(button == self.shuffleModeButton){
		self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
	}
	else if(button == self.repeatModeButton){
		if(self.musicPlayer.repeatMode < LMMusicRepeatModeOne){
			self.musicPlayer.repeatMode++;
		}
		else if(self.musicPlayer.repeatMode == LMMusicRepeatModeOne){
			self.musicPlayer.repeatMode = LMMusicRepeatModeNone;
		}
		
		[self updateRepeatButtonImage];
	}
	else if(button == self.queueButton){
		[self setNowPlayingQueueOpen:![self nowPlayingQueueOpen]];
	}
	else if(button == self.airplayButton){
		MPVolumeView *volumeView;
		for(id subview in self.airplayButton.subviews){
			if([[[subview class] description] isEqualToString:@"MPVolumeView"]){
				volumeView = subview;
				break;
			}
		}
		for(UIView *wnd in volumeView.subviews){
			if([wnd isKindOfClass:[UIButton class]]) {
				UIButton *button = (UIButton*) wnd;
				[button sendActionsForControlEvents:UIControlEventTouchUpInside];
				break;
			}
		}
	}
	
	[self updateMusicModeButtons];
}

- (void)tappedNowPlaying {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer invertPlaybackState];
}

- (void)swipedRightNowPlaying {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer skipToNextTrack];
}

- (void)swipedLeftNowPlaying {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer autoBackThrough];
}



- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:index];
	
//	NSLog(@"Collection index %d, current %d match? %d", (int)entry.collectionIndex, (int)self.currentlyHighlighted, ((self.currentlyHighlighted == entry.collectionIndex)));
	
	[entry changeHighlightStatus:(self.currentlyHighlighted == entry.collectionIndex) animated:NO];
	
//	if((self.currentlyHighlighted == entry.collectionIndex) ){
//		entry.backgroundColor = [UIColor cyanColor];
//	}
	
	[entry reloadContents];
	return entry;
}

- (void)refreshNothingInQueueText {
	BOOL hidden = (self.itemArray.count > 0);
	
	self.nothingInQueueLabel.hidden = hidden;
	self.nothingInQueueTitleLabel.hidden = hidden;
	
	self.nothingInQueueLabel.text = NSLocalizedString((self.musicPlayer.nowPlayingTrack && !self.musicPlayer.nowPlayingCollection) ? @"iOSNotProvidingQueue" : @"TheresNothingHere", nil);
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView *)tableView {
	NSLog(@"Required! %d", (int)amountOfObjects);
	
	if(!self.itemArray || self.itemArray.count != amountOfObjects){
		self.itemArray = [NSMutableArray new];
		for(int i = 0; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iconInsetMultiplier = (1.0/3.0);
			listEntry.iconPaddingMultiplier = (3.0/4.0);
			listEntry.invertIconOnHighlight = YES;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
		}
	}
	
	[self refreshNothingInQueueText];
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	return WINDOW_FRAME.size.height*(1.0f/8.0f);
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *indexEntry = [self.itemArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.itemArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	return 10;
}

- (void)tappedListEntry:(LMListEntry*)entry{
	NSLog(@"Hey %d", (int)entry.collectionIndex);
	LMListEntry *currentHighlighted = [self listEntryForIndex:self.currentlyHighlighted];
	[currentHighlighted changeHighlightStatus:NO animated:YES];
	
	[entry changeHighlightStatus:YES animated:YES];
	
	self.currentlyHighlighted = entry.collectionIndex;
	
	[self.musicPlayer setNowPlayingTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex]];
	[self.musicPlayer play];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	NSLog(@"Returning for %d", (int)entry.collectionIndex);
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
//	return @"queue title";
	return [NSString stringWithFormat:@"%@", [self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex].title];
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
//	return @"queue subtitle";
	return [NSString stringWithFormat:@"%@", [LMNowPlayingView durationStringTotalPlaybackTime:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex].playbackDuration]];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return nil;
}

- (void)panNowPlayingDown:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:recognizer.view];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.mainView.frame.origin;
		self.currentPoint = self.mainView.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
//	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	if(totalTranslation < 0){ //Moving upward
        NSLog(@"什麼鬼");
        self.topConstraint.constant = 0;
		return;
	}
	else{ //Moving downward
		self.topConstraint.constant = totalTranslation;
	}
	
	[self.superview layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		if((translation.y >= self.frame.size.height/10.0)){
			self.topConstraint.constant = self.frame.size.height;
			self.isOpen = NO;
		}
		else{
			self.topConstraint.constant = 0.0;
			self.isOpen = YES;
		}
		
		NSLog(@"Finished is open %d", self.isOpen);
		
		[UIView animateWithDuration:0.25 animations:^{
			[self.superview layoutIfNeeded];
		} completion:^(BOOL finished) {
			if(finished){
				[UIView animateWithDuration:0.25 animations:^{
					[self.coreViewController setNeedsStatusBarAppearanceUpdate];
					[self.coreViewController setStatusBarBlurHidden:self.isOpen];
				}];
			}
		}];
	}
}


- (void)panQueueClosed:(UIPanGestureRecognizer *)recognizer {
    self.queueView.hidden = NO;
    
	CGPoint translation = [recognizer translationInView:self.mainView];
	
	CGFloat totalTranslation;
	if(recognizer.view == self.queueOpenDraggingOverlayView){
		totalTranslation = (self.queueOriginalPoint.x-self.queueView.frame.size.width) + translation.x;
	}
	else{
		totalTranslation = self.queueOriginalPoint.x + translation.x;
	}
	
//	NSLog(@"%f %f %ld", translation.x, totalTranslation, (long)recognizer.state);
	
	if(totalTranslation > 0){ //Moving too far to the right?
		NSLog(@"Fuck");
		[self setNowPlayingQueueOpen:NO];
		return;
	}
	else{ //Moving downward
		self.mainViewLeadingConstraint.constant = totalTranslation;
	}
	
	[self layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled){
		NSLog(@"Done");
		if((translation.x >= self.frame.size.width/4.0)){
			[self setNowPlayingQueueOpen:NO];
		}
		else{
			[self setNowPlayingQueueOpen:YES];
		}
	}
}


- (void)layoutSubviews {
	[super layoutSubviews];

	if(self.didLayoutConstraints){
		return;
	}
	self.didLayoutConstraints = YES;
	
	NSLog(@"What the fuckkkkk!!!");
	
	self.mainView = [UIView newAutoLayoutView];
	self.mainView.backgroundColor = [UIColor purpleColor];
	self.mainView.clipsToBounds = YES;
	[self addSubview:self.mainView];
    
	self.mainViewLeadingConstraint = [self.mainView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.mainView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.mainView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.mainView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	
	
	self.queueView = [UIView newAutoLayoutView];
	self.queueView.backgroundColor = [UIColor whiteColor];
    self.queueView.hidden = YES;
	[self addSubview:self.queueView];
	
	[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.queueView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.mainView];
	[self.queueView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(3.0/4.0)];
	
	
	self.currentlyHighlighted = -1;
	
	self.queueTableView = [LMTableView newAutoLayoutView];
	self.queueTableView.totalAmountOfObjects = self.musicPlayer.nowPlayingCollection.count;
	self.queueTableView.subviewDataSource = self;
	self.queueTableView.shouldUseDividers = YES;
	self.queueTableView.title = @"QueueTableView";
	self.queueTableView.bottomSpacing = 10;
	[self.queueView addSubview:self.queueTableView];
	
	[self.queueTableView autoPinEdgesToSuperviewEdges];
	
	[self.queueTableView reloadSubviewData];
	
	
	self.nothingInQueueTitleLabel = [UILabel newAutoLayoutView];
	self.nothingInQueueTitleLabel.numberOfLines = 0;
	self.nothingInQueueTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22.0f];
	self.nothingInQueueTitleLabel.text = NSLocalizedString(@"NothingInQueue", nil);
	self.nothingInQueueTitleLabel.textAlignment = NSTextAlignmentLeft;
	self.nothingInQueueTitleLabel.backgroundColor = [UIColor whiteColor];
	[self.queueView addSubview:self.nothingInQueueTitleLabel];
	
	[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
	[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
	
	self.nothingInQueueLabel = [UILabel newAutoLayoutView];
	self.nothingInQueueLabel.numberOfLines = 0;
	self.nothingInQueueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
	self.nothingInQueueLabel.text = NSLocalizedString(@"TheresNothingHere", nil);
	self.nothingInQueueLabel.textAlignment = NSTextAlignmentLeft;
	self.nothingInQueueLabel.backgroundColor = [UIColor whiteColor];
	[self.queueView addSubview:self.nothingInQueueLabel];
	
	[self.nothingInQueueLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nothingInQueueTitleLabel withOffset:20];
	[self.nothingInQueueLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.nothingInQueueLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
	
	[self refreshNothingInQueueText];
	
	
	self.backgroundImageView = [UIImageView newAutoLayoutView];
	self.backgroundImageView.image = [UIImage imageNamed:@"lignite_background_portrait.png"];
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.mainView addSubview:self.backgroundImageView];
	
	[self.backgroundImageView autoCenterInSuperview];
	[self.backgroundImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:1.1];
	[self.backgroundImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:1.1];
	
	
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	self.blurredBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	self.blurredBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self.mainView addSubview:self.blurredBackgroundView];
	
	[self.blurredBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.backgroundImageView];
	[self.blurredBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundImageView];
	[self.blurredBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	
	
	self.colourBackgroundView = [UIView newAutoLayoutView];
	self.colourBackgroundView.backgroundColor = [UIColor whiteColor];
	[self.blurredBackgroundView addSubview:self.colourBackgroundView];
	
	[self.colourBackgroundView autoPinEdgesToSuperviewEdges];
	self.colourBackgroundView.hidden = YES;
	
	
	self.albumArtRootView = [UIView newAutoLayoutView];
	self.albumArtRootView.backgroundColor = [UIColor clearColor];
	[self.mainView addSubview:self.albumArtRootView];
	
	[self.albumArtRootView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.mainView];
	[self.albumArtRootView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.mainView];
	[self.albumArtRootView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.mainView];
	[self.albumArtRootView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.mainView];
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.albumArtRootView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.mainView
																		attribute:NSLayoutAttributeWidth
																	   multiplier:1.0
																		 constant:0];
	heightConstraint.priority = UILayoutPriorityRequired;
	[self addConstraint:heightConstraint];
	
	self.albumArtImageView = [LMAlbumArtView newAutoLayoutView];
	[self.albumArtRootView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtRootView withMultiplier:0.9];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtRootView withMultiplier:0.9];
	
	self.albumArtImageView.hidden = YES;
	
	[self.albumArtImageView setupWithAlbumImage:nil];
	self.albumArtImageView.backgroundColor = [UIColor clearColor];
	
	self.brandNewAlbumArtImageView = [UIImageView newAutoLayoutView];
//	self.brandNewAlbumArtImageView.backgroundColor = [UIColor orangeColor];
	[self.albumArtRootView addSubview:self.brandNewAlbumArtImageView];
	
	[self.brandNewAlbumArtImageView autoCenterInSuperview];
	[self.brandNewAlbumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtRootView];
	[self.brandNewAlbumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtRootView];
	
	self.progressSlider = [LMProgressSlider newAutoLayoutView];
	self.progressSlider.backgroundBackgroundColour = [LMColour fadedColour];
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.delegate = self;
	self.progressSlider.value = self.musicPlayer.currentPlaybackTime;
	self.progressSlider.lightTheme = YES;
	self.progressSlider.autoShrink = YES;
	[self.mainView addSubview:self.progressSlider];
	
	[self.progressSlider autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.progressSlider autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.progressSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtRootView];
	[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/20.0)];
		
//	self.trackDurationView = [LMTrackDurationView newAutoLayoutView];
//	self.trackDurationView.delegate = self;
//	self.trackDurationView.shouldInsetInfo = YES;
////	self.trackDurationView.backgroundColor = [UIColor yellowColor];
//	[self addSubview:self.trackDurationView];
//	[self.trackDurationView setup];
//	
//	self.trackDurationView.seekSlider.minimumValue = 0;
//	self.trackDurationView.seekSlider.maximumValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
//	self.trackDurationView.seekSlider.value = self.musicPlayer.currentPlaybackTime;
//	
//	[self.trackDurationView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtRootView];
//	[self.trackDurationView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtRootView];
//	[self.trackDurationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtImageView withOffset:-2];
//	NSLayoutConstraint *constraint = [self.trackDurationView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/10.0)];
//	constraint.priority = UILayoutPriorityRequired;
	
	self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
	self.trackInfoView.textAlignment = NSTextAlignmentCenter;
	self.trackInfoView.textColour = [UIColor blackColor];
	[self.mainView addSubview:self.trackInfoView];
	
	//TODO: Fix this being manually set value
	[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.progressSlider withOffset:30];
	[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.progressSlider withOffset:20];
	[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.progressSlider withOffset:-20];
	[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/6.0)];
	
	self.shuffleModeBackgroundView = [UIView newAutoLayoutView];
	self.repeatModeBackgroundView = [UIView newAutoLayoutView];
	self.queueBackgroundView = [UIView newAutoLayoutView];
	self.airplayBackgroundView = [UIView newAutoLayoutView];
	
	self.shuffleModeButton = [LMButton newAutoLayoutView];
	self.repeatModeButton = [LMButton newAutoLayoutView];
	self.queueButton = [LMButton newAutoLayoutView];
	self.airplayButton = [LMButton newAutoLayoutView];
	
	NSArray *backgrounds = @[
		self.shuffleModeBackgroundView, self.repeatModeBackgroundView, self.airplayBackgroundView, self.queueBackgroundView
	];
	NSArray *buttons = @[
		self.shuffleModeButton, self.repeatModeButton, self.airplayButton, self.queueButton
	];
	LMIcon icons[] = {
		LMIconShuffle, LMIconRepeat, LMIconAirPlay, LMIconHamburger
	};
	
	for(int i = 0; i < buttons.count; i++){
		BOOL isFirst = (i == 0);
		
		UIView *background = [backgrounds objectAtIndex:i];
		UIView *previousBackground = isFirst ? self.trackInfoView : [backgrounds objectAtIndex:i-1];
		
//		background.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
		[self.mainView addSubview:background];
		
		[background autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView withOffset:-10];
		[background autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		[background autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:previousBackground];
		[background autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.trackInfoView withMultiplier:(1.0/(float)buttons.count)];
		
		LMButton *button = [buttons objectAtIndex:i];
		button.userInteractionEnabled = YES;
		[button setDelegate:self];
		[button setupWithImageMultiplier:0.4];
		[button setImage:[LMAppIcon imageForIcon:icons[i]]];
		[button setColour:[LMColour fadedColour]];
		[background addSubview:button];

		[button autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[button autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-20];
		[button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:background withMultiplier:0.6];
		[button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:background];
		
		if(button == self.airplayButton){
			MPVolumeView *volumeView = [MPVolumeView newAutoLayoutView];
//			volumeView.backgroundColor = [UIColor orangeColor];
			[volumeView setShowsVolumeSlider:NO];
			[volumeView setShowsRouteButton:NO];
			[button addSubview:volumeView];
			
			[volumeView autoPinEdgesToSuperviewEdges];
		}
		else if(button == self.queueButton){
			UIPanGestureRecognizer *queueOpenPanGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panQueueClosed:)];
			[self.queueButton addGestureRecognizer:queueOpenPanGesture];
		}
	}
	
	[self.shuffleModeButton setColour:self.musicPlayer.shuffleMode ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	[self.repeatModeButton setColour:(self.musicPlayer.repeatMode != LMMusicRepeatModeNone) ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self updateRepeatButtonImage];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedNowPlaying)];
	[self.mainView addGestureRecognizer:tapGesture];
	
//	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panNowPlayingDown:)];
//	self.brandNewAlbumArtImageView.userInteractionEnabled = YES;
//	[self.brandNewAlbumArtImageView addGestureRecognizer:panGestureRecognizer];
	
	
	self.queueOpenDraggingOverlayView = [UIView newAutoLayoutView];;
//	self.queueOpenDraggingOverlayView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.5 alpha:0.4];
	self.queueOpenDraggingOverlayView.hidden = YES;
	[self.mainView addSubview:self.queueOpenDraggingOverlayView];
	
	[self.queueOpenDraggingOverlayView autoPinEdgesToSuperviewEdges];
	
	UIPanGestureRecognizer *queueOpenPanGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panQueueClosed:)];
	[self.queueOpenDraggingOverlayView addGestureRecognizer:queueOpenPanGesture];
	
	UITapGestureRecognizer *queueOpenTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(queueCloseTap)];
	[self.queueOpenDraggingOverlayView addGestureRecognizer:queueOpenTapGesture];
	
//	[self setNowPlayingQueueOpen:YES];
	
	AVAudioSession* audioSession = [AVAudioSession sharedInstance];
	AVAudioSessionRouteDescription* currentRoute = audioSession.currentRoute;
	for(AVAudioSessionPortDescription* outputPort in currentRoute.outputs){
		[self musicOutputPortDidChange:outputPort];
	}
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Windows error creating music player!");
	}
	return self;
}

//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//	NSLog(@"Hey");
//}

@end
