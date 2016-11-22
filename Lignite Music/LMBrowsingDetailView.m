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
#import "LMPlaylistView.h"

@interface LMBrowsingDetailView()<LMTableViewSubviewDataSource, LMBigListEntryDelegate, LMCollectionInfoViewDelegate, LMControlBarViewDelegate, LMListEntryDelegate, LMMusicPlayerDelegate>

@property LMTableView *tableView;

@property LMBigListEntry *headerBigListEntry;
@property NSMutableArray *songEntries;

@property float largeSize;

@property LMMusicPlayer *musicPlayer;

@property NSInteger currentlyHighlighted;

@end

@implementation LMBrowsingDetailView

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
	for(int i = 0; i < self.musicTrackCollection.count; i++){
		LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:i];
		LMListEntry *entry = [self listEntryForIndex:i];
		LMMusicTrack *entryTrack = entry.associatedData;
		
		if(entryTrack.persistentID == newTrack.persistentID){
			highlightedEntry = entry;
		}
		
		if(track.persistentID == newTrack.persistentID){
			newHighlightedIndex = i;
		}
	}
	
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

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self.headerBigListEntry reloadData:NO];
}

- (void)musicLibraryDidChange {
	[self swipeRightClose];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	switch(index){
		case 0:{
			BOOL isPlaying = [self.musicPlayer.nowPlayingCollection isEqual:self.musicTrackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:isPlaying ? LMIconPause : LMIconPlay]];
		}
		case 1:{
			return [LMAppIcon imageForIcon:LMIconRepeat];
		}
		case 2:{
			return [LMAppIcon imageForIcon:LMIconShuffle];
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
				if(trackCollection.count > 0){
					if(self.musicPlayer.nowPlayingCollection != trackCollection){
						self.musicPlayer.autoPlay = YES;
						isPlayingMusic = YES;
						[self.musicPlayer setNowPlayingCollection:trackCollection];
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
				(self.musicPlayer.repeatMode == LMMusicRepeatModeAll) ? (self.musicPlayer.repeatMode = LMMusicRepeatModeNone) : (self.musicPlayer.repeatMode = LMMusicRepeatModeAll);
			}
			return (self.musicPlayer.repeatMode == LMMusicRepeatModeAll);
		case 2: //Shuffle button
			if(wasJustTapped){
				self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
			}
			return (self.musicPlayer.shuffleMode == LMMusicShuffleModeOn);
	}
	return YES;
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	switch(self.musicType){
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return self.musicTrackCollection.title;
		}
		case LMMusicTypeAlbums: {
			return self.musicTrackCollection.representativeItem.albumTitle;
		}
		default:{
			return nil;
		}
	}
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	switch(self.musicType){
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return [NSString stringWithFormat:@"%ld %@", self.musicTrackCollection.count, NSLocalizedString(self.musicTrackCollection.count == 1 ? @"Song" : @"Songs", nil)];
		}
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
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return nil;
		}
		case LMMusicTypeAlbums: {
			return [NSString stringWithFormat:@"%ld %@", self.musicTrackCollection.count, NSLocalizedString(self.musicTrackCollection.count == 1 ? @"Song" : @"Songs", nil)];
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
		case LMMusicTypeAlbums: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.image = [self.musicTrackCollection.representativeItem albumArt];
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
		case LMMusicTypePlaylists: {
			return height ? 0.25 : 0.80;
		}
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
		NSLog(@"Set");
	}
	[self.tableView reloadSubviewSizes];
}

- (void)tappedListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTrackCollection){
		[self.musicPlayer stop];
		[self.musicPlayer setNowPlayingCollection:self.musicTrackCollection];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return [NSString stringWithFormat:NSLocalizedString(@"LengthOfSong", nil), [LMNowPlayingView durationStringTotalPlaybackTime:track.playbackDuration]];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	switch(self.musicType) {
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
			return [track albumArt];
		}
		case LMMusicTypeAlbums: {
			return nil;
		}
		default: {
			return nil;
		}
	}
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0){
		return self.headerBigListEntry;
	}
	LMListEntry *listEntry = [self.songEntries objectAtIndex:(index-1) % self.songEntries.count];
	listEntry.collectionIndex = index-1; //To adjust for the big list entry at the top
	listEntry.associatedData = [self.musicTrackCollection.items objectAtIndex:listEntry.collectionIndex];
	[listEntry changeHighlightStatus:self.currentlyHighlighted == listEntry.collectionIndex animated:NO];
	[listEntry reloadContents];
	return listEntry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0){
		return [LMBigListEntry sizeForBigListEntryWhenOpened:self.headerBigListEntry.isLargeSize forDelegate:self];
	}
	return WINDOW_FRAME.size.height/8;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if(index == 0){
		return 0;
	}
	return 10;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView {
	self.songEntries = [NSMutableArray new];
	
	for(int i = 0; i < MIN(amountOfObjects, self.musicTrackCollection.count); i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
		listEntry.associatedData = [self.musicTrackCollection.items objectAtIndex:i];
		[listEntry setup];
		
		[self.songEntries addObject:listEntry];
	}
}

- (void)swipeRightClose {
	[self.musicPlayer removeMusicDelegate:self];
	
	LMBrowsingView *browsingView = (LMBrowsingView*)self.superview;
	[browsingView dismissDetailView];
}

- (void)setup {
	self.currentlyHighlighted = -1;
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	self.headerBigListEntry = [LMBigListEntry newAutoLayoutView];
	self.headerBigListEntry.infoDelegate = self;
	self.headerBigListEntry.entryDelegate = self;
	self.headerBigListEntry.controlBarDelegate = self;
	self.headerBigListEntry.collectionIndex = 0;
	self.headerBigListEntry.isLargeSize = YES;
	self.headerBigListEntry.userInteractionEnabled = YES;
	[self.headerBigListEntry setup];
	
	self.tableView = [LMTableView newAutoLayoutView];
	self.tableView.title = @"PlaylistDetailView";
	self.tableView.averageCellHeight = WINDOW_FRAME.size.height*(1.0/10.0);
	self.tableView.totalAmountOfObjects = self.musicTrackCollection.count + 1;
	self.tableView.shouldUseDividers = YES;
	self.tableView.dividerSectionsToIgnore = @[ @(0), @(1) ];
	self.tableView.subviewDataSource = self;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
	
	UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRightClose)];
	swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self addGestureRecognizer:swipeRightGesture];
	
	[self.musicPlayer addMusicDelegate:self];
}

@end
