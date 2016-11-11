//
//  LMPlaylistDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/11/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistDetailView.h"
#import "LMBigListEntry.h"
#import "LMListEntry.h"
#import "LMNewTableView.h"
#import "LMExtras.h"
#import "LMTiledAlbumCoverView.h"
#import "LMColour.h"
#import "LMNowPlayingView.h"
#import "LMMusicPlayer.h"

@interface LMPlaylistDetailView()<LMTableViewSubviewDataSource, LMBigListEntryDelegate, LMCollectionInfoViewDelegate, LMControlBarViewDelegate, LMListEntryDelegate>

@property LMNewTableView *tableView;

@property LMBigListEntry *headerBigListEntry;
@property NSMutableArray *songEntries;

@property float largeSize;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPlaylistDetailView

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	switch(index){
		case 0:{
			BOOL isPlaying = [self.musicPlayer.nowPlayingCollection isEqual:self.playlistCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
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
			LMMusicTrackCollection *trackCollection = self.playlistCollection;
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
	return self.playlistCollection.title;
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return [NSString stringWithFormat:@"%ld %@", self.playlistCollection.count, NSLocalizedString(self.playlistCollection.count == 1 ? @"Song" : @"Songs", nil)];
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
	tiledAlbumCover.musicCollection = self.playlistCollection;
	return tiledAlbumCover;
}

- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry {
	return 0.25;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	if(largeSize){
		self.largeSize = newHeight;
		NSLog(@"Set");
	}
	[self.tableView reloadSubviewSizes];
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Yes");
	
//	LMMusicTrack *track = [self.albumCollection.items objectAtIndex:entry.collectionIndex];
//	
//	NSLog(@"Tapped list entry with artist %@", self.albumCollection.representativeItem.artist);
//	
//	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
//	if(previousHighlightedEntry){
//		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
//	}
//	
//	[entry changeHighlightStatus:YES animated:YES];
//	self.currentlyHighlighted = entry.collectionIndex;
//	
//	if(self.musicPlayer.nowPlayingCollection != self.albumCollection){
//		[self.musicPlayer stop];
//		[self.musicPlayer setNowPlayingCollection:self.albumCollection];
//	}
//	self.musicPlayer.autoPlay = YES;
//	
//	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.playlistCollection.items objectAtIndex:entry.collectionIndex];
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.playlistCollection.items objectAtIndex:entry.collectionIndex];
	return [NSString stringWithFormat:NSLocalizedString(@"LengthOfSong", nil), [LMNowPlayingView durationStringTotalPlaybackTime:track.playbackDuration]];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.playlistCollection.items objectAtIndex:entry.collectionIndex];
	return [track albumArt];
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	if(index == 0){
		return self.headerBigListEntry;
	}
	LMListEntry *listEntry = [self.songEntries objectAtIndex:index % self.songEntries.count];
	listEntry.collectionIndex = index-1; //To adjust for the big list entry at the top
	[listEntry reloadContents];
	return listEntry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	if(index == 0){
		return [LMBigListEntry sizeForBigListEntryWhenOpened:self.headerBigListEntry.isLargeSize forDelegate:self];
	}
	return WINDOW_FRAME.size.height/8;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	if(index == 0){
		return 20;
	}
	return 10;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMNewTableView*)tableView {
	self.songEntries = [NSMutableArray new];
	
	for(int i = 0; i < amountOfObjects; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
		[listEntry setup];
		
		[self.songEntries addObject:listEntry];
	}
}

- (void)setup {
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	self.headerBigListEntry = [LMBigListEntry newAutoLayoutView];
	self.headerBigListEntry.infoDelegate = self;
	self.headerBigListEntry.entryDelegate = self;
	self.headerBigListEntry.controlBarDelegate = self;
	self.headerBigListEntry.collectionIndex = 0;
	self.headerBigListEntry.isLargeSize = YES;
	self.headerBigListEntry.userInteractionEnabled = YES;
	[self.headerBigListEntry setup];

	self.tableView = [LMNewTableView newAutoLayoutView];
	self.tableView.title = @"PlaylistDetailView";
	self.tableView.averageCellHeight = WINDOW_FRAME.size.height*(1.0/10.0);
	self.tableView.totalAmountOfObjects = self.playlistCollection.count + 1;
	self.tableView.shouldUseDividers = YES;
	self.tableView.dividerSectionsToIgnore = @[ @(0), @(1) ];
	self.tableView.subviewDataSource = self;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
}

@end
