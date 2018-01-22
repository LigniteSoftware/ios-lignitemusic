//
//  LMMusicPickerController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMusicPickerController.h"
#import "LMSourceSelectorView.h"
#import "LMTrackPickerController.h"
#import "LMDynamicSearchView.h"
#import "LMPlaylist.h"
#import "LMCoreNavigationController.h"

@interface LMMusicPickerController ()<LMSourceDelegate, UISearchBarDelegate, LMDynamicSearchViewDelegate, LMSourceSelectorDelegate, UIViewControllerRestoration>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The view selector for the user to choose which view they want to take music from.
 */
@property LMSourceSelectorView *viewSelector;

/**
 The search bar that allows the user to search their whole library.
 */
@property UISearchBar *searchBar;

/**
 The search view which shows the results of any search through the user's input on the searchBar.
 */
@property LMDynamicSearchView *searchView;

/**
 The bottom constraint of the search view for keyboard adjustments.
 */
@property NSLayoutConstraint *searchViewBottomConstraint;

@end

@implementation LMMusicPickerController

- (BOOL)trackCollectionIsSelected:(LMMusicTrackCollection*)trackCollection {
	for(LMMusicTrackCollection *selectedTrackCollection in self.trackCollections){
		if([LMMusicPlayer trackCollection:trackCollection isEqualToOtherTrackCollection:selectedTrackCollection]){
			return YES;
		}
	}
	
	return NO;
}

- (void)setCollection:(LMMusicTrackCollection*)collection asSelected:(BOOL)selected forMusicType:(LMMusicType)musicType {
	NSMutableArray *mutableTrackCollections = [[NSMutableArray alloc] initWithArray:self.trackCollections];
	NSMutableArray *mutableMusicTypes = [[NSMutableArray alloc] initWithArray:self.musicTypes];
	
	if(musicType == LMMusicTypeFavourites){
		musicType = LMMusicTypeTitles;
	}
	
	if(selected){
		if(![self trackCollectionIsSelected:collection]){ //Prevent collection from being added more than once
			[mutableTrackCollections addObject:collection];
			if(self.selectionMode == LMMusicPickerSelectionModeAllCollections){
				[mutableMusicTypes addObject:@(musicType)];
			}
		}
	}
	else{
		NSInteger indexToRemove = NSNotFound;
		
		for(NSInteger i = 0; i < mutableTrackCollections.count; i++){
			LMMusicTrackCollection *trackCollection = [mutableTrackCollections objectAtIndex:i];
			LMMusicType trackCollectionMusicType = LMMusicTypeTitles;
			
			if(self.selectionMode == LMMusicPickerSelectionModeAllCollections){ //Normal playlists don't keep track of music types
				trackCollectionMusicType = (LMMusicType)[[mutableMusicTypes objectAtIndex:i] integerValue];
			}
			
			NSLog(@"%@ and %d", trackCollection.representativeItem.albumTitle, (int)trackCollectionMusicType);
			
			if(trackCollectionMusicType == LMMusicTypeFavourites){
				trackCollectionMusicType = LMMusicTypeTitles;
			}
			
			if([LMMusicPlayer trackCollection:trackCollection isEqualToOtherTrackCollection:collection]
			   && trackCollectionMusicType == musicType){
				
				indexToRemove = i;
				break;
			}
		}
		
		if(indexToRemove != NSNotFound){
			[mutableTrackCollections removeObjectAtIndex:indexToRemove];
			if(self.selectionMode == LMMusicPickerSelectionModeAllCollections){
				[mutableMusicTypes removeObjectAtIndex:indexToRemove];
			}
		}
	}
	
	self.trackCollections = [NSArray arrayWithArray:mutableTrackCollections];
	self.musicTypes = [NSArray arrayWithArray:mutableMusicTypes];
}

- (void)sourceSelected:(LMSource*)source {
	NSLog(@"Source selected %@", source.title);
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	switch(source.sourceID){
		case LMIconFavouriteBlackFilled:{
			trackPickerController.musicType = LMMusicTypeFavourites;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			break;
		}
		case LMIconArtists:{
			trackPickerController.musicType = LMMusicTypeArtists;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelArtists;
			break;
		}
		case LMIconAlbums:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			break;
		}
		case LMIconTitles:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			break;
		}
		case LMIconGenres:{
			trackPickerController.musicType = LMMusicTypeGenres;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelArtists;
			break;
		}
		case LMIconCompilations:{
			trackPickerController.musicType = LMMusicTypeCompilations;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			break;
		}
	}
	
	trackPickerController.title = source.title;
	trackPickerController.sourceMusicPickerController = self;
	trackPickerController.selectionMode = self.selectionMode;
	
	[self showViewController:trackPickerController sender:nil];
}

