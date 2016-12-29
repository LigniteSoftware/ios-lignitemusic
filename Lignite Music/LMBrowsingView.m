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
#import "LMBrowsingDetailViewController.h"
#import "LMImageManager.h"
#import "NSTimer+Blocks.h"

@interface LMBrowsingView()<UITableViewDelegate,
							LMBigListEntryTableViewDelegate, LMMusicPlayerDelegate, LMImageManagerDelegate>

@property LMBigListEntryTableView *bigListEntryTableView;

@property LMMusicPlayer *musicPlayer;
@property LMImageManager *imageManager;

@property NSLayoutConstraint *topConstraint;

@property LMBrowsingDetailViewController *browsingDetailViewController;

@property CGPoint originalOffset, currentOffset;

@end

@implementation LMBrowsingView

- (void)adjustNavigationBarForDifference {
//	if((self.bigListEntryTableView.tableView.contentSize.height
//		-self.bigListEntryTableView.tableView.contentOffset.y
//		-self.bigListEntryTableView.tableView.frame.size.height)
//	   < self.frame.size.height/2){
//		return;
//	}
	
	CGFloat difference = self.currentOffset.y - self.originalOffset.y;
	
	if(difference == 0){
		return;
	}
	
	CGFloat maximizeGive = (WINDOW_FRAME.size.height/3);
	CGFloat minimizeGive = (WINDOW_FRAME.size.height/8);
	
	BOOL goingUp = difference < 0;
	BOOL enoughGiveForMaximize = (fabs(difference) > maximizeGive);
	BOOL enoughGiveForMinimize = (difference > minimizeGive);
	
	NSLog(@"%f Going up %d", difference, goingUp);
	
	if(goingUp && enoughGiveForMaximize){
		[self.musicPlayer.navigationBar maximize];
	}
	else{
		if(!goingUp && enoughGiveForMinimize){
			[self.musicPlayer.navigationBar minimize];
		}
		else if(!goingUp){
			[self.musicPlayer.navigationBar maximize];
		}
	}
	
	self.currentOffset = self.originalOffset;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	NSLog(@"Will begin dragging");
	self.originalOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSLog(@"Did end animating");
	
	[self adjustNavigationBarForDifference];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(!decelerate){
		NSLog(@"Did end dragging");
		
		[self adjustNavigationBarForDifference];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if((self.bigListEntryTableView.tableView.contentSize.height
		-self.bigListEntryTableView.tableView.contentOffset.y
		-self.bigListEntryTableView.tableView.frame.size.height)
	    < self.frame.size.height/2){
		return;
	}
	   
	self.currentOffset = scrollView.contentOffset;
	
	CGFloat difference = self.currentOffset.y - self.originalOffset.y;
	
//	NSLog(difference < 0 ? @"Scrolling upwards" : @"Scrolling downwards");
	
	[self.musicPlayer.navigationBar moveToYPosition:difference];
}

- (void)scrollViewToIndex:(NSUInteger)index {
	[self.bigListEntryTableView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
												atScrollPosition:UITableViewScrollPositionTop
														animated:NO];
}

- (void)scrollToItemWithPersistentID:(LMMusicTrackPersistentID)persistentID {
	NSInteger index = -1;
	
	for(NSUInteger i = 0; i < self.musicTrackCollections.count; i++){
		LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:i];
		LMMusicTrack *representativeTrack = [trackCollection representativeItem];
		
		switch(self.musicType) {
			case LMMusicTypeAlbums:
				if(persistentID == representativeTrack.albumPersistentID){
					index = i;
				}
				break;
			case LMMusicTypeArtists:
				if(persistentID == representativeTrack.artistPersistentID){
					index = i;
				}
				break;
			case LMMusicTypeComposers:
				if(persistentID == representativeTrack.composerPersistentID){
					index = i;
				}
				break;
			case LMMusicTypeGenres:
				if(persistentID == representativeTrack.genrePersistentID){
					index = i;
				}
				break;
			case LMMusicTypePlaylists:
				if(persistentID == trackCollection.persistentID){
					index = i;
				}
				break;
			case LMMusicTypeCompilations:
				if(persistentID == trackCollection.persistentID){
					index = i;
				}
				break;
			default:
				NSLog(@"Unsupported search result in browsing view.");
				break;
		}
		
		if(index != -1){
			break;
		}
	}
	
	if(index == -1){
		index = 0;
	}
	
	[self.bigListEntryTableView focusBigListEntryAtIndex:index];
	
	[self scrollViewToIndex:index];
}

