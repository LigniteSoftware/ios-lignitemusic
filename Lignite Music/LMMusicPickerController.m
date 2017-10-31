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

@interface LMMusicPickerController ()<LMSourceDelegate, UISearchBarDelegate, LMDynamicSearchViewDelegate, LMSourceSelectorDelegate>

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

@end

@implementation LMMusicPickerController

- (void)setTrack:(LMMusicTrack*)track asSelected:(BOOL)selected {
	NSMutableArray *mutableTrackCollection = [[NSMutableArray alloc] initWithArray:self.trackCollection.items];
	
	if(selected){
		[mutableTrackCollection addObject:track];
	}
	else{
		LMMusicTrack *trackToRemove = nil;
		
		for(LMMusicTrack *collectionTrack in mutableTrackCollection){
			if(collectionTrack.persistentID == track.persistentID){
				trackToRemove = collectionTrack;
				break;
			}
		}
		
		if(trackToRemove){
			[mutableTrackCollection removeObject:trackToRemove];
		}
	}
	
	self.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:mutableTrackCollection];
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
	
	if([self.delegate respondsToSelector:@selector(musicPicker:didFinishPickingMusicWithTrackCollection:)]){
		[self.delegate musicPicker:self didFinishPickingMusicWithTrackCollection:self.trackCollection];
	}
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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Source", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelSongSelection)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	if(!self.trackCollection){
		self.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:@[]];
	}
	
	
	self.searchBar = [UISearchBar newAutoLayoutView];
	self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"SearchAllMusic", nil), self.title];
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
	
	
	UILabel *selectSourceTitleLabel = [UILabel newAutoLayoutView];
	selectSourceTitleLabel.text = NSLocalizedString(@"SelectASource", nil);
	selectSourceTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
	selectSourceTitleLabel.textColor = [UIColor blackColor];
	[self.view addSubview:selectSourceTitleLabel];
	
	[selectSourceTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar withOffset:14];
	[selectSourceTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[selectSourceTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	
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
	[self.viewSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:selectSourceTitleLabel];
	
	[self.viewSelector setup];
	
	
	self.searchView = [LMDynamicSearchView newAutoLayoutView];
	self.searchView.hidden = YES;
	
	NSMutableArray<LMMusicTrackCollection*> *titlesCollection = [NSMutableArray new];
	NSArray *allTitles = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles];
	for(LMMusicTrackCollection *collection in allTitles){
		for(LMMusicTrack *track in collection.items){
			[titlesCollection addObject:[[LMMusicTrackCollection alloc] initWithItems:@[ track ]]];
		}
	}
	
	NSLog(@"Count %d/%d", (int)allTitles.count, (int)titlesCollection.count);
	
	self.searchView.searchableTrackCollections = @[
												   @[],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeFavourites],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeCompilations],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeGenres],
												   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists], [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums],
													   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles],
													   [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeComposers]
												   ];
	self.searchView.searchableMusicTypes = @[
											 @(LMMusicTypePlaylists),
											 @(LMMusicTypeFavourites),
											 @(LMMusicTypeCompilations),
											 @(LMMusicTypeGenres),
											 @(LMMusicTypeArtists),
											 @(LMMusicTypeAlbums),
											 @(LMMusicTypeTitles),
											 @(LMMusicTypeComposers)
											 ];
	//Set collections and musictypes
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchBar];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
