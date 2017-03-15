//
//  LMBrowsingDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/11/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingDetailView.h"
#import "LMBigListEntry.h"
#import "LMListEntry.h"
#import "LMTableView.h"
#import "LMExtras.h"
#import "LMTiledAlbumCoverView.h"
#import "LMColour.h"
#import "LMNowPlayingView.h"
#import "LMMusicPlayer.h"
#import "LMBrowsingDetailViewController.h"

@interface LMBrowsingDetailView()<LMTableViewSubviewDataSource, LMBigListEntryDelegate, LMCollectionInfoViewDelegate, LMListEntryDelegate, LMMusicPlayerDelegate, LMControlBarViewDelegate>

@property LMTableView *tableView;

@property LMBigListEntry *headerBigListEntry;
@property NSMutableArray *songEntries;

@property float largeSize;

@property LMMusicPlayer *musicPlayer;

@property NSInteger currentlyHighlighted;

/**
 The specific track collections associated with this browsing view. For example, an artist would have their albums within this array of collections.
 */
@property NSArray<LMMusicTrackCollection*>* specificTrackCollections;

/**
 The background imageView for the album art which will initially be partially covered.
 */
@property UIImageView *backgroundImageView;

/**
 The background tile for for music which is not artist based.
 */
@property LMTiledAlbumCoverView *backgroundTileView;

/**
 The control bar.
 */
@property LMControlBarView *controlBar;

@end

