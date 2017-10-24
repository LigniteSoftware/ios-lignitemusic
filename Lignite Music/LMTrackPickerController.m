//
//  LMTrackPickerController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTrackPickerController.h"
#import "LMColour.h"
#import "LMListEntry.h"

@interface LMTrackPickerController ()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The collection view that will display the contents provided.
 */
@property UICollectionView *collectionView;

/**
 The array of list entries which go on the collection view.
 */
@property NSMutableArray *listEntryArray;

@end

@implementation LMTrackPickerController

@synthesize titleTrackCollection = _titleTrackCollection;

- (LMMusicTrackCollection*)titleTrackCollection {
	if(self.trackCollections.count > 0){
		return [self.trackCollections objectAtIndex:0];
	}
	return nil;
}

- (void)tappedListEntry:(LMListEntry*)entry{
	NSLog(@"Tapped %p", entry);
	
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		NSLog(@"Pick song");
		return;
	}
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	NSString *title = nil;
	
	LMMusicTrack *representativeItem = [self.trackCollections objectAtIndex:entry.collectionIndex].representativeItem;
	NSLog(@"Representative %@", representativeItem.albumTitle);
	NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer collectionsForRepresentativeTrack:representativeItem forMusicType:self.musicType];
	
	if(self.depthLevel == LMTrackPickerDepthLevelAlbums){
		trackCollections = @[ [self.trackCollections objectAtIndex:entry.collectionIndex] ];
	}
	
	switch(self.musicType){
		case LMMusicTypeTitles:{
			title = NSLocalizedString(@"Titles", nil);
			break;
		}
		case LMMusicTypeFavourites:{
			//Select song
			title = NSLocalizedString(@"Favourites", nil);
			break;
		}
		case LMMusicTypeArtists:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			title = representativeItem.artist;
			break;
		}
		case LMMusicTypeAlbums:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			title = representativeItem.albumTitle;
			break;
		}
		case LMMusicTypeGenres:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			title = representativeItem.genre;
			break;
		}
		case LMMusicTypeCompilations:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			title = representativeItem.albumTitle;
			break;
		}
		default:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
		}
	}
	
	trackPickerController.title = title;
	trackPickerController.trackCollections = trackCollections;
	
	[self showViewController:trackPickerController sender:nil];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.trackCollections objectAtIndex:entry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return [self.titleTrackCollection.items objectAtIndex:entry.collectionIndex].title;
		case LMMusicTypeGenres: {
			return collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
		}
		case LMMusicTypeCompilations:{
			return [collection titleForMusicType:LMMusicTypeCompilations];
		}
		case LMMusicTypeAlbums: {
			return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
		}
		case LMMusicTypeArtists: {
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default: {
			return @"Error";
		}
	}
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.trackCollections objectAtIndex:entry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return [self.titleTrackCollection.items objectAtIndex:entry.collectionIndex].artist;
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
												  && self.musicType != LMMusicTypeCompilations
												  && self.musicType != LMMusicTypeAlbums);
			
			if(usingSpecificTrackCollections){
				//Fixes for compilations
				NSUInteger albums = [self.musicPlayer collectionsForRepresentativeTrack:collection.representativeItem
																		   forMusicType:self.musicType].count;
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)albums, NSLocalizedString(albums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
			else{
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
		{
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeCompilations:
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

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.trackCollections objectAtIndex:entry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			return [collection.representativeItem artistImage];
		}
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			return [collection.representativeItem albumArt];
		}
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			if(self.titleTrackCollection.count == 0){
				return nil;
			}
			return [self.titleTrackCollection.items objectAtIndex:entry.collectionIndex].albumArt;
		default: {
			NSLog(@"Windows fucking error!");
			return nil;
		}
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(WINDOW_FRAME.size.width - 40, WINDOW_FRAME.size.height/8.0f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		return self.titleTrackCollection.count;
	}
	return self.trackCollections.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"trackPickerCellIdentifier" forIndexPath:indexPath];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMListEntry *listEntry = [self.listEntryArray objectAtIndex:indexPath.row];
	listEntry.collectionIndex = indexPath.row;
	[cell.contentView addSubview:listEntry];
	[listEntry autoPinEdgesToSuperviewEdges];
	
	if(indexPath.row < [self collectionView:self.collectionView numberOfItemsInSection:0]-1){
		UIView *lineView = [UIView newAutoLayoutView];
		lineView.backgroundColor = [LMColour controlBarGrayColour];
		[cell addSubview:lineView];
		
		[lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:listEntry withOffset:[self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout minimumLineSpacingForSectionAtIndex:0]/2.0f];
		[lineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:listEntry];
		[lineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:listEntry];
		[lineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	}
	
//	cell.backgroundColor = [LMColour randomColour];
	
	return cell;
}

- (void)saveSongSelection {
	NSLog(@"Done");
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	if(!self.trackCollections){
		self.trackCollections = [self.musicPlayer queryCollectionsForMusicType:self.musicType];
	}
	
	
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"trackPickerCellIdentifier"];
	[self.view addSubview:self.collectionView];
	
	self.collectionView.backgroundColor = [UIColor whiteColor];
	[self.collectionView autoPinEdgesToSuperviewEdges];
	
	
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
//		listEntry.iconInsetMultiplier = (1.0/3.0);
//		listEntry.iconPaddingMultiplier = (3.0/4.0);
		listEntry.invertIconOnHighlight = YES;
		listEntry.stretchAcrossWidth = YES;
		listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
		
		[self.listEntryArray addObject:listEntry];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
