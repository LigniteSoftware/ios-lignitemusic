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
#import "LMApplication.h"

@interface LMDetailView()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate, LMMusicPlayerDelegate, LMMusicCollectionsViewDelegate, UIScrollViewDelegate, LMLayoutChangeDelegate>

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
 The last point in scrolling where the user stopped scrolling.
 */
@property CGPoint lastScrollingOffsetPoint;

/**
 Whether or not the scrolling that the user did broke the treshhold for minimizing the bottom button bar.
 */
@property BOOL brokeScrollingThreshhold;

@end

@implementation LMDetailView

@synthesize musicTrackCollection = _musicTrackCollection;
@synthesize musicTrackCollectionToUseForSpecificTrackCollection = _musicTrackCollectionToUseForSpecificTrackCollection;

- (LMCoreViewController*)rootViewController {
	LMApplication *application = (LMApplication*)[UIApplication sharedApplication];
	return application.coreViewController;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	self.rootViewController.buttonNavigationBar.currentlyScrolling = YES;

	CGFloat difference = fabs(scrollView.contentOffset.y-self.lastScrollingOffsetPoint.y);

	CGFloat maxContentOffset = scrollView.contentSize.height - (scrollView.frame.size.height*1.5);
	if(scrollView.contentOffset.y > maxContentOffset){
		return; //Don't scroll at the end to prevent weird scrolling behaviour with resize of required button bar height
	}

	if(difference > WINDOW_FRAME.size.height/10){
		self.brokeScrollingThreshhold = YES;
		if(!self.rootViewController.buttonNavigationBar.userMaximizedDuringScrollDeceleration){
			[self.rootViewController.buttonNavigationBar minimize:YES];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(self.brokeScrollingThreshhold){
		//[self.rootViewController.buttonNavigationBar minimize];
	}
	self.brokeScrollingThreshhold = NO;
	self.lastScrollingOffsetPoint = scrollView.contentOffset;
	
	NSLog(@"Finished dragging");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSLog(@"Ended decelerating");
	
	self.rootViewController.buttonNavigationBar.currentlyScrolling = NO;
	self.rootViewController.buttonNavigationBar.userMaximizedDuringScrollDeceleration = NO;
}

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

- (LMMusicTrackCollection*)musicTrackCollectionToUseForSpecificTrackCollection {
	if(_musicTrackCollectionToUseForSpecificTrackCollection){
		return _musicTrackCollectionToUseForSpecificTrackCollection;
	}
	
	return _musicTrackCollection;
}

- (void)setMusicTrackCollectionToUseForSpecificTrackCollection:(LMMusicTrackCollection *)musicTrackCollectionToUse {
	_musicTrackCollectionToUseForSpecificTrackCollection = musicTrackCollectionToUse;
	
	[self.collectionView reloadData];
	[self.collectionView.collectionViewLayout invalidateLayout];
	
	[self setShowingSpecificTrackCollection:YES animated:YES];
}

- (void)musicCollectionTappedAtIndex:(NSInteger)index forMusicCollectionsView:(LMMusicCollectionsView *)collectionsView {
	self.musicTrackCollectionToUseForSpecificTrackCollection = [self.specificTrackCollections objectAtIndex:index];
}

+ (NSInteger)numberOfColumns {
	return fmax(1.0, ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/300.0f);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.musicTrackCollectionToUseForSpecificTrackCollection.trackCount; i++){
		LMMusicTrack *track = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:i];
		
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

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	[self.collectionView reloadData];
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	[self.collectionView reloadData];
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
	LMMusicTrack *track = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:entry.collectionIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlightedEntry];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlightedEntry = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTrackCollectionToUseForSpecificTrackCollection){
		[self.musicPlayer stop];

		[self.musicPlayer setNowPlayingCollection:self.musicTrackCollectionToUseForSpecificTrackCollection];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour mainColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:entry.collectionIndex];
	return musicTrack.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:entry.collectionIndex];
	return musicTrack.artist;
}

