//
//  LMTrackPickerController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "MBProgressHUD.h"
#import "LMTrackPickerController.h"
#import "LMColour.h"
#import "LMListEntry.h"
#import "LMCircleView.h"
#import "LMLetterTabBar.h"
#import "NSTimer+Blocks.h"
#import "LMPlaylist.h"

@interface LMTrackPickerController ()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate, LMLayoutChangeDelegate, UISearchBarDelegate, LMLetterTabDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The search bar.
 */
@property UISearchBar *searchBar;

/**
 The collection view that will display the contents provided.
 */
@property UICollectionView *collectionView;

/**
 The array of list entries which go on the collection view.
 */
@property NSMutableArray<LMListEntry*> *listEntryArray;

/**
 The track collections that the are the result of the user's search result, nil if no search is taking place.
 */
@property NSArray<LMMusicTrackCollection*> *searchResultTrackCollections;

/**
 The letter tab bar.
 */
@property LMLetterTabBar *letterTabBar;

/**
 The "Select all" list entry that goes at the top of and track picker with a depthLevel of LMTrackPickerDepthLevelSongs.
 */
@property LMListEntry *selectAllListEntry;

/**
 Whether or not this is the song depth, basically.
 */
@property (readonly) BOOL entriesAreSelectable;

/**
 Whether or not all tracks in the picker are selected.
 */
@property (readonly) BOOL allEntriesSelected;

/**
 The loading progress HUD for time consuming tasks.
 */
@property MBProgressHUD *loadingProgressHUD;

/**
 The label for when there's no songs.
 */
@property UILabel *noSongsInSongTableViewLabel;

@end

@implementation LMTrackPickerController

@synthesize entriesAreSelectable = _entriesAreSelectable;
@synthesize selectedTrackCollections = _selectedTrackCollections;
@synthesize displayingTrackCollections = _displayingTrackCollections;

- (BOOL)isSearching {
	return (self.searchResultTrackCollections != nil);
}

- (NSArray<LMMusicTrackCollection*>*)displayingTrackCollections {
	if(!self.isSearching){
		return self.trackCollections;
	}
	return self.searchResultTrackCollections;
}

- (NSArray<LMMusicTrackCollection*>*)selectedTrackCollections {
	return self.sourceMusicPickerController.trackCollections;
}

- (BOOL)entriesAreSelectable {
	return (self.depthLevel == LMTrackPickerDepthLevelSongs) || (self.selectionMode == LMMusicPickerSelectionModeAllCollections);
}

- (BOOL)allEntriesSelected {
	for(NSInteger i = 0; i < self.displayingTrackCollections.count; i++){
		LMMusicTrackCollection *trackCollection = [self.displayingTrackCollections objectAtIndex:i];
		if(![self trackCollectionIsSelected:trackCollection]){
			return NO;
		}
	}
	return YES;
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %p", entry);
	
	if(self.selectAllListEntry && entry == self.selectAllListEntry){
		NSLog(@"Select all");
		
		BOOL allEntriesSelected = self.allEntriesSelected;
		
		self.loadingProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		
		self.loadingProgressHUD.mode = MBProgressHUDModeIndeterminate;
		self.loadingProgressHUD.label.text = NSLocalizedString(allEntriesSelected ? @"DeselectingAll" : @"SelectingAll", nil);
		self.loadingProgressHUD.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
		self.loadingProgressHUD.userInteractionEnabled = NO;

		__weak id weakSelf = self;
		
		dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInitiated, 0), ^{
			id strongSelf = weakSelf;
			
			if(!strongSelf){
				return;
			}
			
			LMTrackPickerController *trackPicker = strongSelf;
			
			BOOL allEntriesSelected = trackPicker.allEntriesSelected;
			
			for(NSInteger i = 0; i < trackPicker.displayingTrackCollections.count; i++){
				LMMusicTrackCollection *trackCollection = [trackPicker.displayingTrackCollections objectAtIndex:i];
				
				[trackPicker.sourceMusicPickerController setCollection:trackCollection asSelected:!allEntriesSelected forMusicType:trackPicker.musicType];
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				for(NSInteger i = 0; i < trackPicker.displayingTrackCollections.count; i++){
					LMListEntry *songEntry = [trackPicker.listEntryArray objectAtIndex:i];
					
					[songEntry reloadContents];
				}
				
				[trackPicker.selectAllListEntry reloadContents];
				
				[self.loadingProgressHUD hideAnimated:YES afterDelay:0.0f];
			});
		});

		return;
	}

	if(self.entriesAreSelectable){
		NSLog(@"Pick song");

		LMMusicTrackCollection *trackCollection = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable];

		[self.sourceMusicPickerController setCollection:trackCollection asSelected:![self trackCollectionIsSelected:trackCollection] forMusicType:self.musicType];

		[entry reloadContents];

		[self.selectAllListEntry reloadContents];
		return;
	}
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	NSString *title = nil;
	
	LMMusicTrack *representativeItem = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable].representativeItem;
	NSLog(@"Representative %@", representativeItem.albumTitle);
	NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer collectionsForRepresentativeTrack:representativeItem forMusicType:self.musicType];
	
	if(self.depthLevel == LMTrackPickerDepthLevelAlbums){
		trackCollections = @[ [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable] ];
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
	trackPickerController.sourceMusicPickerController = self.sourceMusicPickerController;
	
	[self showViewController:trackPickerController sender:nil];
}

