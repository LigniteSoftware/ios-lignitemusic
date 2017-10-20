//
//  LMNowPlayingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "UIImage+AverageColour.h"
#import "LMNowPlayingCoreView.h"
#import "LMProgressSlider.h"
#import "LMOperationQueue.h"
#import "UIImage+ColorArt.h"
#import "LMNowPlayingView.h"
#import "LMTrackInfoView.h"
#import "UIColor+isLight.h"
#import "NSTimer+Blocks.h"
#import "LMMusicPlayer.h"
#import "LMListEntry.h"
#import "LMTableView.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMColour.h"
#import "LMButton.h"

@interface LMNowPlayingView() <LMMusicPlayerDelegate, LMButtonDelegate, LMProgressSliderDelegate, LMTableViewSubviewDataSource, LMListEntryDelegate, LMLayoutChangeDelegate, DDTableViewDelegate>

@property LMMusicPlayer *musicPlayer;

/**
 The main view of the now playing view which is separate from the now playing queue.
 */
@property LMView *mainView;

/**
 The padding view which insets all of the controls and content.
 */
@property UIView *paddingView;

/**
 The leading constraint for the main view.
 */
@property NSLayoutConstraint *mainViewLeadingConstraint;

/**
 The background view for the now playing  queue.
 */
@property LMView *queueView;

/**
 The view that goes on top of the main view when the queue is open so that the user can drag it from left to right to close the queue.
 */
@property LMView *queueOpenDraggingOverlayView;

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
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

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
//@property UIView *colourBackgroundView;

@property LMView *albumArtRootView;
@property UIImageView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMTrackInfoView *trackInfoView;

//@property BOOL loaded;

@property LMButton *shuffleModeButton, *repeatModeButton, *queueButton, *airplayButton, *favouritesButton;

@property LMProgressSlider *progressSlider;

@property CGPoint originalPoint, currentPoint;
@property CGPoint queueOriginalPoint;

/**
 The stack view for all of the buttons.
 */
@property UIStackView *buttonStackView;

/**
 The array of currently applied constraints which are special to iPad. Uninstall these before installing more.
 */
@property NSArray *currentiPadSpecificConstraintsArray;

@property NSTimeInterval lastTimeOfSwap;

@property UIImageView *favouriteHeartImageView;

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
    //Nothing happens here
}

- (void)changeMusicTrack:(LMMusicTrack*)newTrack withIndex:(NSInteger)index {
    self.loadedTrack = newTrack;
    self.loadedTrackIndex = index;
    
//    NSLog(@"ID is %@: %lld", newTrack.title, newTrack.persistentID);
	
	if(!self.queue){
		self.queue = [LMOperationQueue new];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *albumArt = [newTrack albumArt];
		UIImage *albumImage = (noTrackPlaying || !albumArt) ? [UIImage imageNamed:@"lignite_background_portrait.png"] : albumArt;
		
		UIColor *averageColour = [albumImage averageColour];
//		BOOL isLight = [averageColour isLight];
//		self.blurredBackgroundView.effect = [UIBlurEffect effectWithStyle:isLight ? UIBlurEffectStyleLight : UIBlurEffectStyleDark];
//		UIColor *newTextColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
		
//		SLColorArt *colorArt = [albumImage colorArt];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.backgroundImageView.image = albumImage;
			self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
			
//			self.trackInfoView.textColour = newTextColour;
			
			BOOL isLight = [averageColour isLight];
			
			self.progressSlider.sliderBackgroundView.backgroundColor = averageColour;
//			self.colourBackgroundView.backgroundColor = colorArt.backgroundColor;
			
			self.blurredBackgroundView.effect = [UIBlurEffect effectWithStyle:isLight ? UIBlurEffectStyleLight : UIBlurEffectStyleDark];
			
			self.trackInfoView.textColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
			self.progressSlider.lightTheme = !isLight;
			
//			NSLog(@"Spook me solid");
			
			self.albumArtImageView.image = albumArt ? albumArt : [LMAppIcon imageForIcon:LMIconNoAlbumArt];
			
			operation = nil;
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
		
		self.albumArtImageView.image = nil;
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
    [self.queueTableView reloadData];
	
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
	
//	NSLog(@"New highlighted %d previous %ld", newHighlightedIndex, (long)self.currentlyHighlighted);
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	
	self.currentlyHighlighted = newHighlightedIndex;
	
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
	
	[self reloadFavouriteStatus];
}


- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSLog(@"Move %@ to %@ from %p", sourceIndexPath, destinationIndexPath, tableView);
	
	if((([[NSDate new] timeIntervalSince1970] - self.lastTimeOfSwap)*1000) < 10){
		NSLog(@"double up, rejecting");
		return;
	}
	
	LMListEntry *currentListEntry = [self.itemArray objectAtIndex:sourceIndexPath.section];
	[self.itemArray removeObjectAtIndex:sourceIndexPath.section];
	[self.itemArray insertObject:currentListEntry atIndex:destinationIndexPath.section];
	
	currentListEntry.collectionIndex = destinationIndexPath.section;
	
	[currentListEntry changeHighlightStatus:YES animated:YES];
	
	[self.musicPlayer moveTrackInQueueFromIndex:sourceIndexPath.section toIndex:destinationIndexPath.section];
	
	[currentListEntry reloadContents];
	
	self.lastTimeOfSwap = [[NSDate new] timeIntervalSince1970];
}

