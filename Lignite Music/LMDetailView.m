//
//  LMDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/27/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "MBProgressHUD.h"
#import "LMDetailView.h"
#import "LMMusicCollectionsView.h"

@interface LMDetailView()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate, LMMusicPlayerDelegate, LMMusicCollectionsViewDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The currently highlighted entry.
 */
@property NSInteger currentlyHighlightedEntry;

/**
 The specific track collections associated with this browsing view. For example, an artist would have their albums within this array of collections.
 */
@property NSArray<LMMusicTrackCollection*>* specificTrackCollections;

/**
 The tile view of albums used for displaying specific track collections.
 */
@property LMMusicCollectionsView *albumTileView;

/**
 The top constraint for the collection view. Its constant should be the frame's height if displaying the track list.
 */
@property NSLayoutConstraint *albumTileViewLeadingConstraint;

/**
 The music track collection to use in loading data, as a specific track collection may have been set.
 */
@property LMMusicTrackCollection *musicTrackCollectionToUse;

@end

@implementation LMDetailView

@synthesize musicTrackCollection = _musicTrackCollection;
@synthesize musicTrackCollectionToUse = _musicTrackCollectionToUse;

- (BOOL)showingAlbumTileView {
	return self.albumTileViewLeadingConstraint.constant == 0; //The specific track collections have been prepped but the actual view just hasn't been lain out yet
}

- (void)setShowingSpecificTrackCollection:(BOOL)showingSpecificTrackCollection animated:(BOOL)animated {
	LMCollectionViewFlowLayout *flowLayout = self.flowLayout;
	
	CGFloat animationTime = animated ? 0.25 : 0;
	
	self.albumTileView.hidden = NO;
	
	if([self.delegate respondsToSelector:@selector(detailViewIsShowingAlbumTileView:)]){
		[self.delegate detailViewIsShowingAlbumTileView:!showingSpecificTrackCollection];
	}
	
	self.albumTileViewLeadingConstraint.constant = showingSpecificTrackCollection ? -self.frame.size.width : 0;
	[UIView animateWithDuration:animationTime animations:^{
		[flowLayout.collectionView performBatchUpdates:nil completion:nil];
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		self.albumTileView.hidden = showingSpecificTrackCollection;
	}];
}

- (LMMusicTrackCollection*)musicTrackCollectionToUse {
	if(_musicTrackCollectionToUse){
		return _musicTrackCollectionToUse;
	}
	
	return _musicTrackCollection;
}

- (void)setMusicTrackCollectionToUse:(LMMusicTrackCollection *)musicTrackCollectionToUse {
	_musicTrackCollectionToUse = musicTrackCollectionToUse;
	
	[self.collectionView reloadData];
	[self.collectionView.collectionViewLayout invalidateLayout];
	
	[self setShowingSpecificTrackCollection:YES animated:YES];
}

- (void)musicCollectionTappedAtIndex:(NSInteger)index forMusicCollectionsView:(LMMusicCollectionsView *)collectionsView {
	self.musicTrackCollectionToUse = [self.specificTrackCollections objectAtIndex:index];
}

+ (NSInteger)numberOfColumns {
	return fmax(1.0, ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/300.0f);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.musicTrackCollectionToUse.trackCount; i++){
		LMMusicTrack *track = [self.musicTrackCollectionToUse.items objectAtIndex:i];
		
		if(track.persistentID == newTrack.persistentID){
			newHighlightedIndex = i;
		}
	}
	
	highlightedEntry = [self listEntryForIndex:newHighlightedIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlightedEntry];
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		BOOL updateNowPlayingStatus = self.currentlyHighlightedEntry == -1;
		self.currentlyHighlightedEntry = newHighlightedIndex;
		if(updateNowPlayingStatus){
			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
		}
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	for(id subview in cell.contentView.subviews){
		if([subview class] == [LMListEntry class]){
			return subview;
		}
	}
	return nil;
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %d", (int)entry.collectionIndex);
	
	LMMusicTrack *track = [self.musicTrackCollectionToUse.items objectAtIndex:entry.collectionIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlightedEntry];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlightedEntry = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTrackCollectionToUse){
#ifdef SPOTIFY
		[self.musicPlayer pause];
#else
		[self.musicPlayer stop];
#endif
		[self.musicPlayer setNowPlayingCollection:self.musicTrackCollectionToUse];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollectionToUse.items objectAtIndex:entry.collectionIndex];
	return musicTrack.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollectionToUse.items objectAtIndex:entry.collectionIndex];
	return musicTrack.artist;
}

