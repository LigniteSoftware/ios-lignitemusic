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
#import "LMCircleView.h"
#import "LMLetterTabBar.h"

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
 The title collections that the are the result of the user's search result, nil if no search is taking place.
 */
@property LMMusicTrackCollection *searchResultTitleTrackCollection;

/**
 The letter tab bar.
 */
@property LMLetterTabBar *letterTabBar;

@end

@implementation LMTrackPickerController

@synthesize titleTrackCollection = _titleTrackCollection;
@synthesize selectedTrackCollection = _selectedTrackCollection;
@synthesize displayingTrackCollections = _displayingTrackCollections;
@synthesize displayingTitleTrackCollection = _displayingTitleTrackCollection;

- (BOOL)isSearching {
	return (self.searchResultTitleTrackCollection || self.searchResultTrackCollections);
}

- (NSArray<LMMusicTrackCollection*>*)displayingTrackCollections {
	if(!self.isSearching){
		return self.trackCollections;
	}
	return self.searchResultTrackCollections;
}

- (LMMusicTrackCollection*)displayingTitleTrackCollection {
	if(!self.isSearching){
		return self.titleTrackCollection;
	}
	return self.searchResultTitleTrackCollection;
}

- (LMMusicTrackCollection*)titleTrackCollection {
	if(self.trackCollections.count > 0){
		return [self.trackCollections objectAtIndex:0];
	}
	return nil;
}

- (LMMusicTrackCollection*)selectedTrackCollection {
	return self.sourceMusicPickerController.trackCollection;
}

- (void)tappedListEntry:(LMListEntry*)entry{
	NSLog(@"Tapped %p", entry);
	
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		NSLog(@"Pick song");
		
		LMMusicTrack *track = [self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex];
		
		[self.sourceMusicPickerController setTrack:track asSelected:![self.selectedTrackCollection.items containsObject:track]];
		
		[entry reloadContents];
		return;
	}
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	NSString *title = nil;
	
	LMMusicTrack *representativeItem = [self.displayingTrackCollections objectAtIndex:entry.collectionIndex].representativeItem;
	NSLog(@"Representative %@", representativeItem.albumTitle);
	NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer collectionsForRepresentativeTrack:representativeItem forMusicType:self.musicType];
	
	if(self.depthLevel == LMTrackPickerDepthLevelAlbums){
		trackCollections = @[ [self.displayingTrackCollections objectAtIndex:entry.collectionIndex] ];
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

- (UIView*)rightViewForListEntry:(LMListEntry *)entry {
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		UIView *checkmarkPaddedView = [UIView newAutoLayoutView];
		
		LMCircleView *checkmarkView = [LMCircleView newAutoLayoutView];
		checkmarkView.backgroundColor = [self.selectedTrackCollection.items containsObject:[self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex]] ? [LMColour ligniteRedColour] : [LMColour lightGrayBackgroundColour];
		
		[checkmarkPaddedView addSubview:checkmarkView];
		
		
		[checkmarkView autoCenterInSuperview];
		[checkmarkView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
		[checkmarkView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkPaddedView withMultiplier:(3.0/4.0)];
		
		
		LMCircleView *checkmarkFillView = [LMCircleView newAutoLayoutView];
		checkmarkFillView.backgroundColor = [self.selectedTrackCollection.items containsObject:[self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex]] ? [LMColour ligniteRedColour] : [UIColor whiteColor];
		
		[checkmarkView addSubview:checkmarkFillView];
		
		[checkmarkFillView autoCenterInSuperview];
		[checkmarkFillView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(9.0/10.0)];
		[checkmarkFillView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:checkmarkView withMultiplier:(9.0/10.0)];
		
		
		UIImageView *checkmarkImageView = [UIImageView newAutoLayoutView];
		checkmarkImageView.contentMode = UIViewContentModeScaleAspectFit;
		checkmarkImageView.image = [LMAppIcon imageForIcon:LMIconWhiteCheckmark];
		[checkmarkView addSubview:checkmarkImageView];
		
		[checkmarkImageView autoCenterInSuperview];
		[checkmarkImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
		[checkmarkImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:checkmarkView withMultiplier:(3.0/8.0)];
		
		return checkmarkPaddedView;
	}
	
	UIView *arrowIconPaddedView = [UIView newAutoLayoutView];
	
	UIImageView *arrowIconView = [UIImageView newAutoLayoutView];
	arrowIconView.contentMode = UIViewContentModeScaleAspectFit;
	arrowIconView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
	
	[arrowIconPaddedView addSubview:arrowIconView];
	
	[arrowIconView autoCenterInSuperview];
	[arrowIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:arrowIconPaddedView withMultiplier:(5.0/8.0)];
	[arrowIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:arrowIconPaddedView];
	
	return arrowIconPaddedView;
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.displayingTrackCollections objectAtIndex:entry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return [self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex].title;
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
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.displayingTrackCollections objectAtIndex:entry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return [self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex].artist;
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
	LMMusicTrackCollection *collection = (self.depthLevel == LMTrackPickerDepthLevelSongs) ? nil : [self.displayingTrackCollections objectAtIndex:entry.collectionIndex];
	
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
			if(self.displayingTitleTrackCollection.count == 0){
				return nil;
			}
			return [self.displayingTitleTrackCollection.items objectAtIndex:entry.collectionIndex].albumArt;
		default: {
			NSLog(@"Windows fucking error!");
			return nil;
		}
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat height = 0.0;
	
	if([LMLayoutManager isiPad]){
		height = ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/10.0f;
	}
	else{
		height = ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/9.0f;
	}
	
	return CGSizeMake(WINDOW_FRAME.size.width - 40, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		return self.displayingTitleTrackCollection.count;
	}
	return self.displayingTrackCollections.count;
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
		self.searchResultTitleTrackCollection = nil;
		
		[self.collectionView reloadData];
		
		self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.trackCollections withAssociatedMusicType:self.musicType];
		
		for(LMListEntry *listEntry in self.listEntryArray){
			[listEntry reloadContents];
		}
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
	if(self.depthLevel == LMTrackPickerDepthLevelSongs){
		for(LMMusicTrack *track in self.titleTrackCollection.items){
			NSString *trackArtistValue = [track valueForProperty:MPMediaItemPropertyArtist];
			NSString *trackValue = [track valueForProperty:searchProperty];
			if([trackValue.lowercaseString containsString:searchText.lowercaseString]){
				[searchResultsMutableArray addObject:track];
			}
			else if([trackArtistValue.lowercaseString containsString:searchText.lowercaseString]){
				[searchResultsMutableArray addObject:track];
			}
		}
		
		self.searchResultTitleTrackCollection = [[LMMusicTrackCollection alloc]initWithItems:[NSArray arrayWithArray:searchResultsMutableArray]];
		
		NSLog(@"%d results.", (int)searchResultsMutableArray.count);
	}
	else{
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
	}
	
	self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:
										   self.musicType == LMMusicTypeTitles
										   ? @[self.displayingTitleTrackCollection]
										  : self.displayingTrackCollections
									   
																						   withAssociatedMusicType:self.musicType];
	
	for(NSInteger i = 0; i < searchResultsMutableArray.count; i++){
		[[self.listEntryArray objectAtIndex:i] reloadContents];
	}
	
	[self.collectionView reloadData];
}

