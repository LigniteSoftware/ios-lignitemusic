//
//  LMTitleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "MBProgressHUD.h"
#import "LMFloatingDetailViewButton.h"
#import "LMCoreViewController.h"
#import "LMLayoutManager.h"
#import "LMTitleView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMOperationQueue.h"
#import "LMMusicPlayer.h"
#import "LMExtras.h"
#import "LMThemeEngine.h"
#import "NSTimer+Blocks.h"
#import "LMSettings.h"

#define LMTitleViewTopTrackPersistentIDKey @"LMTitleViewTopTrackPersistentIDKey"

@interface LMTitleView() <LMListEntryDelegate, LMMusicPlayerDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate, LMFloatingDetailViewButtonDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property LMMusicPlayer *musicPlayer;

@property NSMutableArray *itemArray;
//@property NSMutableArray *itemIconArray;
//^ just retarded dude lol

@property LMOperationQueue *queue;


/**
 The last point in scrolling where the user stopped scrolling.
 */
@property CGPoint lastScrollingOffsetPoint;

/**
 Whether or not the scrolling that the user did broke the treshhold for minimizing the bottom button bar.
 */
@property BOOL brokeScrollingThreshhold;

@property LMLayoutManager *layoutManager;

@property LMMusicTrackCollection *allSongsTrackCollection;

@property LMMusicTrackCollection *favouritesTrackCollection;

@property UILabel *noObjectsLabel;

@property BOOL didJustScrollByLetter;

@property MBProgressHUD *loadingProgressHUD;

/**
 The shuffle button.
 */
@property LMFloatingDetailViewButton *shuffleButton;

/**
 The trailing constraint of the shuffle button, used for offsetting in landscape because of the button navigation bar.
 */
@property NSLayoutConstraint *shuffleButtonTrailingConstraint;

@end

@implementation LMTitleView

@synthesize musicTitles = _musicTitles;
@synthesize shuffleButtonLandscapeOffset = _shuffleButtonLandscapeOffset;

- (LMCoreViewController*)rootViewController {
	return (LMCoreViewController*)self.rawViewController;
}

- (void)setShuffleButtonLandscapeOffset:(CGFloat)shuffleButtonLandscapeOffset {
	_shuffleButtonLandscapeOffset = shuffleButtonLandscapeOffset;
	
	[self layoutIfNeeded];
	
	self.shuffleButtonTrailingConstraint.constant = -shuffleButtonLandscapeOffset;
	
	[UIView animateWithDuration:0.2 animations:^{
		[self layoutIfNeeded];
	}];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [LMColour purpleColor];

	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	NSLog(@"Reloading cell for index %d, currently highlighted is %d", (int)indexPath.row, (int)self.currentlyHighlighted);
	
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
			
			[listEntry setAsHighlighted:(self.currentlyHighlighted == listEntry.collectionIndex) animated:NO];
			[listEntry reloadContents];
		}
	}
	else {
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = indexPath.row;
		listEntry.associatedData = [self.musicTitles.items objectAtIndex:indexPath.row];
		listEntry.isLabelBased = NO;
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = NO;
		
		
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour whiteColour];
		
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 0 : 0];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:([LMLayoutManager isiPhoneX] && [LMLayoutManager isLandscape]) ? 44 : 0];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[listEntry autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		[listEntry setAsHighlighted:(indexPath.row == self.currentlyHighlighted)
								animated:NO];
		
		
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.musicTitles.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(self.frame.size.width, LMLayoutManager.standardListEntryHeight);
}

- (CGFloat)shuffleButtonLandscapeOffset {
	return _shuffleButtonLandscapeOffset;
}

