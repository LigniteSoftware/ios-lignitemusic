//
//  LMBrowsingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/11/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingView.h"
#import "LMBigListEntryTableView.h"
#import "LMMusicPlayer.h"
#import "LMTiledAlbumCoverView.h"
#import "LMAppIcon.h"
#import "LMBrowsingDetailView.h"
#import "LMExtras.h"

@interface LMBrowsingView()<LMBigListEntryTableViewDelegate, LMMusicPlayerDelegate>

@property LMBigListEntryTableView *bigListEntryTableView;

@property LMMusicPlayer *musicPlayer;

@property NSLayoutConstraint *topConstraint;

@end

@implementation LMBrowsingView

- (void)reloadSourceSelectorInfo {
	if(self.hidden){
		return;
	}
	
	NSString *collectionString = NSLocalizedString(self.musicTrackCollections.count == 1 ? @"Playlist" : @"Playlists", nil);
	
	NSLog(@"Setting source selector info.");
	
	[self.musicPlayer setSourceTitle:collectionString];
	[self.musicPlayer setSourceSubtitle:[NSString stringWithFormat:@"%ld %@", (long)self.musicTrackCollections.count, collectionString]];
	
	NSLog(@"Set!");
}

- (void)dismissDetailView {
	[self layoutIfNeeded];
	self.topConstraint.constant = self.frame.size.width;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
	
	self.showingDetailView = NO;
	
	[self.rootViewController openBrowsingAssistant];
}

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
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			return collection.title;
		}
		case LMMusicTypeAlbums: {
			return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)leftTextForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			return [NSString stringWithFormat:@"%ld %@", collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeAlbums: {
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)rightTextForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			return nil;
		}
		case LMMusicTypeAlbums: {
			return [NSString stringWithFormat:@"%lu %@", collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		default: {
			return nil;
		}
	}
}

- (UIImage*)centerImageForBigListEntry:(LMBigListEntry*)bigListEntry {
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			return nil;
		}
		case LMMusicTypeAlbums: {
			return nil;
		}
		default: {
			return nil;
		}
	}
}

- (UIImage*)imageWithIndex:(uint8_t)index forBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
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

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Tapped %ld", bigListEntry.collectionIndex);
	
	LMBrowsingDetailView *browsingDetailView = [LMBrowsingDetailView newAutoLayoutView];
	browsingDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	browsingDetailView.musicType = self.musicType;
	[self addSubview:browsingDetailView];
	
	[browsingDetailView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[browsingDetailView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	self.topConstraint = [browsingDetailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:self.frame.size.width];
	[browsingDetailView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	
	[browsingDetailView setup];
	
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

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forBigListEntry:(LMBigListEntry*)bigListEntry {
	BOOL isPlayingMusic = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
	
	switch(index) {
		case 0:{ //Play button
			LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
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
	if(!bigListEntry.queue){
		bigListEntry.queue = [[LMOperationQueue alloc] init];
	}
	
	[bigListEntry.queue cancelAllOperations];
	
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			LMTiledAlbumCoverView *tiledAlbumCover = subview;
			
			tiledAlbumCover.musicCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
			break;
		}
		case LMMusicTypeAlbums: {
			UIImageView *imageView = (UIImageView*)subview;
			
			NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
				LMMusicTrack *representativeTrack = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem;
				UIImage *albumArt = [representativeTrack albumArt];
				
				dispatch_sync(dispatch_get_main_queue(), ^{
					if(operation.cancelled){
						NSLog(@"Rejecting.");
						return;
					}
					
					imageView.image = albumArt;
				});
			}];
			
			[bigListEntry.queue addOperation:operation];
			break;
		}
		default: {
			break;
		}
	}
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	switch(self.musicType){
		case LMMusicTypePlaylists: {
			LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
			tiledAlbumCover.musicCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
			return tiledAlbumCover;
		}
		case LMMusicTypeAlbums: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			imageView.image = [[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem albumArt];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.layer.shadowColor = [UIColor blackColor].CGColor;
			imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
			imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
			imageView.layer.shadowOpacity = 0.25f;
			return imageView;
		}
		default: {
			NSLog(@"Windows fucking error!");
			return nil;
		}
	}
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return height ? 0.4 : 0.8;
}

- (void)setup {
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	self.bigListEntryTableView = [LMBigListEntryTableView newAutoLayoutView];
	self.bigListEntryTableView.delegate = self;
	self.bigListEntryTableView.totalAmountOfObjects = self.musicTrackCollections.count;
	[self addSubview:self.bigListEntryTableView];
	
	[self.bigListEntryTableView autoPinEdgesToSuperviewEdges];
	
	[self.bigListEntryTableView setup];
	
	[self.musicPlayer addMusicDelegate:self];
}

@end
