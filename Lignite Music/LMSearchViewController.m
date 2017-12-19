//
//  LMSearchViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchViewController.h"
#import "LMPlaylistManager.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMMusicPlayer.h"
#import "LMSearchBar.h"
#import "LMSettings.h"

@interface LMSearchViewController () <LMSearchBarDelegate, LMDynamicSearchViewDelegate, LMLayoutChangeDelegate>

/**
 The search bar for user input.
 */
@property LMSearchBar *searchBar;

/**
 The bottom constraint for the search bar.
 */
@property NSLayoutConstraint *searchBarBottomConstraint;

/**
 The actual search view where the magic happens.
 */
@property LMDynamicSearchView *searchView;

/**
 The background view to the status bar.
 */
@property UIView *statusBarBackgroundView;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The current search term.
 */
@property NSString *currentSearchTerm;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMSearchViewController

- (BOOL)prefersStatusBarHidden {
	return [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)searchViewWasInteractedWith:(LMDynamicSearchView*)searchView {
	NSLog(@"Interacted");
}

/**
 A search view entry was tapped.
 
 @param musicData The music data associated with the tapped entry. This is by default a single LMMusicTrackCollection, unless the musicType is LMMusicTypePlaylists, then it is an LMPlaylist.
 @param musicType The music type that the tapped entry was under, section-wise.
 */
- (void)searchViewEntryWasTappedWithData:(id)musicData forMusicType:(LMMusicType)musicType {
	NSLog(@"Tapped %@ for %d", musicData, musicType);
	
	LMMusicTrackCollection *trackCollection = nil;
	LMPlaylist *playlist = nil;
	if(musicType != LMMusicTypePlaylists){
		trackCollection = (LMMusicTrackCollection*)musicData;
	}
	else{
		playlist = (LMPlaylist*)musicData;
	}
	
	MPMediaEntityPersistentID persistentID = 0;
	switch(musicType){
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
			persistentID = trackCollection.representativeItem.albumPersistentID;
			break;
		case LMMusicTypeArtists:
			persistentID = trackCollection.representativeItem.artistPersistentID;
			break;
		case LMMusicTypeTitles:
		case LMMusicTypeFavourites:
			persistentID = trackCollection.representativeItem.persistentID;
			break;
		case LMMusicTypePlaylists:
			persistentID = playlist.persistentID;
			break;
		case LMMusicTypeGenres:
			persistentID = trackCollection.representativeItem.genrePersistentID;
			break;
		case LMMusicTypeComposers:
			persistentID = trackCollection.representativeItem.composerPersistentID;
			break;
	}
	
	[self.delegate searchEntryTappedWithPersistentID:persistentID forMusicType:musicType];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	self.currentSearchTerm = searchTerm;
	
	[self.searchView searchForString:searchTerm];
}

- (void)searchDialogueOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.view layoutIfNeeded];
	
	self.searchBarBottomConstraint.constant = -keyboardHeight;
	
	[UIView animateWithDuration:0.10 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	self.statusBarBackgroundView.hidden = size.width > size.height; //Will be landscape
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.searchView searchForString:self.currentSearchTerm];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.searchView searchForString:self.currentSearchTerm];
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	self.currentSearchTerm = @"";
	
	
	self.searchBar = [LMSearchBar newAutoLayoutView];
	self.searchBar.delegate = self;
	[self.view addSubview:self.searchBar];
	
	self.searchBarBottomConstraint = [self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	NSArray *searchBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/14.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:searchBarPortraitConstraints];
	
	NSArray *searchBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/14.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:searchBarLandscapeConstraints];
	
	
	self.searchView = [LMDynamicSearchView newAutoLayoutView];
	self.searchView.delegate = self;
	
	self.searchView.searchableTrackCollections = @[
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeFavourites],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeGenres],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeCompilations]
												   ];
	self.searchView.searchableMusicTypes = @[
											 @(LMMusicTypeFavourites),
											 @(LMMusicTypeArtists),
											 @(LMMusicTypeAlbums),
											 @(LMMusicTypePlaylists),
											 @(LMMusicTypeTitles),
											 @(LMMusicTypeGenres),
											 @(LMMusicTypeCompilations)
											 ];
	
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.searchView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.searchBar];
	
	
	self.statusBarBackgroundView = [UIView newAutoLayoutView];
	self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.statusBarBackgroundView];
	
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.statusBarBackgroundView autoSetDimension:ALDimensionHeight toSize:20.0f];
	
	self.statusBarBackgroundView.hidden = self.layoutManager.isLandscape;
	
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^() {
		[self.searchBar showKeyboard];
	} repeats:NO];
}

- (void)dealloc {
	[LMLayoutManager removeAllConstraintsRelatedToView:self.searchBar];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load search view controller's view");
	
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.automaticallyAdjustsScrollViewInsets = YES;
}

@end