- (LMMusicTrackCollection*)musicTitles {
	if(self.favourites){
		return self.favouritesTrackCollection;
	}
	return self.allSongsTrackCollection;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if(self.didJustScrollByLetter){
		self.didJustScrollByLetter = NO;
		return;
	}
	
	self.rootViewController.buttonNavigationBar.currentlyScrolling = YES;
	
    CGFloat difference = fabs(scrollView.contentOffset.y-self.lastScrollingOffsetPoint.y);
	
	CGFloat maxContentOffset = scrollView.contentSize.height - (scrollView.frame.size.height*1.5);
	if(scrollView.contentOffset.y > maxContentOffset){
		return; //Don't scroll at the end to prevent weird scrolling behaviour with resize of required button bar height
	}
	
    if(difference > WINDOW_FRAME.size.height/4){
        self.brokeScrollingThreshhold = YES;
		if(!self.rootViewController.buttonNavigationBar.userMaximizedDuringScrollDeceleration){
			[self.rootViewController.buttonNavigationBar minimise:YES];
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

- (void)reloadCurrentlyHighlightedTrack {
	if([self.musicTitles.items containsObject:self.musicPlayer.nowPlayingTrack]){
		NSInteger indexOfNewTrack = [self.musicTitles.items indexOfObject:self.musicPlayer.nowPlayingTrack];
		[[self listEntryForIndex:self.currentlyHighlighted] setAsHighlighted:NO animated:YES];
		[[self listEntryForIndex:indexOfNewTrack] setAsHighlighted:YES animated:YES];
		
		self.currentlyHighlighted = indexOfNewTrack;
	}
	else{
		[[self listEntryForIndex:self.currentlyHighlighted] setAsHighlighted:NO animated:YES];
		self.currentlyHighlighted = -1;
	}
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
//	LMListEntry *highlightedEntry = nil;
//	int newHighlightedIndex = -1;
//	for(int i = 0; i < self.musicTitles.count; i++){
//		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:i];
//		LMListEntry *entry = [self listEntryForIndex:i];
//		LMMusicTrack *entryTrack = entry.associatedData;
//
//		if(entryTrack.persistentID == newTrack.persistentID){
//			highlightedEntry = entry;
//		}
//
//		if(track.persistentID == newTrack.persistentID){
//			newHighlightedIndex = i;
//		}
//	}
	
//	NSLog(@"New highlighted %d previous %ld", newHighlightedIndex, (long)self.currentlyHighlighted);
	
//	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
//	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
//		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		//BOOL updateNowPlayingStatus = self.currentlyHighlighted == -1;
//		self.currentlyHighlighted = newHighlightedIndex;
//		if(updateNowPlayingStatus){
//			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
//		}
//	}
//
//	if(highlightedEntry){
//		[highlightedEntry changeHighlightStatus:YES animated:YES];
//	}
	
	[self reloadCurrentlyHighlightedTrack];
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self setLoadingIndicatorDisplaying:NO];
	} repeats:NO];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self setLoadingIndicatorDisplaying:NO];
	} repeats:NO];
}

- (void)reloadFavourites {
	if(self.favourites){
		self.currentlyHighlighted = -1;
		
		[self rebuildTrackCollection];
		
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
	[self.collectionView reloadData];
}

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	[self reloadFavourites];
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	[self reloadFavourites];
}

- (void)rebuildTrackCollection {
	NSLog(@"Rebuilding title view track collection.");
	
	NSTimeInterval loadStartTime = [[NSDate new] timeIntervalSince1970];
	
	
	
	MPMediaQuery *everything = [MPMediaQuery new];
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic]
																					  forProperty:MPMediaItemPropertyMediaType
																				   comparisonType:MPMediaPredicateComparisonEqualTo];
	[everything addFilterPredicate:musicFilterPredicate];
	
	[self.musicPlayer applyDemoModeFilterIfApplicableToQuery:everything];
	
	NSMutableArray *musicCollection = [[NSMutableArray alloc]initWithArray:[everything items]];
	
	NSString *sortKey = @"title";
	NSSortDescriptor *albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
	musicCollection = [NSMutableArray arrayWithArray:[musicCollection sortedArrayUsingDescriptors:@[albumSort]]];
	
	self.allSongsTrackCollection = [MPMediaItemCollection collectionWithItems:[NSArray arrayWithArray:musicCollection]];
	
	self.favouritesTrackCollection = [self.musicPlayer favouritesTrackCollection];
	
	[self.collectionView reloadData];
	
	self.noObjectsLabel.hidden = (self.musicTitles.count > 0);
	self.noObjectsLabel.text = NSLocalizedString(self.favourites ? @"NoTracksInFavourites" : @"TheresNothingHere", nil);
	
	self.shuffleButton.hidden = !self.noObjectsLabel.hidden;
	
	[self reloadCurrentlyHighlightedTrack];
	
	NSTimeInterval loadEndTime = [[NSDate new] timeIntervalSince1970];
	
	NSLog(@"Fuck, %f seconds to rebuild the title view track collection.", (loadEndTime - loadStartTime));
}