- (UITableViewCell*)tableView:(UITableView *)tableView draggingCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if(![LMLayoutManager isLandscapeiPad]){
		cell.backgroundColor = [UIColor whiteColor];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView showDraggingView:(UIView *)draggingView atIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Show dragging view at %@", indexPath);
}

- (void)tableView:(UITableView *)tableView hideDraggingView:(UIView *)draggingView atIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Hide dragging view at %@", indexPath);
	
	[NSTimer scheduledTimerWithTimeInterval:0.3 block:^{
		LMNowPlayingCoreView *coreNowPlayingView = (LMNowPlayingCoreView*)self.nowPlayingCoreView;
		[coreNowPlayingView musicTrackDidChange:nil];
	} repeats:NO];
}

- (void)tableView:(UITableView *)tableView draggingGestureChanged:(UILongPressGestureRecognizer *)gesture {
	
}

- (void)trackMovedInQueue:(LMMusicTrack *)trackMoved {
	NSLog(@"%@ was moved, current index is %d", trackMoved.title, (int)self.musicPlayer.indexOfNowPlayingTrack);
	
//	[self.queueTableView reloadSubviewData];
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

- (void)setNowPlayingQueueOpen:(BOOL)open animated:(BOOL)animated {
    if(!open){
        [NSTimer scheduledTimerWithTimeInterval:animated ? 0.5 : 0.0 block:^{
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
	
	if(open && self.queueTableView.numberOfSections > 10){ //Ensure that the number of songs is greater than just a few
		NSInteger fixedIndex = self.loadedTrackIndex - 1;
		CGFloat contentOffsetY = ([self heightAtIndex:0 forTableView:self.queueTableView] + [self spacingAtIndex:0 forTableView:self.queueTableView]) * fixedIndex;
		CGFloat maxContentOffsetY = self.queueTableView.contentSize.height-self.queueTableView.frame.size.height - 10;
		if(contentOffsetY > maxContentOffsetY){
			contentOffsetY = maxContentOffsetY;
		}
		else if(contentOffsetY < 0){
			contentOffsetY = 0;
		}
		self.queueTableView.contentOffset = CGPointMake(0, contentOffsetY);
	}
	
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
		[self.queueButton setColour:open ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
		[self layoutIfNeeded];
	}];
}

- (void)queueCloseTap {
	[self setNowPlayingQueueOpen:NO animated:YES];
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
		[self setNowPlayingQueueOpen:![self nowPlayingQueueOpen] animated:YES];
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
	else if(button == self.favouritesButton){
		[self changeFavouriteStatus];
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

- (void)trackRemovedFromQueue:(LMMusicTrack *)trackRemoved {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"TrackRemovedFromQueue", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
	
//	self.queueTableView.totalAmountOfObjects = self.musicPlayer.nowPlayingCollection.count;
//	[self.queueTableView reloadSubviewData];
//	[self.queueTableView reloadData];

//	[self changeMusicTrack:self.loadedTrack withIndex:self.loadedTrackIndex];
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView *)tableView {
//	NSLog(@"Required! %d", (int)amountOfObjects);
	
    if(!self.itemArray){
        self.itemArray = [NSMutableArray new];
    }
    
	if(self.itemArray.count < amountOfObjects){
		for(NSUInteger i = self.itemArray.count; i < amountOfObjects; i++){
//            NSLog(@"Need to create %ld", i);
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.alignIconToLeft = YES;
			listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
			
			UIColor *color = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
			UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
			MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@"" icon:[LMAppIcon imageForIcon:LMIconRemoveFromQueue] backgroundColor:color padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
				LMMusicTrack *trackToRemove = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:listEntry.collectionIndex];
				
				[self.musicPlayer removeTrackFromQueue:trackToRemove];
				
				if(listEntry.collectionIndex == self.musicPlayer.indexOfNowPlayingTrack){
					if(self.musicPlayer.nowPlayingCollection.items.count > 0){
						NSInteger indexToUse = listEntry.collectionIndex;
						if(indexToUse >= self.musicPlayer.nowPlayingCollection.items.count){
							indexToUse = 0;
						}
						LMMusicTrack *newTrack = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:indexToUse];
						NSLog(@"New track %@", newTrack.title);
						[self.musicPlayer setNowPlayingTrack:newTrack];
						[self changeMusicTrack:newTrack withIndex:indexToUse];
					}
				}
				
				if(self.musicPlayer.nowPlayingCollection.items.count == 0){
					NSLog(@"Close");
				}
				
				NSLog(@"Remove %@", trackToRemove.title);
				
				return YES;
			}];
			saveButton.titleLabel.font = font;
			saveButton.titleLabel.hidden = YES;
			saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
			saveButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
			
			listEntry.rightButtons = @[ saveButton ];
			listEntry.rightButtonExpansionColour = [UIColor colorWithRed:0.92 green:0.00 blue:0.00 alpha:1.0];
			
			[self.itemArray addObject:listEntry];
		}
	}
	
	[self refreshNothingInQueueText];
}

- (void)reloadFavouriteStatus {
	UIImage *favouritesImageToUse = [LMAppIcon imageForIcon:self.loadedTrack.isFavourite ? LMIconFavouriteRed : LMIconFavouriteBlack];
	self.favouriteHeartImageView.image = favouritesImageToUse;
	[self.favouritesButton setImage:favouritesImageToUse];
}

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	[self reloadFavouriteStatus];
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	[self reloadFavouriteStatus];
}