- (NSString*)textForListEntry:(LMListEntry *)entry {
	return [NSString stringWithFormat:@"%d", (entry.collectionIndex + 1)];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	//	if(self.specificTrackCollections){
	//		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
	//		return [collection.representativeItem albumArt];
	//	}
	LMMusicTrack *track = [self.musicTrackCollectionToUse.items objectAtIndex:entry.collectionIndex];
	return [track albumArt];
}

- (LMMusicTrackCollection*)musicTrackCollection {
	return _musicTrackCollection;
}

- (void)setMusicTrackCollection:(LMMusicTrackCollection *)musicTrackCollection {
	_musicTrackCollection = musicTrackCollection;
	
	[self.collectionView reloadData];
	[self.collectionView.collectionViewLayout invalidateLayout];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [LMColour superLightGrayColour];
	
	//	for(UIView *subview in cell.contentView.subviews){
	//		[subview removeFromSuperview];
	//	}
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	if(cell.contentView.subviews.count > 0){
		LMListEntry *listEntry = nil;
		for(UIView *subview in cell.contentView.subviews){
			if([subview class] == [LMListEntry class]) {
				listEntry = (LMListEntry*)subview;
				break;
			}
		}
		
		if(listEntry){
			listEntry.collectionIndex = indexPath.row;
			[listEntry changeHighlightStatus:self.currentlyHighlightedEntry == listEntry.collectionIndex animated:NO];
			[listEntry reloadContents];
		}
	}
	else {
		NSInteger fixedIndex = indexPath.row; // (indexPath.row/[LMExpandableTrackListView numberOfColumns]) + ((indexPath.row % [LMExpandableTrackListView numberOfColumns])*([self collectionView:self.collectionView numberOfItemsInSection:0]/[LMExpandableTrackListView numberOfColumns]));
		
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = fixedIndex;
		listEntry.associatedData = [self.musicTrackCollectionToUse.items objectAtIndex:fixedIndex];
		listEntry.isLabelBased = (self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations);
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = YES;
		
		
		UIColor *color = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
		UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
		MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@"Queue" backgroundColor:color padding:15 callback:^BOOL(MGSwipeTableCell *sender) {
			LMMusicTrack *trackToQueue = [self.musicTrackCollection.items objectAtIndex:listEntry.collectionIndex];
			
			[self.musicPlayer addTrackToQueue:trackToQueue];
			
			NSLog(@"Queue %@", trackToQueue.title);
			
			return YES;
		}];
		saveButton.titleLabel.font = font;
		
		listEntry.rightButtons = @[ saveButton ];
		
		
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour superLightGrayColour];
		
		[listEntry autoPinEdgesToSuperviewEdges];
		
		[listEntry changeHighlightStatus:fixedIndex == self.currentlyHighlightedEntry animated:NO];
		
		
		BOOL isInLastRow = indexPath.row >= (self.musicTrackCollectionToUse.count-[LMDetailView numberOfColumns]);
		
		if(!isInLastRow){
			UIView *dividerView = [UIView newAutoLayoutView];
			dividerView.backgroundColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1.0];
			[listEntry addSubview:dividerView];
			
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-(flowLayout.sectionInset.bottom/2.0)];
			[dividerView autoSetDimension:ALDimensionHeight toSize:1.0];
		}
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.musicTrackCollectionToUse.count;
}

