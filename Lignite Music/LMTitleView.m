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
#import "LMLayoutManager.h"
#import "LMTitleView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMOperationQueue.h"
#import "LMMusicPlayer.h"
#import "LMExtras.h"
#import "LMThemeEngine.h"
#import "NSTimer+Blocks.h"

#define LMTitleViewTopTrackPersistentIDKey @"LMTitleViewTopTrackPersistentIDKey"

@interface LMTitleView() <LMListEntryDelegate, LMTableViewSubviewDataSource, LMMusicPlayerDelegate, UITableViewDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate, LMFloatingDetailViewButtonDelegate>

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

- (void)setShuffleButtonLandscapeOffset:(CGFloat)shuffleButtonLandscapeOffset {
	_shuffleButtonLandscapeOffset = shuffleButtonLandscapeOffset;
	
	[self layoutIfNeeded];
	
	self.shuffleButtonTrailingConstraint.constant = -shuffleButtonLandscapeOffset;
	
	[UIView animateWithDuration:0.2 animations:^{
		[self layoutIfNeeded];
	}];
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

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.musicTitles.count; i++){
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:i];
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
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		//BOOL updateNowPlayingStatus = self.currentlyHighlighted == -1;
		self.currentlyHighlighted = newHighlightedIndex;
//		if(updateNowPlayingStatus){
//			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
//		}
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self setLoadingIndicatorDisplaying:NO];
	} repeats:NO];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self setLoadingIndicatorDisplaying:NO];
	} repeats:NO];
}

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	[self.songListTableView reloadData];
	
	if(self.favourites){
		[self rebuildTrackCollection];
		[self.songListTableView reloadSubviewData];
		[self.songListTableView reloadData];
		
		self.currentlyHighlighted = -1;
		
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	[self.songListTableView reloadData];
	
	if(self.favourites){
		[self rebuildTrackCollection];
		[self.songListTableView reloadSubviewData];
		[self.songListTableView reloadData];
		
		self.currentlyHighlighted = -1;
		
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
}

- (void)rebuildTrackCollection {
	MPMediaQuery *everything = [MPMediaQuery new];
	MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic]
																					  forProperty:MPMediaItemPropertyMediaType
																				   comparisonType:MPMediaPredicateComparisonEqualTo];
	[everything addFilterPredicate:musicFilterPredicate];
	
	NSMutableArray *musicCollection = [[NSMutableArray alloc]initWithArray:[everything items]];
	
	NSString *sortKey = @"title";
	NSSortDescriptor *albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
	musicCollection = [NSMutableArray arrayWithArray:[musicCollection sortedArrayUsingDescriptors:@[albumSort]]];
	
	self.allSongsTrackCollection = [MPMediaItemCollection collectionWithItems:[NSArray arrayWithArray:musicCollection]];
	
	self.favouritesTrackCollection = [self.musicPlayer favouritesTrackCollection];
	
	self.songListTableView.totalAmountOfObjects = self.musicTitles.count;
	
	self.noObjectsLabel.hidden = (self.musicTitles.count > 0);
	self.noObjectsLabel.text = NSLocalizedString(self.favourites ? @"NoTracksInFavourites" : @"TheresNothingHere", nil);
	
	self.shuffleButton.hidden = !self.noObjectsLabel.hidden;
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
//	UIView *testView = [UIView newAutoLayoutView];
//	testView.backgroundColor = [LMColour randomColour];
//	testView.userInteractionEnabled = NO;
//	return testView;
//	
//
	
	if(index >= self.musicTitles.count){
		NSLog(@"Rejecting index, it's greater than the count of musicTitles");
		return nil;
	}

	
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.musicTitles.items objectAtIndex:index];
	
	if(!entry.queue){
		entry.queue = [[LMOperationQueue alloc] init];
	}
	
	[entry.queue cancelAllOperations];
	
	__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
		UIImage *albumArt = [track albumArt];
		
//		NSInteger indexToInsert = (index % self.itemArray.count);
//
//		if(self.itemIconArray.count < indexToInsert){
//			[self.itemIconArray removeObjectAtIndex:indexToInsert];
//		}
//		[self.itemIconArray insertObject:albumArt ? albumArt : [LMAppIcon imageForIcon:LMIconAlbums] atIndex:indexToInsert];
		
		entry.invertIconOnHighlight = albumArt == nil;
		
		//[self.itemIconArray object]
//		NSLog(@"%@ %ld %ld", albumArt, self.itemIconArray.count, indexToInsert);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			[entry reloadContents];
			
			operation = nil;
			
			//	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
			//	return [track albumArt];
		});
	}];
	
//	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
//	if(track.isFavourite){
//		entry.leftButtonExpansionColour = [LMColour deletionRedColour];
//		[[entry.leftButtons firstObject] setImage:[LMAppIcon imageForIcon:LMIconUnfavouriteWhite] forState:UIControlStateNormal];
//	}
//	else{
//		entry.leftButtonExpansionColour = [LMColour successGreenColour];
//		[[entry.leftButtons firstObject] setImage:[LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled] forState:UIControlStateNormal];
//	}
	
	[entry.queue addOperation:operation];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
//#warning spooked
//	[entry changeHighlightStatus:YES animated:YES];
	
	[entry reloadContents];
	
	
	if(!entry){
		NSLog(@"+++ Title view %d entry %p", (int)index, entry);
		NSLog(@":(");
	}
	
	return entry;
}