- (void)changeFavouriteStatus {
	if(self.loadedTrack.isFavourite){
		[self.musicPlayer removeTrackFromFavourites:self.loadedTrack];
	}
	else{
		[self.musicPlayer addTrackToFavourites:self.loadedTrack];
	}
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	if([LMLayoutManager isiPad]){
		return ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/10.0f;
	}
	return ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/9.0f;
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
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
//	return @"queue title";
//	return [NSString stringWithFormat:@"boiii %d", (int)entry.collectionIndex];
	return [NSString stringWithFormat:@"%@", [[self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex] title]];
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
//	return @"queue subtitle";
	LMMusicTrack *associatedTrack = [self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex];
	
	if(self.loadedTrack.artist){
		return [NSString stringWithFormat:@"%@ - %@", [LMNowPlayingView durationStringTotalPlaybackTime:[associatedTrack playbackDuration]], associatedTrack.artist];
	}
	
	return [NSString stringWithFormat:@"%@", [LMNowPlayingView durationStringTotalPlaybackTime:[associatedTrack playbackDuration]]];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return [[self.musicPlayer.nowPlayingCollection.items objectAtIndex:entry.collectionIndex] albumArt];
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
		[self setNowPlayingQueueOpen:NO animated:YES];
		return;
	}
	else{ //Moving downward
		self.mainViewLeadingConstraint.constant = totalTranslation;
	}
	
	[self layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled){
		NSLog(@"Done");
		if((translation.x >= self.frame.size.width/4.0)){
			[self setNowPlayingQueueOpen:NO animated:YES];
		}
		else{
			[self setNowPlayingQueueOpen:YES animated:YES];
		}
	}
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	if(self.nowPlayingQueueOpen && [LMLayoutManager isiPad]){
		[self setNowPlayingQueueOpen:NO animated:YES];
	}
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self setupiPadSpecificLayout];
		
		self.buttonStackView.spacing = ((([LMLayoutManager isLandscapeiPad] || [LMLayoutManager isLandscape])
										 ? self.frame.size.height : self.frame.size.width) * 0.9 * ([LMLayoutManager isiPad] ? ([LMLayoutManager isLandscapeiPad] ? 0.3 : 0.5) : 0.35))/4.0;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	}];
}

