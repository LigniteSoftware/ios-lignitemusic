//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/9/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistView.h"
#import "LMBigListEntryTableView.h"
#import "LMMusicPlayer.h"
#import "LMTiledAlbumCoverView.h"
#import "LMAppIcon.h"

@interface LMPlaylistView()<LMBigListEntryTableViewDelegate, LMMusicPlayerDelegate>

@property LMBigListEntryTableView *bigListEntryTableView;
@property NSArray<LMMusicTrackCollection*> *playlistCollections;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPlaylistView

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self.bigListEntryTableView reloadControlBars];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self.bigListEntryTableView reloadControlBars];
}

- (void)musicLibraryDidChange {
	NSLog(@"Music library changed");
}

- (NSString*)titleForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
//	NSLog(@"Collection index %ld", bigListEntry.collectionIndex);
	return collection.title;
}

- (NSString*)leftTextForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
	
	return [NSString stringWithFormat:@"%ld %@", collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
}

- (NSString*)rightTextForBigListEntry:(LMBigListEntry*)bigListEntry {
	return nil;
}

- (UIImage*)centerImageForBigListEntry:(LMBigListEntry*)bigListEntry {
	return nil;
}

- (UIImage*)imageWithIndex:(uint8_t)index forBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *trackCollection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(index){
		case 0:{
			BOOL isPlaying = [self.musicPlayer.nowPlayingCollection isEqual:trackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
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

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forBigListEntry:(LMBigListEntry*)bigListEntry {
	BOOL isPlayingMusic = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
	
	switch(index) {
		case 0:{ //Play button
			LMMusicTrackCollection *trackCollection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
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

- (uint8_t)amountOfButtonsForBigListEntry:(LMBigListEntry*)bigListEntry {
	return 3;
}

- (void)prepareContentSubview:(id)subview forBigListEntry:(LMBigListEntry *)bigListEntry {
	LMTiledAlbumCoverView *tiledAlbumCover = subview;
	tiledAlbumCover.musicCollection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
//	NSLog(@"Collection index %ld count %ld", bigListEntry.collectionIndex, self.playlistCollections.count);
	tiledAlbumCover.musicCollection = [self.playlistCollections objectAtIndex:bigListEntry.collectionIndex];
//	NSLog(@"Returning");
	return tiledAlbumCover;
}

- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry {
	return 0.4;
}

- (void)setup {
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	self.playlistCollections = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists];
	
	self.bigListEntryTableView = [LMBigListEntryTableView newAutoLayoutView];
	self.bigListEntryTableView.delegate = self;
	self.bigListEntryTableView.totalAmountOfObjects = self.playlistCollections.count;
	[self addSubview:self.bigListEntryTableView];
	
	[self.bigListEntryTableView autoPinEdgesToSuperviewEdges];
	
	[self.bigListEntryTableView setup];
	
	[self.musicPlayer addMusicDelegate:self];
}

@end