- (void)scrollToTrackIndex:(NSUInteger)index {
	if(index >= self.musicTitles.count){
		return;
	}
	
	self.didJustScrollByLetter = YES;
	
	[self.songListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
								  atScrollPosition:UITableViewScrollPositionTop
										  animated:NO];
	
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

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
//		self.itemIconArray = [NSMutableArray new];
		for(int i = 0; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc] initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
			listEntry.alignIconToLeft = NO;
			listEntry.stretchAcrossWidth = NO;
			
//			UIColor *colour = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
//			UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
//			MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@""
//																  icon:[LMAppIcon imageForIcon:LMIconAddToQueue]
//													   backgroundColor:colour
//															   padding:0
//															  callback:
//		    ^BOOL(MGSwipeTableCell *sender) {
//				LMMusicTrack *trackToQueue = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
//
//				[self.musicPlayer addTrackToQueue:trackToQueue];
//
//				NSLog(@"Queue %@", trackToQueue.title);
//
//				return YES;
//			}];
//			saveButton.titleLabel.font = font;
//			saveButton.titleLabel.hidden = YES;
//			saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//			saveButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
//
//			listEntry.rightButtons = @[ saveButton ];
//
//			MGSwipeButton *favouriteButton = [MGSwipeButton buttonWithTitle:@""
//																	   icon:[LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled]
//															backgroundColor:colour padding:0
//																   callback:
//		    ^BOOL(MGSwipeTableCell *sender) {
//				LMMusicTrack *track = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
//
//				if(track.isFavourite){
//					[self.musicPlayer removeTrackFromFavourites:track];
//				}
//				else{
//					[self.musicPlayer addTrackToFavourites:track];
//				}
//
//				NSLog(@"Favourite %@", track.title);
//
//				return YES;
//			}];
//			favouriteButton.titleLabel.font = font;
//			favouriteButton.titleLabel.hidden = YES;
//			favouriteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//			favouriteButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
//
//			listEntry.leftButtons = @[ favouriteButton ];
//			listEntry.leftButtonExpansionColour = [LMColour successGreenColour];
			
			[self.itemArray addObject:listEntry];
			
			//Quick hack to make sure that the items in the array are non nil
//			[self.itemIconArray addObject:@""];
		}
	}
}

- (CGFloat)heightAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	return LMLayoutManager.standardListEntryHeight;
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

- (CGFloat)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	if(index == 0){
		return 10;
	}
	return 10; //TODO: Fix this
}

- (void)tappedListEntry:(LMListEntry*)entry {
	[self setLoadingIndicatorDisplaying:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
		
		//	NSLog(@"Tapped list entry with artist %@", self.albumCollection.representativeItem.artist);
		
		LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
		if(previousHighlightedEntry){
			[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		}
		
		[entry changeHighlightStatus:YES animated:YES];
		self.currentlyHighlighted = entry.collectionIndex;
		
		if(self.musicPlayer.nowPlayingCollection != self.musicTitles){
			[self.musicPlayer stop];
			[self.musicPlayer setNowPlayingCollection:self.musicTitles];
		}
		self.musicPlayer.autoPlay = YES;
		
		[self.musicPlayer setNowPlayingTrack:track];
		
		[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
		[self.musicPlayer.navigationBar maximize:NO];
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
		return [UIImage imageNamed:@"icon_bug.png"];
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
		[self.songListTableView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
		[NSTimer scheduledTimerWithTimeInterval:0.2 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self.songListTableView reloadData];
		}];
		
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
		[self.musicPlayer setNowPlayingCollection:self.favourites ? self.favouritesTrackCollection : self.allSongsTrackCollection];
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
		
		[self rebuildTrackCollection];
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		self.songListTableView = [LMTableView newAutoLayoutView];
		self.songListTableView.totalAmountOfObjects = self.musicTitles.trackCount;
		self.songListTableView.subviewDataSource = self;
		self.songListTableView.shouldUseDividers = YES;
		self.songListTableView.averageCellHeight = [LMLayoutManager standardListEntryHeight] * (2.5/10.0);
		self.songListTableView.bottomSpacing = (WINDOW_FRAME.size.height/3.0);
		self.songListTableView.secondaryDelegate = self;
		[self addSubview:self.songListTableView];
		
		[self.songListTableView reloadSubviewData];
		
		[self.songListTableView autoPinEdgesToSuperviewEdges];
		
//		[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		
		
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
		
		
		self.shuffleButton = [LMFloatingDetailViewButton newAutoLayoutView];
		self.shuffleButton.type = LMFloatingDetailViewControlButtonTypeShuffle;
		self.shuffleButton.delegate = self;
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
		
		[self.musicPlayer addMusicDelegate:self];
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
		[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
	}
	
	[super layoutSubviews];
}

- (MPMediaEntityPersistentID)topTrackPersistentID {
	NSIndexPath *topIndexPath = [self.songListTableView indexPathForRowAtPoint:self.songListTableView.contentOffset];
	
	if(!topIndexPath || (topIndexPath.section >= self.musicTitles.count)){
		return 0;
	}
	
	LMMusicTrack *topMusicTrack = [self.musicTitles.items objectAtIndex:topIndexPath.section];
	
	return topMusicTrack.persistentID;
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