- (void)setupiPadSpecificLayout {
	//Make sure it's the same everywhere
	CGFloat paddingViewPadding = ([LMLayoutManager sharedLayoutManager].isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height) * 0.04;
	
	if(self.currentiPadSpecificConstraintsArray){
		[NSLayoutConstraint deactivateConstraints:self.currentiPadSpecificConstraintsArray];
	}
	
	[self.queueTableView removeFromSuperview];
	
	self.currentiPadSpecificConstraintsArray = [NSLayoutConstraint autoCreateAndInstallConstraints:^{
		if(![LMLayoutManager isiPad]){
			[self.queueView addSubview:self.queueTableView];
			[self.queueTableView autoPinEdgesToSuperviewEdges];
			
			[self.paddingView autoCenterInSuperview];
			[self.paddingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:-paddingViewPadding];
			[self.paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-paddingViewPadding];
			return;
		}
		
		self.queueButton.hidden = [LMLayoutManager isLandscapeiPad];
		self.favouritesButton.hidden = !self.queueButton.hidden;
		self.favouriteHeartImageView.hidden = self.queueButton.hidden;
		
		if(self.queueButton.hidden){ //Is iPad landscape
			[self.mainView addSubview:self.queueTableView];
			
			[self.queueTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:paddingViewPadding];
			[self.queueTableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:paddingViewPadding];
			[self.queueTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:paddingViewPadding];
			[self.queueTableView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.mainView withMultiplier:(4.0/10.0)].constant = paddingViewPadding;
			
			[self.paddingView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
			[self.paddingView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:paddingViewPadding];
			[self.paddingView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:paddingViewPadding];
			[self.paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.mainView withMultiplier:(5.0/10.0)].constant = paddingViewPadding;
		}
		else{
			[self.queueView addSubview:self.queueTableView];
			[self.queueTableView autoPinEdgesToSuperviewEdges];
			
			[self.paddingView autoCenterInSuperview];
			[self.paddingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:-paddingViewPadding];
			[self.paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-paddingViewPadding];
		}
	}];
	
	[self.queueTableView reloadSubviewData];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	if(self.didLayoutConstraints){
		return;
	}
	self.didLayoutConstraints = YES;
	
	[self.layoutManager addDelegate:self];
		
	
	self.mainView = [LMView newAutoLayoutView];
//	self.mainView.backgroundColor = [UIColor yellowColor];
	self.mainView.clipsToBounds = YES;
	[self addSubview:self.mainView];
    
	self.mainViewLeadingConstraint = [self.mainView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.mainView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.mainView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.mainView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	
	
	
	self.queueView = [LMView newAutoLayoutView];
	self.queueView.backgroundColor = [UIColor whiteColor];
    self.queueView.hidden = YES;
	[self addSubview:self.queueView];
	
	NSArray *queueViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.queueView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.mainView];
		[self.queueView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:[LMLayoutManager isiPad] ? (2.0/4.0) : (3.0/4.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:queueViewPortraitConstraints];
	
	NSArray *queueViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.queueView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.queueView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.mainView];
		[self.queueView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/2.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:queueViewLandscapeConstraints];
	
	
	self.currentlyHighlighted = -1;
	
	self.queueTableView = [LMTableView newAutoLayoutView];
	self.queueTableView.totalAmountOfObjects = self.musicPlayer.nowPlayingCollection.count;
	self.queueTableView.subviewDataSource = self;
	self.queueTableView.shouldUseDividers = YES;
	self.queueTableView.title = @"QueueTableView";
	self.queueTableView.bottomSpacing = 0;
	self.queueTableView.notHighlightedBackgroundColour = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
	self.queueTableView.layer.masksToBounds = YES;
	self.queueTableView.layer.cornerRadius = 8.0;
	self.queueTableView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5]; //I wonder what this will do
	self.queueTableView.clipsToBounds = YES;
	self.queueTableView.alwaysBounceVertical = NO;
	self.queueTableView.longPressReorderDelegate = self;
	self.queueTableView.longPressReorderEnabled = YES;
	[self.queueView addSubview:self.queueTableView];
	
	//queueView constraints are setup in -setupiPadSpecificLayout
	
	
	
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
	[self.blurredBackgroundView autoCenterInSuperview];
	
	
	
	self.shuffleModeButton = [LMButton newAutoLayoutView];
	self.repeatModeButton = [LMButton newAutoLayoutView];
	self.queueButton = [LMButton newAutoLayoutView];
	self.airplayButton = [LMButton newAutoLayoutView];
	self.favouritesButton = [LMButton newAutoLayoutView];
	
	
	
	self.paddingView = [UIView newAutoLayoutView];
//	self.paddingView.backgroundColor = [UIColor purpleColor];
	[self.mainView addSubview:self.paddingView];
	
	//Make sure it's the same everywhere
	CGFloat paddingViewPadding = ([LMLayoutManager sharedLayoutManager].isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height) * 0.04;
	
	[self setupiPadSpecificLayout];
	
	
	self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
	self.trackInfoView.textAlignment = NSTextAlignmentCenter;
	self.trackInfoView.textColour = [UIColor blackColor];
	[self.paddingView addSubview:self.trackInfoView];
	
	
	self.favouriteHeartImageView = [UIImageView newAutoLayoutView];
	self.favouriteHeartImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.favouriteHeartImageView.image = [LMAppIcon imageForIcon:self.loadedTrack.isFavourite ? LMIconFavouriteRed : LMIconFavouriteBlack];
	self.favouriteHeartImageView.hidden = [LMLayoutManager isLandscapeiPad];
	self.favouriteHeartImageView.userInteractionEnabled = YES;
	[self.paddingView addSubview:self.favouriteHeartImageView];
	
	UITapGestureRecognizer *favouriteHeartImageViewTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeFavouriteStatus)];
	[self.favouriteHeartImageView addGestureRecognizer:favouriteHeartImageViewTapGesture];
	
	NSArray *favouriteHeartImageViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.favouriteHeartImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView withOffset:-5];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionHeight toSize:25.0f];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionWidth toSize:50.0f];
		[self.favouriteHeartImageView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.trackInfoView];
	}];
	[LMLayoutManager addNewPortraitConstraints:favouriteHeartImageViewPortraitConstraints];
	
	NSArray *favouriteHeartImageViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.favouriteHeartImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView withOffset:-5];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionHeight toSize:35.0f];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionWidth toSize:35.0f];
		[self.favouriteHeartImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView withOffset:0];
	}];
	[LMLayoutManager addNewLandscapeConstraints:favouriteHeartImageViewLandscapeConstraints];
	
	NSArray *avouriteHeartImageViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.favouriteHeartImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView withOffset:-5];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionHeight toSize:40.0f];
		[self.favouriteHeartImageView autoSetDimension:ALDimensionWidth toSize:80.0f];
		[self.favouriteHeartImageView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.trackInfoView];
	}];
	[LMLayoutManager addNewiPadConstraints:avouriteHeartImageViewiPadConstraints];
	
	
	self.albumArtRootView = [LMView newAutoLayoutView];
	self.albumArtRootView.backgroundColor = [UIColor clearColor];
	[self.paddingView addSubview:self.albumArtRootView];
	
	self.albumArtImageView = [UIImageView newAutoLayoutView];
	//	self.albumArtImageView.backgroundColor = [UIColor orangeColor];
	self.albumArtImageView.layer.masksToBounds = YES;
	self.albumArtImageView.layer.cornerRadius = 8.0f;
	[self.albumArtRootView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtRootView];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtRootView];
	
	//Constraints for these views are created after the button stack view
	
	
	
	
	NSArray *buttons = @[
						 self.shuffleModeButton, self.repeatModeButton, self.airplayButton, self.favouritesButton, self.queueButton
						 ];
	LMIcon icons[] = {
		LMIconShuffle, LMIconRepeat, LMIconAirPlay, LMIconFavouriteRed, LMIconHamburger
	};
	
	for(int i = 0; i < buttons.count; i++){
		LMButton *button = [buttons objectAtIndex:i];
		button.userInteractionEnabled = YES;
		[button setDelegate:self];
		[button setupWithImageMultiplier:0.4];
		[button setImage:[LMAppIcon imageForIcon:icons[i]]];
		[button setColour:[LMColour fadedColour]];
		//		[background addSubview:button];
		
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
		else if(button == self.favouritesButton){
			self.favouritesButton.hidden = ![LMLayoutManager isLandscapeiPad];
		}
	}
	
	self.buttonStackView = [UIStackView newAutoLayoutView];
	self.buttonStackView.backgroundColor = [UIColor blueColor];
	self.buttonStackView.axis = UILayoutConstraintAxisHorizontal;
	self.buttonStackView.distribution = UIStackViewDistributionFillEqually;
	self.buttonStackView.spacing = ((([LMLayoutManager isLandscapeiPad] || [LMLayoutManager isLandscape])
									 ? self.frame.size.height : self.frame.size.width) * 0.9 * ([LMLayoutManager isiPad] ? ([LMLayoutManager isLandscapeiPad] ? 0.3 : 0.5) : 0.35))/4.0;
	[self.paddingView addSubview:self.buttonStackView];
	
	
	NSArray *stackViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonStackView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.paddingView withMultiplier:(1.0/8.0)];
		[self.buttonStackView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView withOffset:10];
		[self.buttonStackView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView withOffset:-10];
		[self.buttonStackView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:15];
	}];
	[LMLayoutManager addNewPortraitConstraints:stackViewPortraitConstraints];
	
	NSArray *stackViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonStackView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.paddingView withMultiplier:(1.5/8.0)];
		[self.buttonStackView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView withOffset:10];
		[self.buttonStackView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView withOffset:-10];
		[self.buttonStackView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:stackViewLandscapeConstraints];
	
	NSArray *stackViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonStackView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.paddingView withMultiplier:(1.0/8.0)];
		[self.buttonStackView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.albumArtImageView];
		[self.buttonStackView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtImageView withMultiplier:0.70];
		[self.buttonStackView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.paddingView];
	}];
	[LMLayoutManager addNewiPadConstraints:stackViewiPadConstraints];
	
	for(LMButton *button in buttons){
		[self.buttonStackView addArrangedSubview:button];
	}
	
	
