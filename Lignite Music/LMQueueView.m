//
//  LMQueueView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMQueueViewFlowLayout.h"
#import "LMQueueViewHeader.h"
#import "NSTimer+Blocks.h"
#import "LMThemeEngine.h"
#import "LMMusicPlayer.h"
#import "LMListEntry.h"
#import "LMQueueView.h"
#import "LMColour.h"

@interface LMQueueView()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LMMusicQueueDelegate, LMListEntryDelegate, LMQueueViewHeaderDelegate, LMMusicPlayerDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate>

/**
 The collection view which displays the queue.
 */
@property UICollectionView *collectionView;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The title label for nothing in queue.
 */
@property UILabel *nothingInQueueTitleLabel;

/**
 The label which will display if nothing is in queue or iOS isn't giving us a queue.
 */
@property UILabel *nothingInQueueLabel;

/**
 The list entry that's currently being moved.
 */
@property LMListEntry *currentlyMovingListEntry;

/**
 The latest header that the collection view is using.
 */
@property LMQueueViewHeader *latestHeader;

/**
 The last row cell of the previous tracks section.
 */
@property UICollectionViewCell *previousTracksSectionLastRowCell;

/**
 The last row cell of the previous section.
 */
@property UICollectionViewCell *nextUpSectionLastRowCell;

/**
 Whether or not the user is currently reordering.
 */
@property BOOL isReordering;

/**
 The view which tells the user that the queue is being loaded.
 */
@property UIView *loadingQueueView;

/**
 The loading activity indicator view for when the queue is loading.
 */
@property UIActivityIndicatorView *loadingActivityIndicator;

@property UINotificationFeedbackGenerator *feedbackGenerator; //Temporary I hope

@end

@implementation LMQueueView

@synthesize whiteText = _whiteText;
@synthesize isReordering = _isReordering;

- (UIImage*)iconForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks && [self playingFirstTrackInQueue]){
		return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	return [LMAppIcon imageForIcon:header.isForPreviousTracks ? LMIconPreviousTracks : LMIconNextTracks];
}

- (BOOL)playingFirstTrackInQueue {
	return (self.musicPlayer.queue.previousTracks.count == 0 && self.musicPlayer.nowPlayingTrack);
}

- (NSString*)titleForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks){
		if([self playingFirstTrackInQueue]){
			return NSLocalizedString(@"NowPlayingTrack", nil);
		}
		
		BOOL singular = (self.musicPlayer.queue.previousTracks.count == 1);
		
		NSString *title = NSLocalizedString(singular ? @"PreviousTracksTitleSingular" : @"PreviousTracksTitlePlural", nil);
		
		return title;
	}
	
	return NSLocalizedString((self.musicPlayer.queue.nextTracks.count == 0) ? @"NothingUpNextTitle" : @"UpNextTitle", nil);
}

- (NSString*)subtitleForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks && [self playingFirstTrackInQueue]){
		return NSLocalizedString(@"NowPlayingTrackSubtitle", nil);
	}
	
	NSInteger trackCount = header.isForPreviousTracks ? self.musicPlayer.queue.previousTracks.count : self.musicPlayer.queue.nextTracks.count;
	
	if(trackCount == 0){
		return NSLocalizedString(@"NothingUpNextSubtitle", nil);
	}
	
	BOOL singular = (trackCount == 1);
	
	NSString *trackCountString = [NSString stringWithFormat:NSLocalizedString(singular ? @"XSongsSingle" : @"XSongs", nil), trackCount];
	
	return trackCountString;
}


- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %@", entry);
	
	[self.musicPlayer setNowPlayingTrack:(LMMusicTrack*)entry.associatedData];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour mainColour];
}

- (LMMusicTrack*)trackForIndexPath:(NSIndexPath*)indexPath {
	BOOL isPreviousTracks = (indexPath.section == 0);
	
	NSArray *tracksArray = isPreviousTracks ? self.musicPlayer.queue.previousTracks : self.musicPlayer.queue.nextTracks;
	
	LMMusicTrack *track = nil;
	if(isPreviousTracks && (indexPath.row == tracksArray.count)){
//		NSLog(@"Index path is now playing %@", indexPath);
		track = self.musicPlayer.nowPlayingTrack;
	}
	else{
		track = [tracksArray objectAtIndex:indexPath.row];
	}
	
	return track;
}