- (void)scrollToTrackIndex:(NSUInteger)index {
	if(index >= self.musicTitles.count){
		return;
	}
	
	self.didJustScrollByLetter = YES;

#warning scroll to track index bro
	
//	[self.songListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
//								  atScrollPosition:UITableViewScrollPositionTop
//										  animated:NO];
	
	for(LMListEntry *listEntry in self.itemArray){
		[listEntry reloadContents];
	}
}

- (NSInteger)scrollToTrackWithPersistentID:(LMMusicTrackPersistentID)persistentID {
	NSInteger index = -1;
	
	for(NSUInteger i = 0; i < self.musicTitles.count; i++){
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:i];
		
		if(persistentID == track.persistentID){
			index = i;
		}
		
		if(index != -1){
			break;
		}
	}
	
	if(index == -1){
		index = 0;
	}
	
	//Fix index for adjustment
	NSInteger properIndex = index;
	index = (index == 0) ? 0 : (index-2);
	
	if(index > -1){
		[self scrollToTrackIndex:index];
	}
	
	return properIndex;
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
	[self setLoadingIndicatorDisplaying:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
		
		//	NSLog(@"Tapped list entry with artist %@", self.albumCollection.representativeItem.artist);
		
		LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
		if(previousHighlightedEntry){
			[previousHighlightedEntry setAsHighlighted:NO animated:YES];
		}
		
		NSLog(@"Highlighting %d, dehighlighting %d", (int)entry.collectionIndex, (int)previousHighlightedEntry.collectionIndex);
		
		[entry setAsHighlighted:YES animated:YES];
		self.currentlyHighlighted = entry.collectionIndex;
		
		if(self.musicPlayer.nowPlayingCollection != self.musicTitles){
			[self.musicPlayer stop];
			[self.musicPlayer.queue setQueue:self.musicTitles];
		}
		
		[self.musicPlayer setNowPlayingTrack:track];
		
		[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
		[self.musicPlayer.navigationBar maximise:NO];

		[self.collectionView reloadData];
	} repeats:NO];
}

- (void)tapEntryAtIndex:(NSInteger)index {
	LMListEntry *entry = [self listEntryForIndex:index];
	if(entry){
		[self tappedListEntry:entry];
	}
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour mainColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	if(entry.collectionIndex >= self.musicTitles.items.count){
		return @"Error";
	}
	
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	
	BOOL isSelectedEntry = (self.currentlyHighlighted == entry.collectionIndex);
	
	entry.isAccessibilityElement = YES;
	entry.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@", track.title, [self subtitleForListEntry:entry], NSLocalizedString(isSelectedEntry ? @"VoiceOverLabel_Selected" : @"", nil)];
	entry.accessibilityHint = NSLocalizedString(isSelectedEntry ? @"" : @"VoiceOverHint_DetailViewListEntry", nil);
	
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	if(entry.collectionIndex >= self.musicTitles.items.count){
		return @"Email contact@lignite.io";
	}
	
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	
	NSString *subtitle = [NSString stringWithFormat:@"%@", track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil)];
	if(track.albumTitle){
		subtitle = [subtitle stringByAppendingString:[NSString stringWithFormat:@" - %@", track.albumTitle]];
	}
	
	return subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	if(entry.collectionIndex >= self.musicTitles.items.count){
		return [UIImage imageNamed:@"icon_bug"];
	}
	
