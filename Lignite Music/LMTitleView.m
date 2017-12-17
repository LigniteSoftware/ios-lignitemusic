//
//  LMTitleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLayoutManager.h"
#import "LMTitleView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMOperationQueue.h"
#import "LMMusicPlayer.h"
#import "APIdleManager.h"
#import "LMExtras.h"
#import "LMThemeEngine.h"

#define LMTitleViewTopTrackPersistentIDKey @"LMTitleViewTopTrackPersistentIDKey"

@interface LMTitleView() <LMListEntryDelegate, LMTableViewSubviewDataSource, LMMusicPlayerDelegate, UITableViewDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate>

@property LMMusicPlayer *musicPlayer;

@property NSMutableArray *itemArray;
//@property NSMutableArray *itemIconArray;
//^ just retarded dude lol

@property NSInteger currentlyHighlighted;

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

@end

@implementation LMTitleView

@synthesize musicTitles = _musicTitles;

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
	
	[[APIdleManager sharedInstance] didReceiveInput];
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
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
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
}

- (void)musicLibraryDidChange {
	[self rebuildTrackCollection];
	
	[self.songListTableView reloadSubviewData];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
//	UIView *testView = [UIView newAutoLayoutView];
//	testView.backgroundColor = [LMColour randomColour];
//	testView.userInteractionEnabled = NO;
//	return testView;
//	
//
	
	if(index >= self.musicTitles.count){
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
	
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	if(track.isFavourite){
		entry.leftButtonExpansionColour = [LMColour mainColour];
		[[entry.leftButtons firstObject] setImage:[LMAppIcon imageForIcon:LMIconUnfavouriteWhite] forState:UIControlStateNormal];
	}
	else{
		entry.leftButtonExpansionColour = [LMColour successGreenColour];
		[[entry.leftButtons firstObject] setImage:[LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled] forState:UIControlStateNormal];
	}
	
	[entry.queue addOperation:operation];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	
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

- (void)scrollToTrackWithPersistentID:(LMMusicTrackPersistentID)persistentID {
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
	
	[self.songListTableView focusCellAtIndex:index];
	
	//Fix index for adjustment
	index = (index == 0) ? 0 : (index-2);
	
	if(index > -1){
		[self.songListTableView focusCellAtIndex:index];
		[self scrollToTrackIndex:index];
	}
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
//		self.itemIconArray = [NSMutableArray new];
		for(int i = 0; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
			listEntry.alignIconToLeft = YES;
			listEntry.stretchAcrossWidth = YES;
			
			UIColor *color = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
			UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
			MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@"" icon:[LMAppIcon imageForIcon:LMIconAddToQueue] backgroundColor:color padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
				LMMusicTrack *trackToQueue = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
				
				[self.musicPlayer addTrackToQueue:trackToQueue];
				
				NSLog(@"Queue %@", trackToQueue.title);
				
				return YES;
			}];
			saveButton.titleLabel.font = font;
			saveButton.titleLabel.hidden = YES;
			saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
			saveButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);

			listEntry.rightButtons = @[ saveButton ];
			
			MGSwipeButton *favouriteButton = [MGSwipeButton buttonWithTitle:@"" icon:[LMAppIcon imageForIcon:LMIconFavouriteWhiteFilled] backgroundColor:color padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
				LMMusicTrack *track = [self.musicTitles.items objectAtIndex:listEntry.collectionIndex];
				
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
			listEntry.leftButtonExpansionColour = [LMColour successGreenColour];
						
			[self.itemArray addObject:listEntry];
			
			//Quick hack to make sure that the items in the array are non nil
//			[self.itemIconArray addObject:@""];
		}
	}
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	if([LMLayoutManager isiPad]){
		return [LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.width/12.0f : WINDOW_FRAME.size.height/12.0f;
	}
	return self.layoutManager.isLandscape ? WINDOW_FRAME.size.width/8.0 : WINDOW_FRAME.size.height/8.0;
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
	if(index == 0){
		return 10;
	}
	return 10; //TODO: Fix this
}

- (void)tappedListEntry:(LMListEntry*)entry{
	
	
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
		return @"Please email contact@lignite.io";
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

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Nothing, yet
	}];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	return YES;
}

- (void)themeChanged:(LMTheme)theme {
	if(self.musicPlayer.nowPlayingTrack){
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
}

- (void)setup {
	[self rebuildTrackCollection];
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
	self.songListTableView = [LMTableView newAutoLayoutView];
	self.songListTableView.totalAmountOfObjects = self.musicTitles.trackCount;
	self.songListTableView.subviewDataSource = self;
	self.songListTableView.shouldUseDividers = YES;
	self.songListTableView.averageCellHeight = [LMLayoutManager isiPad] ? (WINDOW_FRAME.size.height/14.0f) : (WINDOW_FRAME.size.height/10);
	self.songListTableView.bottomSpacing = (WINDOW_FRAME.size.height/3.0);
    self.songListTableView.secondaryDelegate = self;
	self.songListTableView.fullDividers = YES;
	[self addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	
	
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
	
	
	
	
	[self.songListTableView reloadSubviewData];
		
	[self.musicPlayer addMusicDelegate:self];
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
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