- (LMMusicTrack*)trackForListEntry:(LMListEntry*)entry {
	return [self trackForIndexPath:entry.indexPath];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self trackForListEntry:entry];
//	NSInteger indexInCompleteQueue = [self.musicPlayer.queue indexOfTrackInCompleteQueueFromIndexPath:entry.indexPath];
//	NSString *fixedTitle = [NSString stringWithFormat:@"%d@%d == %d: %@", (int)entry.indexPath.row, (int)entry.indexPath.section, (int)indexInCompleteQueue, track.title];
//	return fixedTitle;
	
	entry.isAccessibilityElement = YES;
	entry.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@", track.title, [self subtitleForListEntry:entry], NSLocalizedString(entry.highlighted ? @"VoiceOverLabel_Selected" : @"", nil)];
	entry.accessibilityHint = NSLocalizedString(entry.highlighted ? @"" : @"VoiceOverHint_DetailViewListEntry", nil);
	
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self trackForListEntry:entry];
	return track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil);
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	UIImage *albumArt = [self trackForListEntry:entry].albumArt;
	if(!albumArt){
		albumArt = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	return albumArt;
}

- (NSArray<MGSwipeButton*>*)swipeButtonsForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	LMMusicTrack *track = (LMMusicTrack*)listEntry.associatedData;
	
	NSInteger indexOfListEntry = [self.musicPlayer.queue indexOfTrackInCompleteQueueFromIndexPath:listEntry.indexPath];
	
	if((indexOfListEntry == self.musicPlayer.queue.indexOfNowPlayingTrack)
	   && rightSide
	   && (self.musicPlayer.queue.completeQueueCount == 1)){
		return nil;
	}
	
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
	UIColor *colour = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
	UIImage *icon = [LMAppIcon imageForIcon:LMIconRemoveFromQueue];
	if(!rightSide){ //Favourite/unfavourite
		icon = [LMAppIcon imageForIcon:track.isFavourite ? LMIconUnfavouriteWhite : LMIconFavouriteWhiteFilled];
	}
	
	MGSwipeButton *swipeButton
	= [MGSwipeButton buttonWithTitle:@""
								icon:icon
					 backgroundColor:colour
							 padding:0
							callback:^BOOL(MGSwipeTableCell *sender) {
								if(rightSide){
									[self.musicPlayer.queue removeTrackAtIndex:indexOfListEntry];
									
									NSLog(@"Queue %@", track.title);
								}
								else{
									if(track.isFavourite){
										[self.musicPlayer removeTrackFromFavourites:track];
									}
									else{
										[self.musicPlayer addTrackToFavourites:track];
									}
									
									NSLog(@"Favourite %@", track.title);
								}
								
								return YES;
							}];
	
	swipeButton.titleLabel.font = font;
	swipeButton.titleLabel.hidden = YES;
	swipeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
	swipeButton.imageEdgeInsets = UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 18 : 25, 0, LMLayoutManager.isExtraSmall ? 18 : 25, 0);
	
	//	swipeButton.clipsToBounds = YES;
	//	swipeButton.layer.masksToBounds = YES;
	//	swipeButton.layer.cornerRadius = 8.0f;
	
	return @[ swipeButton ];
}

- (UIColor*)swipeButtonColourForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	UIColor *swipeColour = [LMColour successGreenColour];
	
	LMMusicTrack *musicTrack = (LMMusicTrack*)listEntry.associatedData;
	
	if((!rightSide && musicTrack.isFavourite) || rightSide){ //Favourite/unfavourite
		swipeColour = [LMColour deletionRedColour];
	}
	
	return swipeColour;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