@implementation LMBrowsingDetailView

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	NSLog(@"Playback state changed in browsing detail view delegate");
	[self.controlBar reloadHighlightedButtons];
	
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.songEntries.count; i++){
		LMListEntry *indexEntry = [self.songEntries objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	if(self.specificTrackCollections){
		int count = 0;
		for(LMMusicTrackCollection *collection in self.specificTrackCollections){
			for(LMMusicTrack *track in collection.items){
				if(track.persistentID == newTrack.persistentID){
					newHighlightedIndex = count;
					NSLog(@"Found a match");
				}
			}
			count++;
		}
	}
	else{
		for(int i = 0; i < self.musicTrackCollection.trackCount; i++){
			LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:i];
			
			if(track.persistentID == newTrack.persistentID){
				newHighlightedIndex = i;
			}
		}
	}
	
	highlightedEntry = [self listEntryForIndex:newHighlightedIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		BOOL updateNowPlayingStatus = self.currentlyHighlighted == -1;
		self.currentlyHighlighted = newHighlightedIndex;
		if(updateNowPlayingStatus){
			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
		}
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	[self.controlBar reloadHighlightedButtons];
}

- (void)musicLibraryDidChange {
	[(UINavigationController*)self.window.rootViewController popViewControllerAnimated:YES];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	switch(index){
		case 0:{
			BOOL isPlaying = [self.musicPlayer.nowPlayingCollection isEqual:self.musicTrackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
			return [LMAppIcon imageForIcon:isPlaying ? LMIconPause : LMIconPlay];
		}
		case 1:{
			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconRepeat]];
		}
		case 2:{
			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconShuffle]];
		}
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView *)controlBar {
	BOOL isPlayingMusic = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
	
	switch(index) {
		case 0:{ //Play button
			LMMusicTrackCollection *trackCollection = self.musicTrackCollection;
			if(wasJustTapped){
				if(trackCollection.trackCount > 0){
					if(self.musicPlayer.nowPlayingCollection != trackCollection){
						self.musicPlayer.autoPlay = YES;
						isPlayingMusic = YES;
						[self.musicPlayer setNowPlayingCollection:trackCollection];
						
						[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
						[self.musicPlayer.navigationBar maximize];
					}
					else{
						isPlayingMusic ? [self.musicPlayer pause] : [self.musicPlayer play];
						isPlayingMusic = !isPlayingMusic;
					}
				}
				return isPlayingMusic;
			}
			else{
				return [self.musicPlayer.nowPlayingCollection isEqual:trackCollection] && isPlayingMusic;
			}
		}
		case 1: //Repeat button
			if(wasJustTapped){
				(self.musicPlayer.repeatMode == LMMusicRepeatModeAll)
					? (self.musicPlayer.repeatMode = LMMusicRepeatModeNone)
					: (self.musicPlayer.repeatMode = LMMusicRepeatModeAll);
			}
			NSLog(@"Repeat mode is %d", self.musicPlayer.repeatMode);
			return (self.musicPlayer.repeatMode == LMMusicRepeatModeAll);
		case 2: //Shuffle button
			if(wasJustTapped){
				self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
			}
			NSLog(@"Shuffle mode is %d", self.musicPlayer.shuffleMode);
			return (self.musicPlayer.shuffleMode == LMMusicShuffleModeOn);
	}
	return YES;
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	switch(self.musicType){
		case LMMusicTypeCompilations:
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return [self.musicTrackCollection titleForMusicType:self.musicType];
		}
		case LMMusicTypeAlbums: {
			return self.musicTrackCollection.representativeItem.albumTitle ? self.musicTrackCollection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
		}
		case LMMusicTypeComposers: {
			return self.musicTrackCollection.representativeItem.composer ? self.musicTrackCollection.representativeItem.composer : NSLocalizedString(@"UnknownComposer", nil);
		}
		case LMMusicTypeArtists: {
			return self.musicTrackCollection.representativeItem.artist ? self.musicTrackCollection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default:{
			return nil;
		}
	}
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			if(self.specificTrackCollections){
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)self.specificTrackCollections.count, NSLocalizedString(self.specificTrackCollections.count == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
			else{
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)self.musicTrackCollection.numberOfAlbums, NSLocalizedString(self.musicTrackCollection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return [NSString stringWithFormat:@"%ld %@", self.musicTrackCollection.trackCount, NSLocalizedString(self.musicTrackCollection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			if(self.musicTrackCollection.variousArtists){
				return NSLocalizedString(@"Various", nil);
			}
			return self.musicTrackCollection.representativeItem.artist ? self.musicTrackCollection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			return [NSString stringWithFormat:@"%ld %@", self.musicTrackCollection.trackCount, NSLocalizedString(self.musicTrackCollection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return nil;
		}
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			return [NSString stringWithFormat:@"%ld %@", self.musicTrackCollection.trackCount, NSLocalizedString(self.musicTrackCollection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		default: {
			return nil;
		}
	}
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	switch(self.musicType){
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
			tiledAlbumCover.musicCollection = self.musicTrackCollection;
			return tiledAlbumCover;
		}
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.image = [self.musicTrackCollection.representativeItem albumArt];
			return imageView;
		}
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.image = [self.musicTrackCollection.representativeItem artistImage];
			return imageView;
		}
		default: {
			return nil;
		}
	}
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	switch(self.musicType){
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
//		{
//			return height ? 0.25 : 0.80;
//		}
		case LMMusicTypeComposers:
		case LMMusicTypeArtists:
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			return height ? WINDOW_FRAME.size.width/WINDOW_FRAME.size.height : 1.0; //To fill to the edge of the screen
		}
		default: {
			return 0.50;
		}
	}
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	if(largeSize){
		self.largeSize = newHeight;
	}
	[self.tableView reloadSubviewSizes];
}

- (void)tappedListEntry:(LMListEntry*)entry {
	if(self.specificTrackCollections){
		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
		
		LMBrowsingDetailViewController *browsingDetailController = [LMBrowsingDetailViewController new];
		browsingDetailController.browsingDetailView = [LMBrowsingDetailView newAutoLayoutView];
		browsingDetailController.browsingDetailView.musicType = LMMusicTypeAlbums;
		browsingDetailController.browsingDetailView.musicTrackCollection = collection;
		browsingDetailController.browsingDetailView.rootViewController = self.rootViewController;
		[self.rootViewController showViewController:browsingDetailController sender:self];
		return;
	}
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTrackCollection){
#ifdef SPOTIFY
		[self.musicPlayer pause];
#else
		[self.musicPlayer stop];
#endif
		[self.musicPlayer setNowPlayingCollection:self.musicTrackCollection];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	if(self.specificTrackCollections){
		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
		return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
	}
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	if(self.specificTrackCollections){
		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
		return [NSString stringWithFormat:@"%ld %@", collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
	}
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	if(self.musicTrackCollection.variousArtists){
		if(self.musicType == LMMusicTypePlaylists){
			return [NSString stringWithFormat:@"#%ld | %@ | %@", (entry.collectionIndex + 1), [LMNowPlayingView durationStringTotalPlaybackTime:track.playbackDuration], track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil)];
		}
		else{
			return [NSString stringWithFormat:@"%@ | %@", [LMNowPlayingView durationStringTotalPlaybackTime:track.playbackDuration], track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil)];
		}
	}
	else{
		return [NSString stringWithFormat:NSLocalizedString(@"LengthOfSong", nil), [LMNowPlayingView durationStringTotalPlaybackTime:track.playbackDuration]];
	}
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	if(self.specificTrackCollections){
		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
		return [collection.representativeItem albumArt];
	}
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return [track albumArt];
}

- (NSString*)textForListEntry:(LMListEntry *)entry {
	if(self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations){
		return [NSString stringWithFormat:@"%ld", entry.collectionIndex+1];
	}
	return @":)";
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0){
		UIView *testView = [UIView newAutoLayoutView];
		testView.backgroundColor = [UIColor clearColor];
		return testView;
	}
	if(index == 1){
		UIView *rootView = [UIView newAutoLayoutView];
		
		LMCollectionInfoView *collectionInfoView = [LMCollectionInfoView newAutoLayoutView];
		collectionInfoView.delegate = self;
		collectionInfoView.largeMode = YES;
		[rootView addSubview:collectionInfoView];
		
		[collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[collectionInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:rootView withMultiplier:(6.0/10.0)];
		
		collectionInfoView.layer.shadowColor = [UIColor blackColor].CGColor;
		collectionInfoView.layer.shadowRadius = WINDOW_FRAME.size.width/35;
		collectionInfoView.layer.shadowOffset = CGSizeMake(0, collectionInfoView.layer.shadowRadius/2);
		collectionInfoView.layer.shadowOpacity = 0.25f;
		
		[collectionInfoView reloadData];
		
		
		LMControlBarView *controlBar = [LMControlBarView newAutoLayoutView];
		controlBar.delegate = self;
		[rootView addSubview:controlBar];
		
		[controlBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[controlBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[controlBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[controlBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:collectionInfoView];
		
		self.controlBar = controlBar;
		
		return rootView;
	}
	LMListEntry *listEntry = [self.songEntries objectAtIndex:(index-2) % self.songEntries.count];
	listEntry.collectionIndex = index-2; //To adjust for the big list entry at the top
	if(self.specificTrackCollections) {
		listEntry.associatedData = [self.specificTrackCollections objectAtIndex:listEntry.collectionIndex];
	}
	else{
		listEntry.associatedData = [self.musicTrackCollection.items objectAtIndex:listEntry.collectionIndex];
	}
	[listEntry changeHighlightStatus:self.currentlyHighlighted == listEntry.collectionIndex animated:NO];
	[listEntry reloadContents];
	return listEntry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0){
		return self.frame.size.width;
	}
	if(index == 1){
		//The size of the info view text + the size of the new control bar
		return self.frame.size.height/8.0 + self.frame.size.height/9.0;
	}
	return WINDOW_FRAME.size.height/8;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0 || index == 1){
		return 0;
	}
	return 10;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView {
	self.songEntries = [NSMutableArray new];
	
	NSUInteger countToUse = self.specificTrackCollections ? self.specificTrackCollections.count : self.musicTrackCollection.trackCount;
	for(int i = 0; i < MIN(amountOfObjects, countToUse); i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
		listEntry.associatedData = self.specificTrackCollections ?
									[self.specificTrackCollections objectAtIndex:i] :
									[self.musicTrackCollection.items objectAtIndex:i];
		listEntry.isLabelBased = (self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations);
		[listEntry setup];
		
		[self.songEntries addObject:listEntry];
	}
}

- (void)setup {
	self.currentlyHighlighted = -1;
	
	self.backgroundColor = [UIColor whiteColor];
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
										  && self.musicType != LMMusicTypeCompilations
										  && self.musicType != LMMusicTypeAlbums);
	
	if(usingSpecificTrackCollections){
		self.specificTrackCollections = [self.musicPlayer collectionsForRepresentativeTrack:self.musicTrackCollection.representativeItem
																			   forMusicType:self.musicType];
	}
	
	if(self.musicType == LMMusicTypeArtists){
		self.backgroundImageView = [UIImageView newAutoLayoutView];
		self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backgroundImageView.image = [self.musicTrackCollection.representativeItem artistImage];
		[self addSubview:self.backgroundImageView];
	}
	else{
		self.backgroundTileView = [LMTiledAlbumCoverView newAutoLayoutView];
		self.backgroundTileView.musicCollection = self.musicTrackCollection;
		[self addSubview:self.backgroundTileView];
	}
	
	id viewToPin = (self.musicType == LMMusicTypeArtists) ? self.backgroundImageView : self.backgroundTileView;
	
	[viewToPin autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[viewToPin autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[viewToPin autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[viewToPin autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
	
	
	self.tableView = [LMTableView newAutoLayoutView];
	self.tableView.title = @"PlaylistDetailView";
	self.tableView.averageCellHeight = WINDOW_FRAME.size.height*(1.0/10.0);
	self.tableView.totalAmountOfObjects = (self.specificTrackCollections ? self.specificTrackCollections.count : self.musicTrackCollection.trackCount) + 2;
	self.tableView.shouldUseDividers = YES;
	self.tableView.firstEntryClear = YES;
	self.tableView.dividerSectionsToIgnore = @[ @(0), @(1), @(2) ];
	self.tableView.subviewDataSource = self;
	self.tableView.bottomSpacing = WINDOW_FRAME.size.height/3.0;
	[self addSubview:self.tableView];
	
	NSLog(@"Items %ld spec %d", self.tableView.totalAmountOfObjects, self.specificTrackCollections ? 1 : 0);
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
	
	[self.tableView setContentOffset:CGPointMake(0, WINDOW_FRAME.size.width/4.0 * 3.0)];
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self.rootViewController pushItemOntoNavigationBarWithTitle:[self titleForInfoView:self.headerBigListEntry.collectionInfoView] withNowPlayingButton:YES];
}

@end