//	self.colourBackgroundView = [UIView newAutoLayoutView];
//	self.colourBackgroundView.backgroundColor = [UIColor whiteColor];
//	[self.blurredBackgroundView addSubview:self.colourBackgroundView];
//	
//	[self.colourBackgroundView autoPinEdgesToSuperviewEdges];
//	self.colourBackgroundView.hidden = YES;
	
	
	self.progressSlider = [LMProgressSlider newAutoLayoutView];
	self.progressSlider.nowPlayingView = YES;
	self.progressSlider.backgroundBackgroundColour = [LMColour fadedColour];
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.delegate = self;
	self.progressSlider.value = self.musicPlayer.currentPlaybackTime;
	self.progressSlider.lightTheme = YES;
	self.progressSlider.autoShrink = YES;
	[self.paddingView addSubview:self.progressSlider];
	//Constraints for this view are added below the image view constraint code since this view is pinned to the bottom of the album art root view
	
	
	
	
	NSArray *albumArtRootViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.albumArtRootView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.paddingView];
		[self.albumArtRootView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.paddingView];
		[self.albumArtRootView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.paddingView];
		[self.albumArtRootView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.paddingView];
		[self.albumArtRootView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.paddingView];
	}];
	[LMLayoutManager addNewPortraitConstraints:albumArtRootViewPortraitConstraints];
	
	NSArray *albumArtRootViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.albumArtRootView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.albumArtRootView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.albumArtRootView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.progressSlider withOffset:-paddingViewPadding/2];
		[self.albumArtRootView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.albumArtRootView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:albumArtRootViewLandscapeConstraints];
	
	NSArray *albumArtRootViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.albumArtRootView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.albumArtRootView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.paddingView withMultiplier:(9.0/10.0)];
		[self.albumArtRootView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.albumArtRootView];
		[self.albumArtRootView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.paddingView];
	}];
	[LMLayoutManager addNewiPadConstraints:albumArtRootViewiPadConstraints];
	
	
	
	
	
	NSArray *progressSliderPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView];
		[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtImageView];
		[self.progressSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtRootView withOffset:paddingViewPadding/2];
		[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/12.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:progressSliderPortraitConstraints];

	NSArray *progressSliderLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.progressSlider autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.progressSlider autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.progressSlider autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/12.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:progressSliderLandscapeConstraints];
	
	NSArray *progressSlideriPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView];
		[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtImageView];
		[self.progressSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtRootView withOffset:paddingViewPadding/4];
		[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.paddingView withMultiplier:(1.0/16.0)];
	}];
	[LMLayoutManager addNewiPadConstraints:progressSlideriPadConstraints];
	
	
	//Track info view created above the button stack view
	
	//TODO: Fix this being manually set value
	NSArray *trackInfoViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.progressSlider withOffset:30];
		[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.progressSlider withOffset:20];
		[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.progressSlider withOffset:-20];
		[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.paddingView withMultiplier:(1.0/6.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:trackInfoViewPortraitConstraints];
	
	NSArray *trackInfoViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.paddingView withOffset:20];
		[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumArtRootView withOffset:20];
		[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.paddingView withOffset:-20];
		[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.paddingView withMultiplier:(1.0/6.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:trackInfoViewLandscapeConstraints];

	NSArray *trackInfoViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.progressSlider withOffset:15];
		[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.progressSlider withOffset:20];
		[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.progressSlider withOffset:-20];
		[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.paddingView withMultiplier:(1.0/8.0)];
	}];
	[LMLayoutManager addNewiPadConstraints:trackInfoViewiPadConstraints];
	
	
	
	[self.shuffleModeButton setColour:self.musicPlayer.shuffleMode ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	[self.repeatModeButton setColour:(self.musicPlayer.repeatMode != LMMusicRepeatModeNone) ? [[UIColor whiteColor] colorWithAlphaComponent:(8.0/10.0)] : [LMColour fadedColour]];
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self updateRepeatButtonImage];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedNowPlaying)];
	[self.mainView addGestureRecognizer:tapGesture];
	
