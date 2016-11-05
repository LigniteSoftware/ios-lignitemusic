//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAlbumDetailView.h"
#import "LMNowPlayingViewController.h"
#import "LMAlbumViewItem.h"
#import "LMAlbumView.h"
#import "LMButton.h"
#import "LMTableView.h"
#import "LMTableViewCell.h"
#import "LMAppIcon.h"
#import "LMMusicPlayer.h"

@interface LMAlbumView () <LMAlbumViewItemDelegate, LMTableViewSubviewDelegate, LMMusicPlayerDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMTableView *rootTableView;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property NSArray<LMMusicTrackCollection*>* albumCollections;
@property float lastUpdatedContentOffset;
@property BOOL loaded, hasLoadedInitialItems;

@property NSLayoutConstraint *topConstraint;

@property NSInteger currentlyPlaying;

@end

@implementation LMAlbumView

- (void)reloadSourceSelectorInfo {
	if(self.hidden){
		return;
	}
	
	NSString *collectionString = NSLocalizedString(self.albumCollections.count == 1 ? @"Album" : @"Albums", nil);
	
	NSLog(@"Setting source selector info.");
	
	[self.musicPlayer setSourceTitle:collectionString];
	[self.musicPlayer setSourceSubtitle:[NSString stringWithFormat:@"%ld %@", (long)self.albumCollections.count, collectionString]];
	
	NSLog(@"Set!");
}

- (void)dismissViewOnTop {
	[self layoutIfNeeded];
	self.topConstraint.constant = self.frame.size.height;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
	
	self.showingDetailView = NO;
	
	[self.rootViewController openBrowsingAssistant];
}

- (LMAlbumViewItem*)albumViewItemForAlbumIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMAlbumViewItem *item = nil;
	for(int i = 0; i < self.albumsItemArray.count; i++){
		LMAlbumViewItem *indexItem = [self.albumsItemArray objectAtIndex:i];
		if(indexItem.collectionIndex == index){
			item = indexItem;
			break;
		}
	}
	return item;
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.albumCollections.count; i++){
		LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:i];
		LMMusicTrack *representativeItem = collection.representativeItem;
		
		if(representativeItem.albumPersistentID == newTrack.albumPersistentID){
			newHighlightedIndex = i;
		}
	}
	
	LMAlbumViewItem *playingItem = [self albumViewItemForAlbumIndex:newHighlightedIndex];
	if(playingItem && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying){
		[playingItem.playButton setImage:[LMAppIcon imageForIcon:LMIconPause]];
	}
	
	LMAlbumViewItem *lastEntry = [self albumViewItemForAlbumIndex:self.currentlyPlaying];
	if(lastEntry && ![lastEntry isEqual:playingItem]){
		[lastEntry.playButton setImage:[LMAppIcon imageForIcon:LMIconPlay]];
	}
	
	self.currentlyPlaying = newHighlightedIndex;
	
	NSLog(@"The currently playing is %ld", self.currentlyPlaying);
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	LMAlbumViewItem *playingEntry = [self albumViewItemForAlbumIndex:self.currentlyPlaying];
	if(playingEntry){
		NSLog(@"Playing now: %d", newState);
		[playingEntry.playButton setImage:newState == LMMusicPlaybackStatePlaying ? [LMAppIcon imageForIcon:LMIconPause] : [LMAppIcon imageForIcon:LMIconPlay]];
	}
}

- (void)musicLibraryDidChange {
	[self rebuildTrackCollection];
	
	[self.rootTableView regenerate:YES];
	[self.rootTableView reloadData];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	
	[self dismissViewOnTop];
}

- (void)rebuildTrackCollection {
	self.albumCollections = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums];
	self.albumsCount = self.albumCollections.count;
	self.rootTableView.amountOfItemsTotal = self.albumsCount;
	[self reloadSourceSelectorInfo];
}

/**
 When an album view item is clicked, this is called. The system should then enter into detail view for the album view.

 @param item The item which was tapped.
 */
- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item {
	NSLog(@"I see you have tapped item with index %lu", (unsigned long)item.collectionIndex);
	
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:item.collectionIndex];
	NSLog(@"Collection %@", collection.representativeItem.artist);
	
	LMAlbumDetailView *detailView = [[LMAlbumDetailView alloc]initWithMusicTrackCollection:[self.albumCollections objectAtIndex:item.collectionIndex]];
	detailView.rootView = self;
	detailView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:detailView];
	
	self.topConstraint = [detailView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height];
	[detailView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[detailView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	
	[detailView setup];
	
	[self layoutIfNeeded];
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:0.5 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
	
	self.showingDetailView = YES;
	
	[self.rootViewController closeBrowsingAssistant];
}

- (void)openNowPlayingView {
//	LMNowPlayingViewController *nowPlayingController = [self.storyboard instantiateViewControllerWithIdentifier:@"nowPlayingController"];
	//[self presentViewController:nowPlayingController animated:YES c8ompletion:nil];	
	[self.rootViewController openNowPlayingView];
}


/**
 When an album view item's play button is tapped, this is called. The system should then start playing the album and display
 the now playing view.

 @param item The item which had its play button clicked.
 */
- (void)clickedPlayButtonOnAlbumViewItem:(LMAlbumViewItem*)item {
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:item.collectionIndex];
	
	if((self.musicPlayer.nowPlayingCollection && self.musicPlayer.nowPlayingCollection != collection) || (!self.musicPlayer.nowPlayingCollection && self.currentlyPlaying != item.collectionIndex)){
		self.musicPlayer.autoPlay = YES;
		[self.musicPlayer setNowPlayingCollection:collection];
		
		[self openNowPlayingView];
	}
	else{
		[self musicPlaybackStateDidChange:[self.musicPlayer invertPlaybackState]];
	}
}

/**
 See LMTableView for documentation on this function.
 */
- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(height){
		return 0.4;
	}
	return 0.8;
}

/**
 See LMTableView for documentation on this function.
 */
- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 20;
	//TODO fix this
}

/**
 See LMTableView for documentation on this function.
 */
- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return NO;
}

/**
 See LMTableView for documentation on this function.
 */
- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(self.albumsItemArray){
		NSLog(@"New amount %lu", (unsigned long)amount);
		//Quick patch to fix the following bug: when syncing and less than 3 albums are in place already and more are added the array gets all jumbled
		if(amount > self.albumsItemArray.count){
			LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:amount-1];
			LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMusicTrack:collection.representativeItem];
			[newItem setupWithAlbumCount:collection.count andDelegate:self];
			newItem.userInteractionEnabled = YES;
			[self.albumsItemArray addObject:newItem];
		}
		return;
	}
	
	self.albumsItemArray = [[NSMutableArray alloc]init];
	
	for(int i = 0; i < amount; i++){
		LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:i];
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMusicTrack:collection.representativeItem];
		[newItem setupWithAlbumCount:collection.count andDelegate:self];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
	}
}

/**
 See LMTableView for documentation on this function.
 */
- (id)prepareSubviewAtIndex:(NSUInteger)index {
//	LMAlbumViewItem *item = (LMAlbumViewItem*)subview;
//	item.collectionIndex = index;
//	
//	if(!hasLoaded){
//		if(!self.everything){
//			NSLog(@"self.everything doesn't exist!");
//			return;
//		}
//		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:index];
//		[item setupWithAlbumCount:[collection count] andDelegate:self];
//	}
		
	LMAlbumViewItem *albumViewItem = [self.albumsItemArray objectAtIndex:index % self.albumsItemArray.count];
	[albumViewItem.playButton setImage:(index == self.currentlyPlaying && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying) ? [LMAppIcon imageForIcon:LMIconPause] : [LMAppIcon imageForIcon:LMIconPlay]];
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:index];
	[albumViewItem updateContentsWithMusicTrack:collection.representativeItem andNumberOfItems:collection.count];
	albumViewItem.collectionIndex = index;
	
	return albumViewItem;
}

/**
 Called when the view did layout its subviews and redrawing needs to occur for any other views.
 */
- (void)layoutSubviews {
	if(self.loaded){
		return;
	}
	self.loaded = YES;
	
	self.currentlyPlaying = -1;
	
	self.rootTableView = [LMTableView newAutoLayoutView];
	self.rootTableView.subviewDelegate = self;
	[self addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgesToSuperviewEdges];
	
	[self rebuildTrackCollection];
	[self.rootTableView regenerate:NO];
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(openNowPlayingView)];
	[self addGestureRecognizer:pinchGesture];
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self reloadSourceSelectorInfo];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Error creating LMAlbumView!");
	}
	return self;
}

@end