- (void)reloadSourceSelectorInfo {
	NSString *titleString;
	NSString *singlularString;
	NSString *pluralString;
	
	NSLog(@"Yes %d", self.musicType);
	
	switch(self.musicType){
		case LMMusicTypePlaylists:{
			titleString = @"Playlists";
			singlularString = @"List";
			pluralString = @"Lists";
			break;
		}
		case LMMusicTypeAlbums:{
			titleString = @"Albums";
			singlularString = @"Album";
			pluralString = @"Albums";
			break;
		}
		case LMMusicTypeGenres:{
			titleString = @"Genres";
			singlularString = @"Genre";
			pluralString = @"Genres";
			break;
		}
		case LMMusicTypeArtists: {
			titleString = @"Artists";
			singlularString = @"Artist";
			pluralString = @"Artists";
			break;
		}
		case LMMusicTypeComposers: {
			titleString = @"Composers";
			singlularString = @"Composer";
			pluralString = @"Composers";
			break;
		}
		case LMMusicTypeCompilations: {
			titleString = @"Compilations";
			singlularString = @"Compilation";
			pluralString = @"Compilations";
			break;
		}
		default: {
			titleString = @"Unknowns";
			singlularString = @"Unknown";
			pluralString = @"Unknowns";
			break;
		}
	}
	
	NSString *collectionString = NSLocalizedString(self.musicTrackCollections.count == 1 ? singlularString : pluralString, nil);
	
	[self.musicPlayer setSourceTitle:NSLocalizedString(titleString, nil)];
	[self.musicPlayer setSourceSubtitle:[NSString stringWithFormat:@"%ld %@", (long)self.musicTrackCollections.count, collectionString]];
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
	
//	[self.rootViewController openBrowsingAssistant];
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
		case LMMusicTypeGenres: {
			return collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
		}
		case LMMusicTypeCompilations:{
			return [collection titleForMusicType:LMMusicTypeCompilations];
		}
		case LMMusicTypePlaylists:{
			return [collection titleForMusicType:LMMusicTypePlaylists];
		}
		case LMMusicTypeAlbums: {
			return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
		}
		case LMMusicTypeArtists: {
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		case LMMusicTypeComposers: {
			return collection.representativeItem.composer ? collection.representativeItem.composer : NSLocalizedString(@"UnknownComposer", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)leftTextForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, [NSLocalizedString(collection.numberOfAlbums == 1 ? @"Album" : @"Albums", nil) lowercaseString]];
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
		case LMMusicTypeCompilations:
		{
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeAlbums: {
			if(collection.variousArtists){
				return NSLocalizedString(@"Various", nil);
			}
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
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
		case LMMusicTypeCompilations:
		{
			return nil;
		}
		case LMMusicTypeAlbums: {
			return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		}
		default: {
			return nil;
		}
	}
}

- (UIImage*)centerImageForBigListEntry:(LMBigListEntry*)bigListEntry {
	switch(self.musicType){
		case LMMusicTypeArtists:
		case LMMusicTypeGenres:
		case LMMusicTypeAlbums:
		case LMMusicTypeComposers:
		case LMMusicTypeCompilations:
		case LMMusicTypePlaylists: {
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
	browsingDetailView.rootViewController = self.rootViewController;
	
	self.browsingDetailViewController = [LMBrowsingDetailViewController new];
	self.browsingDetailViewController.browsingDetailView = browsingDetailView;
	self.browsingDetailViewController.requiredHeight = self.frame.size.height;
	
	self.rootViewController.currentDetailViewController = self.browsingDetailViewController;
	
	[self.rootViewController showViewController:self.browsingDetailViewController sender:self.rootViewController];
	
//	[self.rootViewController closeBrowsingAssistant];
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
		bigListEntry.queue = [LMOperationQueue new];
	}
	
	[bigListEntry.queue cancelAllOperations];
	
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			UIImageView *imageView = (UIImageView*)subview;
			
			NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
				LMMusicTrack *representativeTrack = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem;
				UIImage *artistImage = [representativeTrack artistImage];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if(operation.cancelled){
						NSLog(@"Rejecting.");
						return;
					}
					
					imageView.image = artistImage;
				});
			}];
			
			[bigListEntry.queue addOperation:operation];
			break;
		}
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			LMTiledAlbumCoverView *tiledAlbumCover = subview;
//			tiledAlbumCover.simpleMode = YES;
			tiledAlbumCover.musicCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
			break;
		}
		default: {
			break;
		}
	}
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			imageView.image = [[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem artistImage];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.layer.shadowColor = [UIColor blackColor].CGColor;
			imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
			imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
			imageView.layer.shadowOpacity = 0.25f;
			return imageView;
		}
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
			tiledAlbumCover.musicCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
//			tiledAlbumCover.simpleMode = YES;
			return tiledAlbumCover;
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

- (void)imageCacheChangedForCategory:(LMImageManagerCategory)category {
//	if(self.musicType == LMMusicTypeArtists && category == LMImageManagerCategoryArtistImages){
		[self.bigListEntryTableView reloadData];
//	}
}

- (void)setup {
	self.originalOffset = CGPointMake(0, 0);
	
	self.bigListEntryTableView.hidden = YES;
	[self.bigListEntryTableView removeFromSuperview];
	self.bigListEntryTableView = nil;
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.imageManager = [LMImageManager sharedImageManager];
	
	self.bigListEntryTableView = [LMBigListEntryTableView newAutoLayoutView];
	self.bigListEntryTableView.delegate = self;
	self.bigListEntryTableView.totalAmountOfObjects = self.musicTrackCollections.count;
	[self addSubview:self.bigListEntryTableView];
	
	[self.bigListEntryTableView autoPinEdgesToSuperviewEdges];
	
	[self.bigListEntryTableView setup];
	
	self.bigListEntryTableView.tableView.secondaryDelegate = self;
	
	[self.musicPlayer addMusicDelegate:self];
	[self.imageManager addDelegate:self];
}

@end