- (UIView*)checkmarkViewSelected:(BOOL)selected {
	UIView *checkmarkPaddedView = [UIView newAutoLayoutView];
	
	LMCircleView *checkmarkView = [LMCircleView newAutoLayoutView];
	checkmarkView.backgroundColor = selected ? [LMColour mainColour] : [LMColour lightGrayBackgroundColour];
	
	[checkmarkPaddedView addSubview:checkmarkView];
	
	
	[checkmarkView autoCentreInSuperview];
	[checkmarkView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
	[checkmarkView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
	
	
	LMCircleView *checkmarkFillView = [LMCircleView newAutoLayoutView];
	checkmarkFillView.backgroundColor = selected ? [LMColour mainColour] : [UIColor whiteColor];
	
	[checkmarkView addSubview:checkmarkFillView];
	
	[checkmarkFillView autoCentreInSuperview];
	[checkmarkFillView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(9.0/10.0)];
	[checkmarkFillView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:checkmarkView withMultiplier:(9.0/10.0)];
	
	
	UIImageView *checkmarkImageView = [UIImageView newAutoLayoutView];
	checkmarkImageView.contentMode = UIViewContentModeScaleAspectFit;
	checkmarkImageView.image = [LMAppIcon imageForIcon:LMIconWhiteCheckmark];
	[checkmarkView addSubview:checkmarkImageView];
	
	[checkmarkImageView autoCentreInSuperview];
	[checkmarkImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
	[checkmarkImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
	
	return checkmarkPaddedView;
}

- (UIView*)arrowView {
	UIView *arrowIconPaddedView = [UIView newAutoLayoutView];
	
	UIImageView *arrowIconView = [UIImageView newAutoLayoutView];
	arrowIconView.contentMode = UIViewContentModeScaleAspectFit;
	arrowIconView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
	
	[arrowIconPaddedView addSubview:arrowIconView];
	
	[arrowIconView autoCentreInSuperview];
	[arrowIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:arrowIconPaddedView withMultiplier:(2.0/8.0)];
	[arrowIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:arrowIconPaddedView];
	
	return arrowIconView;
}

- (BOOL)trackCollectionIsSelected:(LMMusicTrackCollection*)trackCollection {
	for(LMMusicTrackCollection *selectedTrackCollection in self.selectedTrackCollections){
		NSLog(@"Collection count %d %lld", (int)trackCollection.count, trackCollection.representativeItem.genrePersistentID);
		if([LMMusicPlayer trackCollection:trackCollection isEqualToOtherTrackCollection:selectedTrackCollection]){
			return YES;
		}
	}
	
	return NO;
}

- (UIView*)rightViewForListEntry:(LMListEntry *)entry {

	if(self.entriesAreSelectable){
		BOOL selected = NO;
		if(entry.collectionIndex == -1){
			selected = self.allEntriesSelected;
		}
		else{
			selected = [self trackCollectionIsSelected:[self.displayingTrackCollections objectAtIndex:entry.collectionIndex-1]];
		}
		
		return [self checkmarkViewSelected:selected];
	}
	
	return [self arrowView];

//		case LMMusicPickerSelectionModeAllCollections:{
//			BOOL selected = NO;
//			if(entry.collectionIndex == -1){
//				selected = self.allEntriesSelected;
//			}
//			else{
//				selected = [self.selectedTrackCollections containsObject:[self.displayingTrackCollections objectAtIndex:entry.collectionIndex]];
//			}
//
//			return [self checkmarkViewSelected:selected];

}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour mainColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	if(self.selectAllListEntry && entry.collectionIndex == -1){
		return NSLocalizedString(self.allEntriesSelected ? @"DeselectAll" : @"SelectAll", nil);
	}
	
	LMMusicTrackCollection *collection = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return collection.representativeItem.title;
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
	if(self.selectAllListEntry && entry.collectionIndex == -1){
		return nil;
	}
	
	LMMusicTrackCollection *collection = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return collection.representativeItem.artist;
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
	if(self.selectAllListEntry && entry.collectionIndex == -1){
		return nil;
	}
	
	LMMusicTrackCollection *collection = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex-self.entriesAreSelectable];
	
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
			if(self.displayingTrackCollections.count == 0){
				return nil;
			}
			return collection.representativeItem.albumArt;
		default: {
			NSLog(@"Windows fucking error!");
			return nil;
		}
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat height = LMLayoutManager.standardListEntryHeight;
	
	CGSize size = CGSizeMake(WINDOW_FRAME.size.width - 40, height);
	
	if([LMLayoutManager isLandscape]){
		size.width -= 40.0f;
	}
	
	return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if(self.selectAllListEntry){
		return self.displayingTrackCollections.count + 1;
	}
	return self.displayingTrackCollections.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"trackPickerCellIdentifier" forIndexPath:indexPath];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMListEntry *listEntry = nil;
	if(self.selectAllListEntry && indexPath.row == 0){
		listEntry = self.selectAllListEntry;
		listEntry.collectionIndex = -1;
		[cell.contentView addSubview:listEntry];
		[listEntry autoPinEdgesToSuperviewEdges];
	}
	else{
		listEntry = [self.listEntryArray objectAtIndex:indexPath.row-self.entriesAreSelectable];
		listEntry.collectionIndex = indexPath.row;
		[cell.contentView addSubview:listEntry];
		[listEntry autoPinEdgesToSuperviewEdges];
	}
	
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	NSLog(@"Changed to '%@'", searchText);
	
	if([searchText isEqualToString:@""]){
		self.searchResultTrackCollections = nil;
		
		[self.collectionView reloadData];
		
		self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.trackCollections withAssociatedMusicType:self.musicType];
		
		for(LMListEntry *listEntry in self.listEntryArray){
			[listEntry reloadContents];
		}
		
		[self.selectAllListEntry reloadContents];
		[self reloadNoSongsLabel];
		return;
	}
	
	NSString *searchProperty = MPMediaItemPropertyTitle;
	
	switch(self.depthLevel){
		case LMTrackPickerDepthLevelSongs:
			searchProperty = MPMediaItemPropertyTitle;
			break;
		case LMTrackPickerDepthLevelAlbums:
			searchProperty = MPMediaItemPropertyAlbumTitle;
			break;
		case LMTrackPickerDepthLevelArtists:
			searchProperty = MPMediaItemPropertyArtist;
			break;
	}
	
	NSMutableArray *searchResultsMutableArray = [NSMutableArray new];

	for(LMMusicTrackCollection *collection in self.trackCollections){
		NSString *trackValue = [collection.representativeItem valueForProperty:searchProperty];
		if([trackValue.lowercaseString containsString:searchText.lowercaseString]){
			[searchResultsMutableArray addObject:collection];
		}
		else if(self.depthLevel != LMTrackPickerDepthLevelArtists){
			NSString *trackArtistValue = [collection.representativeItem valueForProperty:MPMediaItemPropertyArtist];
			if([trackArtistValue.lowercaseString containsString:searchText.lowercaseString]){
				[searchResultsMutableArray addObject:collection];
			}
		}
	}
	
	self.searchResultTrackCollections = [NSArray arrayWithArray:searchResultsMutableArray];
	
	NSLog(@"%d results.", (int)searchResultsMutableArray.count);
	
	NSArray *fixedTrackCollectionsArray = self.displayingTrackCollections;
	
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		fixedTrackCollectionsArray = @[ [LMMusicPlayer trackCollectionForArrayOfTrackCollections:self.displayingTrackCollections] ];
	}
	
	self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:
										   fixedTrackCollectionsArray
																						   withAssociatedMusicType:self.musicType];
	
	for(NSInteger i = 0; i < searchResultsMutableArray.count; i++){
		[[self.listEntryArray objectAtIndex:i] reloadContents];
	}
	
	[self.selectAllListEntry reloadContents];
	
	[self.collectionView reloadData];
	
	[self reloadNoSongsLabel];
}