- (void)cancelSongSelection {
	NSLog(@"Cancel song selection");
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if([self.delegate respondsToSelector:@selector(musicPickerDidCancelPickingMusic:)]){
		[self.delegate musicPickerDidCancelPickingMusic:self];
	}
}

- (void)saveSongSelection {
	NSLog(@"Save song selection");
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if([self.delegate respondsToSelector:@selector(musicPicker:didFinishPickingMusicWithTrackCollections:)]){
		[self.delegate musicPicker:self didFinishPickingMusicWithTrackCollections:self.trackCollections];
	}
}

- (void)searchView:(LMDynamicSearchView *)searchView entryWasSetAsSelected:(BOOL)selected withData:(id)musicData forMusicType:(LMMusicType)musicType {
	
	NSLog(@"Selected %d", selected);
	
	LMMusicTrackCollection *collection = (LMMusicTrackCollection*)musicData;
	if(self.trackCollections){
		[self setCollection:collection asSelected:selected forMusicType:musicType];
	}
}

- (void)searchViewEntryWasTappedWithData:(id)musicData forMusicType:(LMMusicType)musicType {
	LMMusicTrackCollection *collection = (LMMusicTrackCollection*)musicData;
	
	NSLog(@"Collection tapped with album %@", collection.representativeItem.albumTitle);
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer collectionsForRepresentativeTrack:collection.representativeItem forMusicType:musicType];
	
	switch(musicType){
		case LMMusicTypeFavourites:{
			trackPickerController.musicType = LMMusicTypeFavourites;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			trackPickerController.title = NSLocalizedString(@"Favourites", nil);
			break;
		}
		case LMMusicTypeArtists:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			trackPickerController.title = collection.representativeItem.artist;
			break;
		}
		case LMMusicTypeAlbums:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			trackPickerController.title = collection.representativeItem.albumTitle;
			break;
		}
		case LMMusicTypeTitles:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			trackPickerController.title = NSLocalizedString(@"Titles", nil);
			break;
		}
		case LMMusicTypeGenres:{
			trackPickerController.musicType = LMMusicTypeGenres;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelArtists;
			trackPickerController.title = collection.representativeItem.genre;
			break;
		}
		case LMMusicTypeCompilations:{
			trackPickerController.musicType = LMMusicTypeCompilations;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			trackPickerController.title = collection.representativeItem.albumTitle;
			break;
		}
		default:{
			NSAssert(false, @"This music type (%d) is not supported yet, sorry.", musicType);
			break;
		}
	}
	
	if(trackPickerController.depthLevel == LMTrackPickerDepthLevelSongs){
		trackPickerController.highlightedData = (LMMusicTrack*)collection.representativeItem;
	}
	trackPickerController.trackCollections = trackCollections;
	trackPickerController.sourceMusicPickerController = self;
	trackPickerController.selectionMode = self.selectionMode;
	trackPickerController.scrollableWithLetterTabs = NO;
	
	[self showViewController:trackPickerController sender:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	self.searchView.hidden = (!searchText || [searchText isEqualToString:@""]);
	
	if(!self.searchView.hidden){
		[self.searchView searchForString:searchText];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
}

- (void)searchViewWasInteractedWith:(LMDynamicSearchView *)searchView {
	[self.searchBar resignFirstResponder];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[self.searchBar resignFirstResponder];
}

- (void)sourceSelectorDidScroll:(LMSourceSelectorView *)sourceSelector {
	[self.searchBar resignFirstResponder];
}

- (void)adaptBottomConstraintForKeyboardWithNotification:(NSNotification*)notification hidden:(BOOL)keyboardHidden {
	NSDictionary *info  = notification.userInfo;
	NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	CGRect rawFrame = [value CGRectValue];
	CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
	
	CGFloat keyboardHeight = keyboardHidden ? 0.0f : keyboardFrame.size.height;
	
	[self.view layoutIfNeeded];
	
	self.searchViewBottomConstraint.constant = -keyboardHeight;
	
	[UIView animateWithDuration:0.4 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)keyboardWillHide:(NSNotification*)notification {
	[self adaptBottomConstraintForKeyboardWithNotification:notification hidden:YES];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	[self adaptBottomConstraintForKeyboardWithNotification:notification hidden:NO];
}

- (NSArray<NSArray<LMMusicTrackCollection*>*>*)searchableTrackCollectionsForSearchView:(LMDynamicSearchView*)searchView {
	return @[
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeFavourites],
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists],
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums],
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles],
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeGenres],
			 [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeCompilations]
			 ];
}

