//
//  LMQueueView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMQueueViewHeader.h"
#import "LMMusicPlayer.h"
#import "LMMusicQueue.h"
#import "LMListEntry.h"
#import "LMQueueView.h"
#import "LMColour.h"

@interface LMQueueView()<UICollectionViewDelegate, UICollectionViewDataSource, LMMusicQueueDelegate, LMListEntryDelegate, LMQueueViewHeaderDelegate, LMMusicPlayerDelegate>

/**
 The collection view which displays the queue.
 */
@property UICollectionView *collectionView;

/**
 The music queue.
 */
@property LMMusicQueue *musicQueue;

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

@end

@implementation LMQueueView

- (UIImage*)iconForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks && [self playingFirstTrackInQueue]){
		return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	}
	return [LMAppIcon imageForIcon:header.isForPreviousTracks ? LMIconPreviousTracks : LMIconNextTracks];
}

- (BOOL)playingFirstTrackInQueue {
	return (self.musicQueue.previousTracks.count == 0 && self.musicPlayer.nowPlayingTrack);
}

- (NSString*)titleForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks){
		if([self playingFirstTrackInQueue]){
			return NSLocalizedString(@"NowPlayingTrack", nil);
		}
		
		BOOL singular = (self.musicQueue.previousTracks.count == 1);
		
		NSString *title = NSLocalizedString(singular ? @"PreviousTracksTitleSingular" : @"PreviousTracksTitlePlural", nil);
		
		return title;
	}
	
	return NSLocalizedString((self.musicQueue.nextTracks.count == 0) ? @"NothingUpNextTitle" : @"UpNextTitle", nil);
}

- (NSString*)subtitleForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks && [self playingFirstTrackInQueue]){
		return NSLocalizedString(@"NowPlayingTrackSubtitle", nil);
	}
	
	NSInteger trackCount = header.isForPreviousTracks ? self.musicQueue.previousTracks.count : self.musicQueue.nextTracks.count;
	
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
	return [UIColor redColor];
}