- (void)letterSelected:(NSString*)letter atIndex:(NSUInteger)index {
	NSLog(@"Letter selected: %@/%lu", letter, index);
	
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
}

- (void)swipeDownGestureOccurredOnLetterTabBar { } //Nothing, for now

- (void)reloadNoSongsLabel {
	self.noSongsInSongTableViewLabel.hidden = self.displayingTrackCollections.count > 0;
	self.collectionView.hidden = self.displayingTrackCollections.count == 0;
}

- (void)saveSongSelection {
	NSLog(@"Done");
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.sourceMusicPickerController saveSongSelection];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
	}];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	[self.searchBar resignFirstResponder];
}

- (void)focusEntryAtRow:(NSUInteger)row {
	UIView *cellSubview = [self.listEntryArray objectAtIndex:row];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^() {
		[UIView animateWithDuration:0.75 animations:^{
			cellSubview.backgroundColor = [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:0.15];
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.75 animations:^{
				cellSubview.backgroundColor = [UIColor whiteColor];
			}];
		}];
	} repeats:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	if(!self.trackCollections){
		if(self.musicType == LMMusicTypeTitles){
			MPMediaQuery *everything = [MPMediaQuery new];
			MPMediaPropertyPredicate *musicFilterPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic]
																							  forProperty:MPMediaItemPropertyMediaType
																						   comparisonType:MPMediaPredicateComparisonEqualTo];
			[everything addFilterPredicate:musicFilterPredicate];
			
			NSMutableArray *musicCollection = [[NSMutableArray alloc]initWithArray:[everything items]];
			
			NSString *sortKey = @"title";
			NSSortDescriptor *albumSort = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
			musicCollection = [NSMutableArray arrayWithArray:[musicCollection sortedArrayUsingDescriptors:@[albumSort]]];
			
			self.trackCollections = @[[MPMediaItemCollection collectionWithItems:[NSArray arrayWithArray:musicCollection]]];
		}
		else{
			self.trackCollections = [self.musicPlayer queryCollectionsForMusicType:self.musicType];
		}
	}
	
	//Reorganize bunched up tracks in one collection into an array of collections
	if(self.depthLevel == LMTrackPickerDepthLevelSongs && self.trackCollections.count == 1){
		self.trackCollections = [LMMusicPlayer arrayOfTrackCollectionsForMusicTrackCollection:self.trackCollections.firstObject];
	}
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	

	
	
	
	self.searchBar = [UISearchBar newAutoLayoutView];
	self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"SearchType", nil), self.title];
	self.searchBar.delegate = self;
	[self.view addSubview:self.searchBar];
	
	NSArray *searchBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	}];
	[LMLayoutManager addNewPortraitConstraints:searchBarPortraitConstraints];
	
	NSArray *searchBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.searchBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.letterTabBar];
	}];
	[LMLayoutManager addNewLandscapeConstraints:searchBarLandscapeConstraints];
	
	if(@available(iOS 11, *)){
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.searchBar
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.view.safeAreaLayoutGuide
															  attribute:NSLayoutAttributeTop
															 multiplier:1.0f
															   constant:0.0f]];
	}
	else{
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.searchBar
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.topLayoutGuide
															  attribute:NSLayoutAttributeBottom
															 multiplier:1.0f
															   constant:0.0f]];
	}
	
	
	UIView *iPhoneXBottomCoverView = nil;
	if([LMLayoutManager isiPhoneX]){
		iPhoneXBottomCoverView = [UIView newAutoLayoutView];
		iPhoneXBottomCoverView.backgroundColor = [LMColour whiteColour];
		[self.view addSubview:iPhoneXBottomCoverView];
		
		
		[iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		NSArray *buttonNavigationBarBottomCoverViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[iPhoneXBottomCoverView autoSetDimension:ALDimensionHeight toSize:22.0f];
		}];
		[LMLayoutManager addNewPortraitConstraints:buttonNavigationBarBottomCoverViewPortraitConstraints];
		
		NSArray *buttonNavigationBarBottomCoverViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[iPhoneXBottomCoverView autoSetDimension:ALDimensionHeight toSize:0];
		}];
		[LMLayoutManager addNewLandscapeConstraints:buttonNavigationBarBottomCoverViewLandscapeConstraints];
	}
	
	
	self.letterTabBar = [LMLetterTabBar new];
	self.letterTabBar.delegate = self;
	self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.trackCollections withAssociatedMusicType:self.musicType];
	[self.view addSubview:self.letterTabBar];
	
	NSArray *letterTabBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.letterTabBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:iPhoneXBottomCoverView];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:[LMLayoutManager isiPhoneX] ? (1.0/20.0) : (1.0/15.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:letterTabBarPortraitConstraints];
	
	NSArray *letterTabBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:[LMLayoutManager isiPhoneX] ? (1.0/20.0) : (1.0/15.0)];
		[self.letterTabBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.searchBar withOffset:64];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}];
	[LMLayoutManager addNewLandscapeConstraints:letterTabBarLandscapeConstraints];
	
	

	
	
	if(self.entriesAreSelectable){
		self.selectAllListEntry = [LMListEntry new];
		self.selectAllListEntry.delegate = self;
		self.selectAllListEntry.collectionIndex = -1;
		self.selectAllListEntry.invertIconOnHighlight = YES;
		self.selectAllListEntry.roundedCorners = NO;
		self.selectAllListEntry.stretchAcrossWidth = YES;
		self.selectAllListEntry.alignIconToLeft = YES;
	}
	
	
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.contentInset = UIEdgeInsetsMake(20, 10, 20, 10);
	self.collectionView.allowsSelection = NO;
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"trackPickerCellIdentifier"];
	[self.view addSubview:self.collectionView];
	
	self.collectionView.backgroundColor = [UIColor whiteColor];
	NSArray *collectionViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.collectionView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.letterTabBar];
		[self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar];
	}];
	[LMLayoutManager addNewPortraitConstraints:collectionViewPortraitConstraints];
	
	NSArray *collectionViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		if([LMLayoutManager isiPhoneX]){
			[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		}
		else{
			[self.collectionView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		}
		[self.collectionView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.letterTabBar];
	}];
	[LMLayoutManager addNewLandscapeConstraints:collectionViewLandscapeConstraints];
	
	
	[self.view bringSubviewToFront:self.letterTabBar];
	
	
	NSLog(@"%d", self.entriesAreSelectable);
	
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = self.entriesAreSelectable ? 1 : 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
//		listEntry.iconInsetMultiplier = (1.0/3.0);
//		listEntry.iconPaddingMultiplier = (3.0/4.0);
		listEntry.invertIconOnHighlight = YES;
		listEntry.stretchAcrossWidth = YES;
		listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
		listEntry.alignIconToLeft = YES;
		listEntry.roundedCorners = YES;
		
		[self.listEntryArray addObject:listEntry];
	}
	
	
	self.noSongsInSongTableViewLabel = [UILabel newAutoLayoutView];
	self.noSongsInSongTableViewLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 16.0f : 18.0f];
	self.noSongsInSongTableViewLabel.text = NSLocalizedString(@"TheresNothingHere", nil);
	self.noSongsInSongTableViewLabel.textColor = [UIColor blackColor];
	self.noSongsInSongTableViewLabel.hidden = self.displayingTrackCollections.count > 0;
	self.noSongsInSongTableViewLabel.textAlignment = NSTextAlignmentLeft;
	self.noSongsInSongTableViewLabel.numberOfLines = 0;
	self.noSongsInSongTableViewLabel.userInteractionEnabled = YES;
	self.noSongsInSongTableViewLabel.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.noSongsInSongTableViewLabel];
	
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
//	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.noSongsInSongTableViewLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar withOffset:20];
	
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		if(self.highlightedData){
			switch(self.musicType){
				case LMMusicTypePlaylists:{
//					LMPlaylist *playlist = (LMPlaylist*)self.highlightedData;
					NSAssert(false, @"Playlists are not supported in the track picker, sorry.");
					break;
				}
				case LMMusicTypeFavourites:
				case LMMusicTypeTitles:{
					LMMusicTrack *musicTrack = (LMMusicTrack*)self.highlightedData;
					
					NSInteger index = NSNotFound;
					
					for(NSInteger i = 0; i < self.displayingTrackCollections.count; i++){
						LMMusicTrack *titleTrack = [self.displayingTrackCollections objectAtIndex:i].representativeItem;
						if(titleTrack.persistentID == musicTrack.persistentID){
							index = i;
							break;
						}
					}
					
					if(index != NSNotFound){
						[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
						
						[self focusEntryAtRow:index];
					}
					
					break;
				}
				case LMMusicTypeArtists:
				case LMMusicTypeCompilations:
				case LMMusicTypeGenres:
				case LMMusicTypeAlbums:
				case LMMusicTypeComposers:{
					LMMusicTrackCollection *dataTrackCollection = (LMMusicTrackCollection*)self.highlightedData;
					
					NSInteger index = NSNotFound;
					
					for(NSInteger i = 0; i < self.trackCollections.count; i++){
						LMMusicTrackCollection *collection = [self.trackCollections objectAtIndex:i];
						LMMusicTrack *representativeTrack = collection.representativeItem;
						
						NSString *property = nil;
						switch(self.musicType){
							case LMMusicTypeArtists:
								property = MPMediaItemPropertyAlbumArtistPersistentID;
								break;
							case LMMusicTypeGenres:
								property = MPMediaItemPropertyGenrePersistentID;
								break;
							case LMMusicTypeComposers:
								property = MPMediaItemPropertyComposerPersistentID;
								break;
							case LMMusicTypeCompilations:
							case LMMusicTypeAlbums:
							default:
								property = MPMediaItemPropertyAlbumPersistentID;
								break;
						}
						
						MPMediaEntityPersistentID dataPersistentID = [[dataTrackCollection.representativeItem valueForProperty:property] unsignedLongLongValue];
						
						MPMediaEntityPersistentID trackPersistentID = [[representativeTrack valueForProperty:property] unsignedLongLongValue];
						
						if(dataPersistentID == trackPersistentID){
							index = i;
							break;
						}
					}
					
					if(index != NSNotFound){
						[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
						
						[self focusEntryAtRow:index];
					}
					
					break;
				}
			}
		}
	} repeats:NO];
	
	[self reloadNoSongsLabel];
	
	[self.view bringSubviewToFront:self.searchBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.selectionMode = LMMusicPickerSelectionModeOnlyTracks;		
	}
	return self;
}

@end