//	NSInteger actualIndex = entry.collectionIndex % self.itemArray.count;
//
//	if(self.itemIconArray.count < 9){
//		return nil;
//	}
//	if([[self.itemIconArray objectAtIndex:actualIndex] isEqual:@""]){
//		return nil;
//	}
//	UIImage *image = [self.itemIconArray objectAtIndex:actualIndex];

	return [self.musicTitles.items objectAtIndex:entry.collectionIndex].albumArt;
	
//	return image;
}

- (NSArray<MGSwipeButton*>*)swipeButtonsForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	if(listEntry.collectionIndex >= self.musicTitles.count){
		return nil;
	}
	
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
	
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
	if(listEntry.collectionIndex >= self.musicTitles.count){
		return nil;
	}
	
	UIColor *swipeColour = [LMColour successGreenColour];
	
	LMMusicTrack *musicTrack = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
	
	if(!rightSide && musicTrack.isFavourite){ //Favourite/unfavourite
		swipeColour = [LMColour deletionRedColour];
	}
	
	return swipeColour;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
		
		[NSTimer scheduledTimerWithTimeInterval:0.2 block:^{
			[self.collectionView reloadData];
		} repeats:NO];
		
		if(!self.layoutManager.isLandscape){
			[self setShuffleButtonLandscapeOffset:4.0f];
		}
	}];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	return YES;
}

- (void)floatingDetailViewButtonTapped:(LMFloatingDetailViewButton*)button {
	[self setLoadingIndicatorDisplaying:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		[self.musicPlayer stop];
		
		[self.musicPlayer setShuffleMode:LMMusicShuffleModeOn];
		[self.musicPlayer.queue setQueue:self.musicTitles autoPlay:YES];
		
		[self.musicPlayer play];
	} repeats:NO];
}

- (void)setLoadingIndicatorDisplaying:(BOOL)displaying {
	if(displaying){
		self.loadingProgressHUD = [MBProgressHUD showHUDAddedTo:self animated:YES];
		
		self.loadingProgressHUD.mode = MBProgressHUDModeIndeterminate;
		self.loadingProgressHUD.label.text = NSLocalizedString(@"HangOn", nil);
		self.loadingProgressHUD.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
		self.loadingProgressHUD.userInteractionEnabled = NO;
	}
	else{
		[self.loadingProgressHUD hideAnimated:YES];
	}
}