- (NSString*)textForListEntry:(LMListEntry *)entry {
	return [NSString stringWithFormat:@"%ld", (entry.collectionIndex + 1)];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	//	if(self.specificTrackCollections){
	//		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
	//		return [collection.representativeItem albumArt];
	//	}
	LMMusicTrack *track = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:entry.collectionIndex];
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
	
	cell.backgroundColor = [LMColour superLightGreyColour];
	
	//	for(UIView *subview in cell.contentView.subviews){
	//		[subview removeFromSuperview];
	//	}
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	NSInteger indexAdjustedForShuffleButton = indexPath.row;
//	BOOL isShuffleButton = (indexPath.row == 0);
	
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:indexAdjustedForShuffleButton];
	
	if(cell.contentView.subviews.count > 0){
		LMListEntry *listEntry = nil;
		for(UIView *subview in cell.contentView.subviews){
			if([subview class] == [LMListEntry class]) {
				listEntry = (LMListEntry*)subview;
				break;
			}
		}
		
		if(listEntry){
			listEntry.collectionIndex = indexAdjustedForShuffleButton;
			
			listEntry.leftButtonExpansionColour = track.isFavourite ? [LMColour mainColour] : [LMColour successGreenColour];
			
			[[listEntry.leftButtons firstObject] setImage:track.isFavourite ? [LMAppIcon imageForIcon:LMIconUnfavouriteWhite] : [LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled] forState:UIControlStateNormal];
			
			[listEntry changeHighlightStatus:(self.currentlyHighlightedEntry == listEntry.collectionIndex) animated:NO];
			[listEntry reloadContents];
		}
	}
	else {
//		NSInteger fixedIndex = indexPath.row; // (indexPath.row/[LMExpandableTrackListView numberOfColumns]) + ((indexPath.row % [LMExpandableTrackListView numberOfColumns])*([self collectionView:self.collectionView numberOfItemsInSection:0]/[LMExpandableTrackListView numberOfColumns]));
		
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = indexAdjustedForShuffleButton;
		listEntry.associatedData = [self.musicTrackCollectionToUseForSpecificTrackCollection.items objectAtIndex:indexAdjustedForShuffleButton];
		listEntry.isLabelBased = (self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations);
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = YES;
		
		
		UIColor *colour = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
		UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
		MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@"" icon:[LMAppIcon imageForIcon:LMIconAddToQueue] backgroundColor:colour padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
			LMMusicTrack *trackToQueue = [self.musicTrackCollection.items objectAtIndex:listEntry.collectionIndex];
			
			[self.musicPlayer addTrackToQueue:trackToQueue];
			
			NSLog(@"Queue %@", trackToQueue.title);
			
			return YES;
		}];
		saveButton.titleLabel.font = font;
		saveButton.titleLabel.hidden = YES;
		saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
		saveButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
		
		listEntry.rightButtons = @[ saveButton ];
		
		MGSwipeButton *favouriteButton = [MGSwipeButton buttonWithTitle:@"" icon:track.isFavourite ? [LMAppIcon imageForIcon:LMIconUnfavouriteWhite] : [LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled] backgroundColor:colour padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
			LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:listEntry.collectionIndex];
			
			if(track.isFavourite){
				[self.musicPlayer removeTrackFromFavourites:track];
			}
			else{
				[self.musicPlayer addTrackToFavourites:track];
			}
			
			NSLog(@"Favourite %@", track.title);
			
			return YES;
		}];
		favouriteButton.titleLabel.font = font;
		favouriteButton.titleLabel.hidden = YES;
		favouriteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
		favouriteButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
		
		listEntry.leftButtons = @[ favouriteButton ];
		listEntry.leftButtonExpansionColour = track.isFavourite ? [LMColour mainColour] : [LMColour successGreenColour];

		
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour superLightGreyColour];
		
		[listEntry autoPinEdgesToSuperviewEdges];
			
		[listEntry changeHighlightStatus:(indexAdjustedForShuffleButton == self.currentlyHighlightedEntry) animated:NO];
		
		
//		BOOL isInLastRow = indexPath.row >= (self.musicTrackCollectionToUseForSpecificTrackCollection.count - [LMDetailView numberOfColumns]);
		