//	cell.backgroundColor = [LMColour randomColour];
	
	
//	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
//	NSLog(@"Reloading cell for index %d", (int)indexPath.row);
	
	if(cell.contentView.subviews.count > 0){
		LMListEntry *listEntry = nil;
		for(UIView *subview in cell.contentView.subviews){
			if([subview class] == [LMListEntry class]) {
				listEntry = (LMListEntry*)subview;
				break;
			}
		}
		
		if(listEntry){
			listEntry.indexPath = indexPath;
			
			BOOL shouldHighlight = ([self trackForListEntry:listEntry] == self.musicPlayer.nowPlayingTrack);
			[listEntry setAsHighlighted:shouldHighlight animated:NO];
			
			BOOL isPreviousTrack = (listEntry.indexPath.section == 0) && (listEntry.indexPath.row < self.musicPlayer.queue.previousTracks.count);
			listEntry.contentView.alpha = isPreviousTrack ? (2.0 / 4.0) : 1.0;
			
			LMMusicTrack *listEntryTrack = [self trackForListEntry:listEntry];
			listEntry.associatedData = listEntryTrack;
			
//			listEntry.backgroundColor = [LMColour whiteColour];
			
			[listEntry reloadContents];
			[listEntry resetSwipeButtons:NO];
			
			listEntry.leadingConstraint.constant = (([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 20 : 0);
			listEntry.trailingConstraint.constant = (([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 20 : 0);
		}
	}
	else {
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.indexPath = indexPath;
		LMMusicTrack *listEntryTrack = [self trackForListEntry:listEntry];
		listEntry.associatedData = listEntryTrack;
		listEntry.isLabelBased = NO;
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = NO;
		
		BOOL isPreviousTrack = (listEntry.indexPath.section == 0) && (listEntry.indexPath.row < self.musicPlayer.queue.previousTracks.count);
		listEntry.contentView.alpha = isPreviousTrack ? (2.0 / 4.0) : 1.0;
		
//		NSLog(@"Created new list entry for track %@", listEntryTrack.title);
		
		BOOL shouldHighlight = (listEntryTrack == self.musicPlayer.nowPlayingTrack);
		[listEntry setAsHighlighted:shouldHighlight animated:NO];
		
		[cell.contentView addSubview:listEntry];
		cell.backgroundColor = [LMColour whiteColour];
//		listEntry.layer.masksToBounds = NO;
//		listEntry.layer.cornerRadius = 8.0f;
		
		listEntry.leadingConstraint = [listEntry autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 20 : 0];
		listEntry.trailingConstraint = [listEntry autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 20 : 0];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}

	if(@available(iOS 11.0, *)){
		BOOL isFirstRow = (indexPath.row == 0);
		BOOL isLastRow = (indexPath.row == ([self collectionView:self.collectionView numberOfItemsInSection:indexPath.section] - 1));
		BOOL isFirstSection = (indexPath.section == 0);
		
		if(self.isReordering){
			cell.clipsToBounds = NO;
		}
		if(isLastRow && isFirstSection){
			self.previousTracksSectionLastRowCell = cell;
			
			cell.clipsToBounds = YES;
			cell.layer.cornerRadius = 8.0f;
			cell.layer.maskedCorners = (kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
		}
		else if(isFirstRow && !isFirstSection){
			self.nextUpSectionLastRowCell = cell;
			
			cell.clipsToBounds = YES;
			cell.layer.cornerRadius = 8.0f;
			cell.layer.maskedCorners = (kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner);
		}
		else{
			cell.clipsToBounds = NO;
		}
	}
	
	return cell;
}

- (void)setWhiteText:(BOOL)whiteText {
	_whiteText = whiteText;
	
	if(self.collectionView){
		[self.collectionView reloadData];
	}
}

- (BOOL)whiteText {
	return _whiteText;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView
		  viewForSupplementaryElementOfKind:(NSString *)kind
								atIndexPath:(NSIndexPath *)indexPath {
	
	NSString *reuseIdentifier = (indexPath.section == 0) ? @"previousTracksHeaderIdentifier" : @"nextTracksHeaderIdentifier";
	
	LMQueueViewHeader *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
																		withReuseIdentifier:reuseIdentifier
																			   forIndexPath:indexPath];
	
	header.isForPreviousTracks = (indexPath.section == 0);
	header.delegate = self;
	header.whiteText = self.whiteText;
	
	header.backgroundColor = self.isReordering ? [LMColour whiteColour] : [LMColour clearColour];
	
	[header reload];
	
	self.latestHeader = header;
	
	return header;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	if(!self.musicPlayer.queue.hasBeenBuilt){
		return 0;
	}
	
	return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if(!self.musicPlayer.queue.hasBeenBuilt){
		return 0;
	}
	
	BOOL hideNoTracksLabel = !(self.musicPlayer.queue.count == 0);
	
	self.nothingInQueueTitleLabel.hidden = hideNoTracksLabel;
	self.nothingInQueueLabel.hidden = hideNoTracksLabel;
	
	self.collectionView.hidden = !hideNoTracksLabel;
	
	NSInteger addition = 0;
	LMQueueViewFlowLayout *flowLayout = (LMQueueViewFlowLayout*)self.collectionView.collectionViewLayout;
	if(flowLayout.sectionDifferences.count > 0){
		addition += [[flowLayout.sectionDifferences objectAtIndex:section] integerValue];
		NSLog(@"Adding addition");
	}
	
	return ((section == 0) ? (self.musicPlayer.queue.previousTracks.count + 1)
			: self.musicPlayer.queue.nextTracks.count)
			+ addition;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(self.frame.size.width, LMLayoutManager.standardListEntryHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	
	if(section == 0){
		return CGSizeZero;
	}
	
	return CGSizeMake(self.collectionView.frame.size.width, [LMLayoutManager standardListEntryHeight]);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
	BOOL isNowPlayingTrack = ([self trackForIndexPath:indexPath] == self.musicPlayer.nowPlayingTrack);
	
	return !isNowPlayingTrack;
}

- (void)collectionView:(UICollectionView *)collectionView
   moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
		   toIndexPath:(NSIndexPath *)destinationIndexPath {
	
	NSLog(@"Move item from %@ to %@", sourceIndexPath, destinationIndexPath);
	
	[self.musicPlayer.queue moveTrackFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
	
	LMQueueViewFlowLayout *flowLayout = (LMQueueViewFlowLayout*)self.collectionView.collectionViewLayout;
	[flowLayout finishedInteractivelyMoving];
}

- (void)setIsReordering:(BOOL)isReordering {
	_isReordering = isReordering;
	
	if(self.delegate){
		[self.delegate queueViewIsReordering:isReordering];
		
		if(self.latestHeader && self.latestHeader.whiteText && isReordering){
			[self.latestHeader setWhiteText:NO];
			
			self.latestHeader.previouslyUsingWhiteText = YES;
		}
		else if(self.latestHeader && !self.latestHeader.whiteText && self.latestHeader.previouslyUsingWhiteText){
			[self.latestHeader setWhiteText:YES];
			
			self.latestHeader.previouslyUsingWhiteText = NO;
		}
	}
}

- (BOOL)isReordering {
	return _isReordering;
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer*)longPressGesture {
	NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPressGesture locationInView:self.collectionView]];
	
	CGPoint movementPoint = [longPressGesture locationInView:self.collectionView];
	movementPoint.x = (self.collectionView.frame.size.width / 2.0);
	
	switch(longPressGesture.state){
		case UIGestureRecognizerStateBegan: {
			[self.delegate displayQueueCantReorderWarning];
			
			self.feedbackGenerator = [UINotificationFeedbackGenerator new];
			[self.feedbackGenerator prepare];
			[self.feedbackGenerator notificationOccurred:UINotificationFeedbackTypeError];
			self.feedbackGenerator = nil;
			return;
			
			if(indexPath){
				self.isReordering = YES;
				
				self.previousTracksSectionLastRowCell.clipsToBounds = NO;
				self.nextUpSectionLastRowCell.clipsToBounds = NO;
				
				[self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
				
				if(!self.currentlyMovingListEntry){
					UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
					if(cell.contentView.subviews.count > 0){
						for(UIView *subview in cell.contentView.subviews){
							if([subview class] == [LMListEntry class]){
								self.currentlyMovingListEntry = (LMListEntry*)subview;
								break;
							}
						}
					}
				}
				
				if(self.currentlyMovingListEntry){
					if(self.currentlyMovingListEntry.contentView.alpha < 1.0){
						self.currentlyMovingListEntry.previousAlpha = self.currentlyMovingListEntry.contentView.alpha;
						
						[UIView animateWithDuration:0.3 animations:^{
							self.currentlyMovingListEntry.contentView.alpha = 1.0;
						}];
					}
				}
				
				[UIView animateWithDuration:0.3 animations:^{
					self.latestHeader.backgroundColor = [LMColour whiteColour];
				}];
			}
			break;
		}
		case UIGestureRecognizerStateChanged: {
//			[self.collectionView.collectionViewLayout invalidateLayout];
			[self.collectionView updateInteractiveMovementTargetPosition:movementPoint];
			break;
		}
		case UIGestureRecognizerStateEnded: {
			[self.collectionView.collectionViewLayout invalidateLayout];
			[self.collectionView endInteractiveMovement];
			
			if(self.currentlyMovingListEntry){
				if(self.currentlyMovingListEntry.previousAlpha > 0.0){
					[UIView animateWithDuration:0.3 animations:^{
						self.currentlyMovingListEntry.contentView.alpha = self.currentlyMovingListEntry.previousAlpha;
					} completion:^(BOOL finished) {
						[self reloadLayout];
					}];
					
					self.currentlyMovingListEntry.previousAlpha = 0.0;
				}
				
				self.currentlyMovingListEntry = nil;
			}
			
			self.isReordering = NO;
			
//			[NSTimer scheduledTimerWithTimeInterval:3.0 block:^{
				[UIView animateWithDuration:0.3 animations:^{
					self.latestHeader.backgroundColor = [LMColour clearColour];
				}];
//			} repeats:NO];
			
			[self reloadLayout];
			break;
		}
		default: {
			self.isReordering = NO;
			
//			[NSTimer scheduledTimerWithTimeInterval:3.0 block:^{
				[UIView animateWithDuration:0.3 animations:^{
					self.latestHeader.backgroundColor = [LMColour clearColour];
				}];
//			} repeats:NO];
			
			[self.collectionView.collectionViewLayout invalidateLayout];
			[self.collectionView cancelInteractiveMovement];
			
			self.currentlyMovingListEntry = nil;
			break;
		}
	}
}



- (void)queueBegan {
	[self reloadLayout];
	
	NSLog(@"Queue began.");
}

- (void)queueCompletelyChanged {
	[self reloadLayout];
	
	NSLog(@"Queue completely changed.");
}

- (void)queueEnded {
	[self reloadLayout];
	
	NSLog(@"Queue ended.");
}

- (void)queueChangedToShuffleMode:(LMMusicShuffleMode)shuffleMode {
	[self reloadLayout];
}

- (void)reloadLayout {
	[self.collectionView reloadData];
	[self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)trackMovedInQueue:(LMMusicTrack*)trackMoved {
	[self reloadLayout];
}

- (void)trackRemovedFromQueue:(LMMusicTrack *)trackRemoved {
	[self reloadLayout];
}

- (void)trackAddedToQueue:(LMMusicTrack *)trackAdded {
	[self reloadLayout];
}


- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	[self reloadLayout];
}

- (void)trackAddedToFavourites:(LMMusicTrack*)track {
	[self reloadLayout];
}

- (void)trackRemovedFromFavourites:(LMMusicTrack*)track {
	[self reloadLayout];
}

- (void)resetContentOffsetToNowPlaying:(BOOL)animated {
//	NSLog(@"Reset content offset");
	
	if(self.collectionView.contentSize.height < (self.collectionView.frame.size.height * 1.5)){
		return;
	}
	
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.musicPlayer.queue.previousTracks.count inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
	
	[UIView animateWithDuration:animated ? 0.1 : 0.0 animations:^{
		self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y - 10);
	}];
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	[self reloadLayout];
}

- (void)themeChanged:(LMTheme)theme {
	[self reloadLayout];
}

- (void)queueInvalidated {
	self.loadingQueueView.hidden = NO;
}

- (void)queueIsBeingRebuilt:(BOOL)rebuilding becauseOfActionType:(LMMusicQueueActionType)actionType {
	self.loadingQueueView.hidden = !rebuilding;
	
	if(actionType == LMMusicQueueActionTypeOpenQueue){
		rebuilding ? [self.loadingActivityIndicator startAnimating] : [self.loadingActivityIndicator stopAnimating];
		
		if(!rebuilding){
			[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
				[self resetContentOffsetToNowPlaying:YES];
			} repeats:NO];
		}
	}
}

- (void)prepareForRebuild {
	[self.loadingActivityIndicator startAnimating];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
//		self.backgroundColor = [UIColor blueColor];
		
		if([LMLayoutManager isiPhoneX]){
			self.layoutManager = [LMLayoutManager sharedLayoutManager];
			[self.layoutManager addDelegate:self];
		}
		
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		[self.musicPlayer.queue addDelegate:self];
		
		
		self.backgroundColor = [LMColour clearColour];
		

		
//		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
//		fuck.sectionInset = UIEdgeInsetsMake(10, 0, 10, 0);
//		fuck.headerReferenceSize = CGSizeMake(WINDOW_FRAME.size.width, LMLayoutManager.standardListEntryHeight);

		LMQueueViewFlowLayout *fuck = [[LMQueueViewFlowLayout alloc]init];
//		fuck.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
		fuck.headerReferenceSize = CGSizeMake(WINDOW_FRAME.size.width, LMLayoutManager.standardListEntryHeight);

		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
//		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
		self.collectionView.backgroundColor = [LMColour clearColour];
		[self.collectionView registerClass:[UICollectionViewCell class]
				forCellWithReuseIdentifier:@"cellIdentifier"];
		[self.collectionView registerClass:[LMQueueViewHeader class]
				forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
					   withReuseIdentifier:@"previousTracksHeaderIdentifier"];
		[self.collectionView registerClass:[LMQueueViewHeader class]
				forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
					   withReuseIdentifier:@"nextTracksHeaderIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
		
		UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureHandler:)];
		[self.collectionView addGestureRecognizer:longPressGesture];
		
		
		
		self.nothingInQueueTitleLabel = [UILabel newAutoLayoutView];
		self.nothingInQueueTitleLabel.numberOfLines = 0;
		self.nothingInQueueTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22.0f];
		self.nothingInQueueTitleLabel.text = NSLocalizedString(@"NothingInQueue", nil);
		self.nothingInQueueTitleLabel.textAlignment = NSTextAlignmentLeft;
		self.nothingInQueueTitleLabel.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.nothingInQueueTitleLabel];
		
		if([LMLayoutManager isiPhoneX]){
			NSArray *nothingInQueueTitleLabelPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:40];
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
			}];
			[LMLayoutManager addNewPortraitConstraints:nothingInQueueTitleLabelPortraitConstraints];
			
			NSArray *nothingInQueueTitleLabelLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
				[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:64];
			}];
			[LMLayoutManager addNewLandscapeConstraints:nothingInQueueTitleLabelLandscapeConstraints];
		}
		else{
			[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
			[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
			[self.nothingInQueueTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
		}
		
		
		self.nothingInQueueLabel = [UILabel newAutoLayoutView];
		self.nothingInQueueLabel.numberOfLines = 0;
		self.nothingInQueueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
		self.nothingInQueueLabel.text = NSLocalizedString(@"NothingInQueueDescription", nil);
		self.nothingInQueueLabel.textAlignment = NSTextAlignmentLeft;
		self.nothingInQueueLabel.backgroundColor = [UIColor whiteColor];
		self.nothingInQueueLabel.textColor = [UIColor blackColor];
		[self addSubview:self.nothingInQueueLabel];
		
		[self.nothingInQueueLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nothingInQueueTitleLabel withOffset:20];
		[self.nothingInQueueLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.nothingInQueueTitleLabel];
		[self.nothingInQueueLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.nothingInQueueTitleLabel];
		
		
		
		self.loadingQueueView = [UIView newAutoLayoutView];
		self.loadingQueueView.userInteractionEnabled = YES;
		self.loadingQueueView.backgroundColor = [LMColour whiteColour];
		[self addSubview:self.loadingQueueView];
		
		[self.loadingQueueView autoPinEdgesToSuperviewEdges];
		
		
		UIView *loadingContainerView = [UIView newAutoLayoutView];
		loadingContainerView.backgroundColor = [LMColour whiteColour];
		[self.loadingQueueView addSubview:loadingContainerView];
		
		[loadingContainerView autoCentreInSuperview];
		[loadingContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[loadingContainerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		UILabel *loadingText = [UILabel newAutoLayoutView];
		loadingText.textColor = [LMColour blackColour];
		loadingText.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
		loadingText.textAlignment = NSTextAlignmentCentre;
		loadingText.text = NSLocalizedString(@"PlayingNewQueue", nil);
		[loadingContainerView addSubview:loadingText];
		
		[loadingText autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[loadingText autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[loadingText autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		self.loadingActivityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		self.loadingActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		[loadingContainerView addSubview:self.loadingActivityIndicator];
		
		[self.loadingActivityIndicator autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:loadingText withOffset:-10];
		[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.loadingActivityIndicator autoAlignAxisToSuperviewAxis:ALAxisVertical];
		
		
		[self queueIsBeingRebuilt:(self.musicPlayer.queue.completeQueueCount == 0)
			  becauseOfActionType:LMMusicQueueActionTypeOpenQueue];
	}
}

@end