- (LMMusicTrack*)trackForIndexPath:(NSIndexPath*)indexPath {
	BOOL isPreviousTracks = (indexPath.section == 0);
	
	NSArray *tracksArray = isPreviousTracks ? self.musicQueue.previousTracks : self.musicQueue.nextTracks;
	
	LMMusicTrack *track = nil;
	if(isPreviousTracks && (indexPath.row == tracksArray.count)){
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
	NSInteger indexInCompleteQueue
		= [self.musicQueue indexOfTrackInCompleteQueueFromPreviousTracks:(entry.indexPath.section == 0)
												   withIndexInSubQueueOf:entry.indexPath.row];
	NSString *fixedTitle = [NSString stringWithFormat:@"%d@%d == %d: %@", (int)entry.indexPath.row, (int)entry.indexPath.section, (int)indexInCompleteQueue, track.title];
//	return fixedTitle;
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
	
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
	UIColor *colour = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
	UIImage *icon = [LMAppIcon imageForIcon:LMIconAddToQueue];
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
									[self.musicPlayer addTrackToQueue:track];
									
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
	
	if(!rightSide && musicTrack.isFavourite){ //Favourite/unfavourite
		swipeColour = [LMColour deletionRedColour];
	}
	
	return swipeColour;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
//	cell.backgroundColor = [LMColour randomColour];
	
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	NSLog(@"Reloading cell for index %d", (int)indexPath.row);
	
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
			
			BOOL isPreviousTrack = (listEntry.indexPath.section == 0) && (listEntry.indexPath.row < self.musicQueue.previousTracks.count);
			listEntry.alpha = isPreviousTrack ? (2.0 / 4.0) : 1.0;
			
			LMMusicTrack *listEntryTrack = [self trackForListEntry:listEntry];
			listEntry.associatedData = listEntryTrack;
			
//			listEntry.backgroundColor = [LMColour whiteColour];
			
			[listEntry reloadContents];
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
		
		BOOL isPreviousTrack = (listEntry.indexPath.section == 0) && (listEntry.indexPath.row < self.musicQueue.previousTracks.count);
		listEntry.alpha = isPreviousTrack ? (2.0 / 4.0) : 1.0;
		
		NSLog(@"Created new list entry for track %@", listEntryTrack.title);
		
		BOOL shouldHighlight = (listEntryTrack == self.musicPlayer.nowPlayingTrack);
		[listEntry setAsHighlighted:shouldHighlight animated:NO];
		
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour whiteColour];
		
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 0 : 0];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 44 : 0];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
//		[listEntry changeHighlightStatus:(indexPath.row == self.currentlyHighlighted)
//								animated:NO];
		
		
		//Divider line for between the entries
		UIView *dividerView = [UIView newAutoLayoutView];
		dividerView.backgroundColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1.0];
		[listEntry addSubview:dividerView];
		
		[dividerView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
		[dividerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
		[dividerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-(flowLayout.sectionInset.bottom/2.0)];
		[dividerView autoSetDimension:ALDimensionHeight toSize:1.0];
	}

	return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView
		  viewForSupplementaryElementOfKind:(NSString *)kind
								atIndexPath:(NSIndexPath *)indexPath {
	
	NSString *reuseIdentifier = (indexPath.section == 0) ? @"previousTracksHeaderIdentifier" : @"nextTracksHeaderIdentifier";
	
	LMQueueViewHeader *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
	
	header.isForPreviousTracks = (indexPath.section == 0);
	header.delegate = self;
	
	header.backgroundColor = [LMColour superLightGreyColour];
	
	[header reload];
	
	return header;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	BOOL hideNoTracksLabel = !(self.musicQueue.count == 0);
	
	self.nothingInQueueTitleLabel.hidden = hideNoTracksLabel;
	self.nothingInQueueLabel.hidden = hideNoTracksLabel;
	
	self.collectionView.hidden = !hideNoTracksLabel;
	
	return (section == 0) ? (self.musicQueue.previousTracks.count + 1) : self.musicQueue.nextTracks.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(self.frame.size.width, LMLayoutManager.standardListEntryHeight);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
	BOOL isNowPlayingTrack = ([self trackForIndexPath:indexPath] == self.musicPlayer.nowPlayingTrack);
	
	return !isNowPlayingTrack;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSLog(@"Move item from %@ to %@", sourceIndexPath, destinationIndexPath);
	
	LMMusicTrack *track = [self trackForIndexPath:sourceIndexPath];
	
	NSInteger previousIndex
		= [self.musicQueue indexOfTrackInCompleteQueueFromPreviousTracks:(sourceIndexPath.section == 0)
												   withIndexInSubQueueOf:sourceIndexPath.row];
	
	NSInteger newIndex
		= [self.musicQueue indexOfTrackInCompleteQueueFromPreviousTracks:(destinationIndexPath.section == 0)
												   withIndexInSubQueueOf:destinationIndexPath.row];
	
	NSLog(@"Moving track from complete index %d to new complete index %d", (int)previousIndex, (int)newIndex);
	
	[self.musicQueue moveTrackFromIndex:previousIndex toIndex:newIndex];
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer*)longPressGesture {
	NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPressGesture locationInView:self.collectionView]];
	
	CGPoint movementPoint = [longPressGesture locationInView:self.collectionView];
	movementPoint.x = (self.collectionView.frame.size.width / 2.0);
	
	switch(longPressGesture.state){
		case UIGestureRecognizerStateBegan: {
			if(indexPath){
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
					if(self.currentlyMovingListEntry.alpha < 1.0){
						self.currentlyMovingListEntry.previousAlpha = self.currentlyMovingListEntry.alpha;
						
						[UIView animateWithDuration:0.3 animations:^{
							self.currentlyMovingListEntry.alpha = 1.0;
						}];
					}
				}
			}
			break;
		}
		case UIGestureRecognizerStateChanged: {
			[self.collectionView updateInteractiveMovementTargetPosition:movementPoint];
			break;
		}
		case UIGestureRecognizerStateEnded: {
			[self.collectionView endInteractiveMovement];
			
			if(self.currentlyMovingListEntry){
				if(self.currentlyMovingListEntry.previousAlpha > 0.0){
					[UIView animateWithDuration:0.3 animations:^{
						self.currentlyMovingListEntry.alpha = self.currentlyMovingListEntry.previousAlpha;
					}];
					
					self.currentlyMovingListEntry.previousAlpha = 0.0;
				}
				
				self.currentlyMovingListEntry = nil;
			}
			break;
		}
		default: {
			[self.collectionView cancelInteractiveMovement];
			
			self.currentlyMovingListEntry = nil;
			break;
		}
	}
}



- (void)queueBegan {
	[self.collectionView reloadData];
	
	NSLog(@"Queue began.");
}

- (void)queueEnded {
	[self.collectionView reloadData];
	
	NSLog(@"Queue ended.");
}

- (void)trackMovedInQueue:(LMMusicTrack * _Nonnull)trackMoved {
	NSLog(@"%@ moved apparently, time to reload", trackMoved.title);
	
//	[self.collectionView performBatchUpdates:^{
		[self.collectionView reloadData];
//	} completion:^(BOOL finished) {
//		NSLog(@"Done batch updates.");
//	}];
}


- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	[self.collectionView reloadData];
}

- (void)trackAddedToFavourites:(LMMusicTrack*)track {
	[self.collectionView reloadData];
}

- (void)trackRemovedFromFavourites:(LMMusicTrack*)track {
	[self.collectionView reloadData];
}


- (void)resetContentOffsetToNowPlaying {
	NSLog(@"Reset content offset");
	
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.musicQueue.previousTracks.count inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
	
	self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y - LMLayoutManager.standardListEntryHeight - 20);
}


- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor blueColor];
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		
		self.musicQueue = [LMMusicQueue sharedMusicQueue];
		[self.musicQueue addDelegate:self];
		
#warning Todo: add theme delegate support
		
		self.backgroundColor = [LMColour whiteColour];
		
		
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 0, 10, 0);
		fuck.headerReferenceSize = CGSizeMake(WINDOW_FRAME.size.width, LMLayoutManager.standardListEntryHeight);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
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
	}
}

@end