//		if(!isInLastRow){
			UIView *dividerView = [UIView newAutoLayoutView];
			dividerView.backgroundColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1.0];
			[listEntry addSubview:dividerView];
			
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//			[dividerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:listEntry withMultiplier:1.0];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-(flowLayout.sectionInset.bottom/2.0)];
			[dividerView autoSetDimension:ALDimensionHeight toSize:1.0];
//		}
//		else{
//			NSLog(@"Fuck %@", indexPath);
//			NSLog(@"shit");
//		}
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.musicTrackCollectionToUseForSpecificTrackCollection.count;
}

- (CGSize)currentItemSize {
//	NSLog(@"Number of columns %d", (int)[LMDetailView numberOfColumns]);
	return CGSizeMake(self.frame.size.width/[LMDetailView numberOfColumns]*0.90,
					  fmin(LMLayoutManager.standardListEntryHeight, 80));
}

//Of the detail view if it was based on amount of tracks and not available screen space
- (CGSize)totalSize {
	CGSize size = CGSizeMake(WINDOW_FRAME.size.width, 0);
	
	CGSize normalItemSize;
	NSInteger numberOfColumns = 0, amountOfItems = 0;
	CGFloat spacing = 0;
	
	if(self.showingAlbumTileView){
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
		
		amountOfItems = self.musicTrackCollectionToUseForSpecificTrackCollection.count;
		
		if(numberOfColumns > amountOfItems){
			numberOfColumns = amountOfItems;
		}
		
		size.height += (amountOfItems * 10)/numberOfColumns; //Spacing
		size.height += 10;
		if(amountOfItems < 3){
			size.height += (((amountOfItems == 1) ? 2 : 1) * normalItemSize.height); //Adjustment to make sure floating buttons fit
		}
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
	
//	NSLog(@"Returning %@\ncollection view size %@\nsuperframe %@\nalbum tile view frame %@\nself frame %@", NSStringFromCGSize(itemSize), NSStringFromCGRect(self.collectionView.frame), NSStringFromCGRect(self.collectionView.superview.superview.frame), NSStringFromCGRect(self.albumTileView.frame), NSStringFromCGRect(self.frame));
	
//	NSLog(@"Content inset %@\nsection inset %@", NSStringFromUIEdgeInsets(self.collectionView.contentInset), NSStringFromUIEdgeInsets(flowLayout.sectionInset));
	
	return itemSize;
}

- (void)rootViewWillTransitionToSize:(CGSize)size
		   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(self.specificTrackCollections && self.albumTileView.hidden){
			self.albumTileViewLeadingConstraint.constant = -self.frame.size.width;
		}
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Nothing, yet
		if(self.specificTrackCollections && self.albumTileView.hidden){
			self.albumTileViewLeadingConstraint.constant = -self.frame.size.width;
		}
	}];
}


- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		
		[[LMLayoutManager sharedLayoutManager] addDelegate:self];
		
		
		//Album tile view is created in init
		self.albumTileView.flowLayout = self.flowLayout;
		self.albumTileView.backgroundColor = [UIColor purpleColor];
		self.albumTileView.adjustForFloatingControls = self.adjustForFloatingControls;
		[self addSubview:self.albumTileView];
		
		self.albumTileViewLeadingConstraint = [self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.albumTileView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.albumTileView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:self.adjustForFloatingControls ? -53.0 : 0];
	
				
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
		self.collectionView.backgroundColor = [LMColour superLightGreyColour];
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.collectionView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumTileView withOffset:self.adjustForFloatingControls ? 53.0f : 0];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.collectionView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
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
			self.specificTrackCollections = [self.musicPlayer collectionsForRepresentativeTrack:self.musicTrackCollection.representativeItem forMusicType:self.musicType];
		}
		
		
		self.albumTileView = [LMMusicCollectionsView newAutoLayoutView];
		self.albumTileView.backgroundColor = [UIColor purpleColor];
		self.albumTileView.trackCollections = self.specificTrackCollections;
		self.albumTileView.delegate = self;
		
		[self rootViewController].buttonNavigationBar.userMaximizedDuringScrollDeceleration = NO;
	}
	return self;
}

@end