//	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panNowPlayingDown:)];
//	self.albumArtImageView.userInteractionEnabled = YES;
//	[self.albumArtImageView addGestureRecognizer:panGestureRecognizer];
	
	
	self.queueOpenDraggingOverlayView = [LMView newAutoLayoutView];;
//	self.queueOpenDraggingOverlayView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.5 alpha:0.4];
	self.queueOpenDraggingOverlayView.hidden = YES;
	[self.paddingView addSubview:self.queueOpenDraggingOverlayView];
	
	[self.queueOpenDraggingOverlayView autoPinEdgesToSuperviewEdges];
	
	UIPanGestureRecognizer *queueOpenPanGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panQueueClosed:)];
	[self.queueOpenDraggingOverlayView addGestureRecognizer:queueOpenPanGesture];
	
	UITapGestureRecognizer *queueOpenTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(queueCloseTap)];
	[self.queueOpenDraggingOverlayView addGestureRecognizer:queueOpenTapGesture];
	
//	[self setNowPlayingQueueOpen:YES animated:YES];
	
	AVAudioSession* audioSession = [AVAudioSession sharedInstance];
	AVAudioSessionRouteDescription* currentRoute = audioSession.currentRoute;
	for(AVAudioSessionPortDescription* outputPort in currentRoute.outputs){
		[self musicOutputPortDidChange:outputPort];
	}
	
	[self reloadFavouriteStatus];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
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
