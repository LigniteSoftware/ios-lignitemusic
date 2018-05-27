//
//  LMQueueView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMQueueViewHeader.h"
#import "LMMusicQueue.h"
#import "LMListEntry.h"
#import "LMQueueView.h"
#import "LMColour.h"

@interface LMQueueView()<UICollectionViewDelegate, UICollectionViewDataSource, LMMusicQueueDelegate, LMListEntryDelegate, LMQueueViewHeaderDelegate>

/**
 The collection view which displays the queue.
 */
@property UICollectionView *collectionView;

/**
 The music queue.
 */
@property LMMusicQueue *musicQueue;

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

@end

@implementation LMQueueView

- (UIImage*)iconForHeader:(LMQueueViewHeader*)header {
	return [LMAppIcon imageForIcon:header.isForPreviousTracks ? LMIconPreviousTracks : LMIconNextTracks];
}

- (NSString*)titleForHeader:(LMQueueViewHeader*)header {
	if(header.isForPreviousTracks){
		BOOL singular = (self.musicQueue.previousTracks.count == 1);
		
		NSString *title = NSLocalizedString(singular ? @"PreviousTracksTitleSingular" : @"PreviousTracksTitlePlural", nil);
		
		return title;
	}
	return NSLocalizedString(@"UpNextTitle", nil);
}

- (NSString*)subtitleForHeader:(LMQueueViewHeader*)header {
	NSInteger trackCount = header.isForPreviousTracks ? self.musicQueue.previousTracks.count : self.musicQueue.nextTracks.count;
	
	BOOL singular = (trackCount == 1);
	
	NSString *trackCountString = [NSString stringWithFormat:NSLocalizedString(singular ? @"XSongsSingle" : @"XSongs", nil), trackCount];
	
	return trackCountString;
}


- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %@", entry);
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [UIColor redColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	return [NSString stringWithFormat:@"%d/%d", entry.indexPath.section, entry.indexPath.row];
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	return @"Subtitle";
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [LMColour randomColour];
	
	
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
			
//			[listEntry changeHighlightStatus:(self.currentlyHighlighted == listEntry.collectionIndex) animated:NO];
			[listEntry reloadContents];
		}
	}
	else {
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.indexPath = indexPath;
		listEntry.associatedData = nil;
#warning fix this ^
		listEntry.isLabelBased = NO;
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = NO;
		
		
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
	
	LMQueueViewHeader *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
																				 withReuseIdentifier:@"test" forIndexPath:indexPath];
	
	header.isForPreviousTracks = (indexPath.section == 0);
	header.delegate = self;
	
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
	
	return (section == 0) ? self.musicQueue.previousTracks.count : self.musicQueue.nextTracks.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(self.frame.size.width, LMLayoutManager.standardListEntryHeight);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSLog(@"Move item from %@ to %@", sourceIndexPath, destinationIndexPath);
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer*)longPressGesture {
	NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPressGesture locationInView:self.collectionView]];
	
	switch(longPressGesture.state){
		case UIGestureRecognizerStateBegan: {
			[UIView animateWithDuration:0.3 animations:^{
				if(indexPath){
					[self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
				}
				else{
					NSLog(@"IndexPath couldn't be found, sorry!");
				}
			}];
			break;
		}
		case UIGestureRecognizerStateChanged: {
			CGPoint movementPoint = [longPressGesture locationInView:self.collectionView];
			movementPoint.x = (self.collectionView.frame.size.width / 2.0);
			[self.collectionView updateInteractiveMovementTargetPosition:movementPoint];
			break;
		}
		case UIGestureRecognizerStateEnded: {
			[self.collectionView endInteractiveMovement];
			break;
		}
		default: {
			[self.collectionView cancelInteractiveMovement];
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

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.musicQueue = [LMMusicQueue sharedMusicQueue];
		[self.musicQueue addDelegate:self];
		
		self.backgroundColor = [LMColour orangeColor];
		
		
		
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
					   withReuseIdentifier:@"test"];
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