- (CGSize)currentItemSize {
	NSLog(@"Number of columns %d", (int)[LMDetailView numberOfColumns]);
	return CGSizeMake(self.frame.size.width/[LMDetailView numberOfColumns]*0.90,
					  fmin(([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/8.0, 80));
}

- (CGSize)totalSize {
	CGSize size = CGSizeMake(WINDOW_FRAME.size.width, 0);
	
	CGSize normalItemSize;
	NSInteger numberOfColumns = 0, amountOfItems = 0;
	CGFloat spacing = 0;
	BOOL fuck = YES;
	
	if(self.showingAlbumTileView){
		fuck = NO;
		
		self.albumTileView.flowLayout = self.flowLayout;
		
		numberOfColumns = [LMLayoutManager amountOfCollectionViewItemsPerRow];
		
		normalItemSize = [self.albumTileView normalItemSize];
		
		amountOfItems = self.specificTrackCollections.count;
		
		spacing = [self.albumTileView spacing];
		
		if(numberOfColumns > amountOfItems){
			numberOfColumns = amountOfItems;
		}
		
		size.height += (amountOfItems * spacing)/numberOfColumns; //Spacing
		size.height += spacing;
	}
	else{
		numberOfColumns = [LMDetailView numberOfColumns];
		
		normalItemSize = [self currentItemSize];
		
		amountOfItems = self.musicTrackCollectionToUse.count;
		
		if(numberOfColumns > amountOfItems){
			numberOfColumns = amountOfItems;
		}
		
		size.height += (amountOfItems * 10)/numberOfColumns; //Spacing
		size.height += 10;
	}
	
	
//	NSLog(@"Initial %d spacing %f", (int)size.height, spacing);
	
	size.height += (amountOfItems * normalItemSize.height)/numberOfColumns;
//	NSLog(@"Adding amount now %d", (int)size.height);
	
	if(numberOfColumns % 2 == 0 && amountOfItems % 2 != 0 && amountOfItems > numberOfColumns){ //If the number of columns is even but the amount of actual items is uneven
		size.height += normalItemSize.height;
//		NSLog(@"Adding spacer because uneven now %d", (int)size.height);
	}
	
//	NSLog(@"Total size %@", NSStringFromCGSize(size));
	
	return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	CGSize itemSize = [self currentItemSize];
	
	CGFloat contentInsets = flowLayout.sectionInset.right + flowLayout.sectionInset.left;
	
	if(itemSize.width > (self.collectionView.frame.size.width-contentInsets)){
		return CGSizeMake(0, 0);
	}
	
	NSLog(@"Returning %@\ncollection view size %@\nsuperframe %@\nalbum tile view frame %@\nself frame %@", NSStringFromCGSize(itemSize), NSStringFromCGRect(self.collectionView.frame), NSStringFromCGRect(self.collectionView.superview.superview.frame), NSStringFromCGRect(self.albumTileView.frame), NSStringFromCGRect(self.frame));
	
	NSLog(@"Content inset %@\nsection inset %@", NSStringFromUIEdgeInsets(self.collectionView.contentInset), NSStringFromUIEdgeInsets(flowLayout.sectionInset));
	
	return itemSize;
}


- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		
		//Album tile view is created in init
		self.albumTileView.flowLayout = self.flowLayout;
		self.albumTileView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.albumTileView];
		
		self.albumTileViewLeadingConstraint = [self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.albumTileView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	
				
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
		self.collectionView.backgroundColor = [LMColour superLightGrayColour];
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.collectionView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumTileView];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.collectionView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumTileView];
		//		self.collectionView.hidden = YES;
		
		[self.musicPlayer addMusicDelegate:self];
		
		
		NSLog(@"Album tile view %p, collection view %p, flow layout %p", self.albumTileView.collectionView, self.collectionView, self.flowLayout);
	}
	else{
		[self.collectionView reloadData];
		[self.collectionView.collectionViewLayout invalidateLayout];
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
	
	if(!self.specificTrackCollections){
		self.albumTileViewLeadingConstraint.constant = -self.frame.size.width;
		self.albumTileView.hidden = YES;
	}
	
	[super layoutSubviews];
}

- (instancetype)initWithMusicTrackCollection:(LMMusicTrackCollection*)musicTrackCollection musicType:(LMMusicType)musicType {
	self = [super initForAutoLayout];
	if(self){
		self.musicTrackCollection = musicTrackCollection;
		self.musicType = musicType;
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.currentlyHighlightedEntry = -1;
		
		
		
		BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
											  && self.musicType != LMMusicTypeCompilations
											  && self.musicType != LMMusicTypeAlbums);
		
		if(usingSpecificTrackCollections){
			self.specificTrackCollections = [self.musicPlayer collectionsForRepresentativeTrack:self.musicTrackCollection.representativeItem
																				   forMusicType:self.musicType];
		}
		
		
		self.albumTileView = [LMMusicCollectionsView newAutoLayoutView];
		self.albumTileView.backgroundColor = [UIColor purpleColor];
		self.albumTileView.trackCollections = self.specificTrackCollections;
		self.albumTileView.delegate = self;
	}
	return self;
}

@end