- (void)themeChanged:(LMTheme)theme {
	if(self.musicPlayer.nowPlayingTrack){
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.currentlyHighlighted = -1;
		
		NSTimeInterval loadStartTime = [[NSDate new] timeIntervalSince1970];
		
		[self rebuildTrackCollection];
		
		NSLog(@"titleView: trackCollectionRebuild, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		NSLog(@"titleView: Initialise delegates, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 0, 10, 0);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
		self.collectionView.backgroundColor = [LMColour whiteColour];
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];

		
		NSLog(@"titleView: tableView, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		
		self.noObjectsLabel = [UILabel newAutoLayoutView];
		self.noObjectsLabel.numberOfLines = 0;
		self.noObjectsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 16.0f : 18.0f];
		self.noObjectsLabel.text = NSLocalizedString(self.favourites ? @"NoTracksInFavourites" : @"TheresNothingHere", nil);
		self.noObjectsLabel.textAlignment = NSTextAlignmentLeft;
		[self addSubview:self.noObjectsLabel];
		
		[self.noObjectsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:[LMLayoutManager isiPad] ? 100 : 20];
		[self.noObjectsLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
		[self.noObjectsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:[LMLayoutManager isiPad] ? 100 : 20];
		//	[self.noObjectsLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(3.0/4.0)];
		
		self.noObjectsLabel.hidden = (self.musicTitles.count > 0);
		
		
		NSLog(@"titleView: noObjectsLabel, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		
		self.shuffleButton = [LMFloatingDetailViewButton newAutoLayoutView];
		self.shuffleButton.type = LMFloatingDetailViewControlButtonTypeShuffle;
		self.shuffleButton.delegate = self;
		self.shuffleButton.isAccessibilityElement = YES;
		self.shuffleButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_DetailViewButtonShuffle", nil);
		self.shuffleButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_DetailViewButtonShuffle", nil);
		[self addSubview:self.shuffleButton];
		
		[self.shuffleButton autoPinEdgeToSuperviewMargin:ALEdgeTop].constant = 8;
		self.shuffleButtonTrailingConstraint = [self.shuffleButton autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self setShuffleButtonLandscapeOffset:4.0f];
		//	[button autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.shuffleButton autoSetDimension:ALDimensionWidth toSize:63.0f];
		[self.shuffleButton autoMatchDimension:ALDimensionHeight
								   toDimension:ALDimensionWidth
										ofView:self.shuffleButton];
		self.shuffleButton.hidden = !self.noObjectsLabel.hidden;
		
		NSLog(@"titleView: shuffleButton, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		[self.musicPlayer addMusicDelegate:self];
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
		[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
		
		
		NSLog(@"titleView: notifyDelegates, %f", (([[NSDate new] timeIntervalSince1970]) - loadStartTime));
		
		
		
		NSTimeInterval loadEndTime = [[NSDate new] timeIntervalSince1970];
		NSLog(@"Loaded title view, took %f seconds", (loadEndTime - loadStartTime));
		
		[self.collectionView reloadData];
		[self.collectionView performBatchUpdates:^{}
									  completion:^(BOOL finished) {
										  NSLog(@"Finished title view load: %d", finished);
										  if([LMSettings debugInitialisationSounds]){
											  AudioServicesPlaySystemSound(1256);
										  }
										  
										  LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
										  
										  [NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
											  [coreViewController loadButtonNavigationBar];
										  } repeats:NO];
									  }];
		
		if([self.delegate respondsToSelector:@selector(titleViewFinishedInitialising)]){
			[self.delegate titleViewFinishedInitialising];
		}
	}
	
	[super layoutSubviews];
}

- (MPMediaEntityPersistentID)topTrackPersistentID {
	return 0;
//	NSIndexPath *topIndexPath = [self.songListTableView indexPathForRowAtPoint:self.songListTableView.contentOffset];
//
//	if(!topIndexPath || (topIndexPath.section >= self.musicTitles.count)){
//		return 0;
//	}
//
//	LMMusicTrack *topMusicTrack = [self.musicTitles.items objectAtIndex:topIndexPath.section];
//
//	return topMusicTrack.persistentID;
}

//- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	[super encodeRestorableStateWithCoder:coder];
//	
//	NSIndexPath *topIndexPath = [self.songListTableView indexPathForRowAtPoint:self.songListTableView.contentOffset];
//
//	LMMusicTrack *topMusicTrack = [self.musicTitles.items objectAtIndex:topIndexPath.section];
//
//	[coder encodeInt64:topMusicTrack.persistentID forKey:LMTitleViewTopTrackPersistentIDKey];
//
//	NSLog(@"Current index path %@ track %@", topIndexPath, topMusicTrack.title);
//}
//
//- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
//	[super decodeRestorableStateWithCoder:coder];
//
//	NSLog(@"WHO DO YOU");
//
//	MPMediaEntityPersistentID topTrackPersistentID = [coder decodeInt64ForKey:LMTitleViewTopTrackPersistentIDKey];
//
//	[self scrollToTrackWithPersistentID:topTrackPersistentID];
//}

//- (NSString*)restorationIdentifier {
//	return @"LMTitleView";
//}

- (instancetype)init {
	self = [super init];
	if(self) {
//		self.restorationIdentifier = @"LMTitleView";
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Error creating LMTitleView");
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