- (NSArray<NSNumber*>*)searchableMusicTypesForSearchView:(LMDynamicSearchView*)searchView {
	return @[
			 @(LMMusicTypeFavourites),
			 @(LMMusicTypeArtists),
			 @(LMMusicTypeAlbums),
			 @(LMMusicTypeTitles),
			 @(LMMusicTypeGenres),
			 @(LMMusicTypeCompilations)
			 ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Source", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelSongSelection)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	if(!self.trackCollections){
		self.trackCollections = @[];
	}
	
	if(self.trackCollections && !self.musicTypes){
		NSMutableArray *musicTypesMutableArray = [NSMutableArray new];
		for(NSInteger i = 0; i < self.trackCollections.count; i++){
			[musicTypesMutableArray addObject:@(LMMusicTypeTitles)];
		}
	}
	
	
	self.searchBar = [UISearchBar newAutoLayoutView];
	self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"SearchAllMusic", nil), self.title];
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
	
	
	NSArray *sourceTitles = @[
							  @"Favourites", @"Artists", @"Albums", @"Titles", @"Genres", @"Compilations"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"", @"", @"", @"", @"", @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconFavouriteBlackFilled, LMIconArtists, LMIconAlbums, LMIconTitles, LMIconGenres, LMIconCompilations
	};
	BOOL notHighlight[] = {
		NO, NO, NO, NO, NO, NO
	};
	
	
	NSMutableArray *sources = [NSMutableArray new];
	
	for(int i = 0; i < sourceTitles.count; i++){
		NSString *subtitle = [sourceSubtitles objectAtIndex:i];
		LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
										 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
											 andIcon:sourceIcons[i]];
		source.shouldNotHighlight = notHighlight[i];
		source.delegate = self;
		source.sourceID = sourceIcons[i];
		[sources addObject:source];
	}
	
	self.viewSelector = [LMSourceSelectorView newAutoLayoutView];
	self.viewSelector.backgroundColor = [UIColor redColor];
	self.viewSelector.sources = sources;
	self.viewSelector.delegate = self;
	[self.view addSubview:self.viewSelector];
	
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.viewSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar];
	
	[self.viewSelector setup];
	
	
	self.searchView = [LMDynamicSearchView newAutoLayoutView];
	self.searchView.delegate = self;
	switch(self.selectionMode){
		case LMMusicPickerSelectionModeOnlyTracks:
			self.searchView.selectionMode = LMSearchViewEntrySelectionModeTitlesAndFavourites;
			break;
		case LMMusicPickerSelectionModeAllCollections:
			self.searchView.selectionMode = LMSearchViewEntrySelectionModeAll;
			break;
	}
	self.searchView.hidden = YES;
	
//	self.searchView.searchableTrackCollections = @[
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeFavourites],
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists],
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums],
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles],
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeGenres],
//												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeCompilations]
//												   ];
//	self.searchView.searchableMusicTypes = @[
//											 @(LMMusicTypeFavourites),
//											 @(LMMusicTypeArtists),
//											 @(LMMusicTypeAlbums),
//											 @(LMMusicTypeTitles),
//											 @(LMMusicTypeGenres),
//											 @(LMMusicTypeCompilations)
//											 ];
	
	for(LMMusicTrackCollection *trackCollection in self.trackCollections){
		[self.searchView setData:trackCollection asSelected:YES forMusicType:LMMusicTypeTitles];
	}
	
	//Set collections and musictypes
	[self.view addSubview:self.searchView];
	
	self.searchViewBottomConstraint = [self.searchView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar];
	
	NSNotificationCenter *centre = [NSNotificationCenter defaultCenter];
	[centre addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[centre addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	NSLog(@"encode self.navcon %@", self.navigationController);
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	NSLog(@"self.navcon %@", self.navigationController);
	
	[super decodeRestorableStateWithCoder:coder];
}

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	NSLog(@"%@", identifierComponents);
	
	return [LMMusicPickerController new];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.selectionMode = LMMusicPickerSelectionModeOnlyTracks;
		
		self.trackCollections = [NSArray new];
		self.musicTypes = [NSArray new];
		
		self.restorationIdentifier = [[self class] description];
		self.restorationClass = [self class];
	}
	return self;
}

@end