- (void)letterSelected:(NSString*)letter atIndex:(NSUInteger)index {
	NSLog(@"Letter selected: %@/%lu", letter, index);
	
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
}

- (void)swipeDownGestureOccurredOnLetterTabBar { } //Nothing, for now

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
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	self.searchBar = [UISearchBar newAutoLayoutView];
	self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"SearchType", nil), self.title];
	self.searchBar.delegate = self;
	[self.view addSubview:self.searchBar];
	
	NSArray *searchBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
	}];
	[LMLayoutManager addNewPortraitConstraints:searchBarPortraitConstraints];
	
	NSArray *searchBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44];
	}];
	[LMLayoutManager addNewLandscapeConstraints:searchBarLandscapeConstraints];
	
	self.letterTabBar = [LMLetterTabBar new];
	self.letterTabBar.delegate = self;
	self.letterTabBar.lettersDictionary = [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.trackCollections withAssociatedMusicType:self.musicType];
	[self.view addSubview:self.letterTabBar];
	
	NSArray *letterTabBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/15.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:letterTabBarPortraitConstraints];
	
	NSArray *letterTabBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/15.0)];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}];
	[LMLayoutManager addNewLandscapeConstraints:letterTabBarLandscapeConstraints];
	
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
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
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.letterTabBar];
	}];
	[LMLayoutManager addNewLandscapeConstraints:collectionViewLandscapeConstraints];
	
	
	[self.view bringSubviewToFront:self.letterTabBar];
	
	
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
//		listEntry.iconInsetMultiplier = (1.0/3.0);
//		listEntry.iconPaddingMultiplier = (3.0/4.0);
		listEntry.invertIconOnHighlight = YES;
//		listEntry.stretchAcrossWidth = YES;
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
