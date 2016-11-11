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

@interface LMPlaylistView()<LMBigListEntryTableViewDelegate>

@property LMBigListEntryTableView *bigListEntryTableView;
@property NSArray<LMMusicTrackCollection*> *playlistCollections;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPlaylistView

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
	switch(index){
		case 0:
			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlay]];
		case 1:
			return [LMAppIcon imageForIcon:LMIconRepeat];
		case 2:
			return [LMAppIcon imageForIcon:LMIconShuffle];
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forBigListEntry:(LMBigListEntry*)bigListEntry {
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
}

@end
