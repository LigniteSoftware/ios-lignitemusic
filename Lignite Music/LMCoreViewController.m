//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMGuideViewPagerController.h"
#import "LMSettingsViewController.h"
#import "LMSearchViewController.h"
#import "UIImage+AverageColour.h"
#import "LMCompactBrowsingView.h"
#import "LMCoreViewController.h"
#import "LMNowPlayingCoreView.h"
#import "LMNowPlayingCoreView.h"
#import "UIColor+isLight.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "LMThemeEngine.h"
#import "MBProgressHUD.h"
#import "APIdleManager.h"
#import "LMMusicPlayer.h"
#import "LMAppDelegate.h"
#import "LMAlertView.h"
#import "LMTitleView.h"
#import "LMSettings.h"
#import "LMAnswers.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMSource.h"

#import "LMLagDetectionThread.h"

#import "LMFeedbackViewController.h"
#import "LMRestorableNavigationController.h"
#import "LMCreditsViewController.h"

#import "LMProgressSlider.h"
#import "LMControlBarView.h"
#import "LMBrowsingBar.h"
#import "LMMiniPlayerCoreView.h"
#import "LMMiniPlayerView.h"
#import "LMTutorialView.h"
#import "LMButtonBar.h"
#import "LMExpandableTrackListControlBar.h"
#import "LMPhoneLandscapeDetailView.h"
#import "LMPlaylistEditorViewController.h"
#import "LMEnhancedPlaylistEditorViewController.h"
#import "LMAppleWatchBridge.h"
#import "LMThemePickerViewController.h"
#import "LMWarningManager.h"

#ifdef SPOTIFY
#import "Spotify.h"
#endif

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

#define LMCoreViewControllerRestorationStateKey @"LMCoreViewControllerRestorationStateKey"
#define LMCoreViewControllerStateRestoredNavigationTabKey @"LMCoreViewControllerStateRestoredNavigationTabKey"
#define LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey @"LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey"
#define LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex @"LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex"
#define LMCoreViewControllerStateRestoredTitleViewTopPersistentID @"LMCoreViewControllerStateRestoredTitleViewTopPersistentID"

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchViewControllerResultDelegate, LMButtonNavigationBarDelegate, UINavigationBarDelegate, UINavigationControllerDelegate,
LMTutorialViewDelegate, LMImageManagerDelegate, LMLandscapeNavigationBarDelegate, LMThemeEngineDelegate, LMLayoutChangeDelegate, LMWarningDelegate,

LMControlBarViewDelegate
>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingCoreView *nowPlayingCoreView;

@property LMTitleView *titleView;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property id currentSource;

@property UIView *browsingAssistantViewAttachedTo;

@property LMSearchViewController *searchViewController;

@property NSArray *musicCollectionsArray;

/**
 The time stamp for syncing.
 */
@property NSTimeInterval syncTimeStamp;

@property BOOL loaded;

@property CGPoint originalPoint, currentPoint;

@property NSInteger settingsOpen;
@property BOOL willOpenSettings;

@property LMLayoutManager *layoutManager;

@property UIImageView *splashImageView;

/**
 The view which goes in the background to blur out the rest of the app.
 */
@property UIVisualEffectView *backgroundBlurView;

@property UIActivityIndicatorView *loadingActivityIndicator;
@property UILabel *loadingLabel;

@property LMMusicType musicType;

@property LMCoreViewControllerRestorationState restorationState;
@property LMNavigationTab stateRestoredNavigationTab;
@property BOOL stateRestoredNavigationBarWasMinimized;
@property NSInteger previouslyOpenedDetailViewIndex;
@property MPMediaEntityPersistentID previousTitleViewTopPersistentID;
@property BOOL restorationStateHasReloadedContents;

@property MBProgressHUD *loadingProgressHUD;

@property UIView *buttonNavigationBarBottomCoverView;

@property BOOL orientationChangedOutsideOfView;
@property (readonly) BOOL requiresRefresh;

@property LMWarningManager *warningManager;
@property LMWarning *downloadImagesOnDataOrLowStorageWarning;

@end

@implementation LMCoreViewController

- (BOOL)requiresRefresh {
	if(!self.restorationStateHasReloadedContents && self.restorationState == LMCoreViewControllerRestorationStateOutOfView){
		self.restorationStateHasReloadedContents = YES;
		return YES;
	}
	
	if(self.orientationChangedOutsideOfView){
		self.orientationChangedOutsideOfView = NO;
		return YES;
	}
	
	return NO;
}

//- (NSLayoutConstraint*)buttonNavigationBarHeightConstraint {
//	for(NSLayoutConstraint *constraint in self.buttonNavigationBar.constraints){
//		if(constraint.firstItem == self.buttonNavigationBar && (constraint.firstAttribute == NSLayoutAttributeWidth || constraint.firstAttribute == NSLayoutAttributeHeight)){
//			
//			return constraint;
//		}
//	}
//	
//	return nil;
//}

- (void)cacheSizeChangedTo:(uint64_t)newCacheSize forCategory:(LMImageManagerCategory)category {
    if((category == LMImageManagerCategoryArtistImages && self.compactView.musicType == LMMusicTypeArtists)
    || (category == LMImageManagerCategoryAlbumImages && self.compactView.musicType == LMMusicTypeAlbums)){
        [self.compactView reloadDataAndInvalidateLayouts];
    }
}

//- (void)warningBarButtonItemTapped {
//	NSLog(@"Tapped warning");
//
//	[[LMImageManager sharedImageManager] launchExplicitPermissionRequestOnView:self.navigationController.view
//				  withCompletionHandler:^(LMImageManagerPermissionStatus permissionStatus) {
//					  if(permissionStatus == LMImageManagerPermissionStatusAuthorized) {
//						  NSLog(@"Cleared!");
//					  }
//				  }];
//}

//- (void)setWarningButtonShowing:(BOOL)showing {
//	//Set custom warning button onto navigationBar
//	if(!self.navigationBarWarningButton){
//		UIButton *iconWarningView = [UIButton newAutoLayoutView];
//		iconWarningView.imageView.contentMode = UIViewContentModeScaleAspectFit;
//		[iconWarningView setImage:[LMAppIcon imageForIcon:LMIconWarning] forState:UIControlStateNormal];
//		[iconWarningView addTarget:self action:@selector(warningBarButtonItemTapped) forControlEvents:UIControlEventTouchUpInside];
//
//		[self.navigationController.navigationBar addSubview:iconWarningView];
//
//		[iconWarningView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:6.0f];
//		[iconWarningView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[iconWarningView autoSetDimension:ALDimensionHeight toSize:44.0f];
//		[iconWarningView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:iconWarningView];
//
//		self.navigationBarWarningButton = iconWarningView;
//	}
//
//	self.navigationBarWarningButton.hidden = !showing;
//}

- (void)imageDownloadConditionLevelChanged:(LMImageManagerConditionLevel)newConditionLevel {
	switch(newConditionLevel){
		case LMImageManagerConditionLevelOptimal: {
//			[self setWarningButtonShowing:NO];
			NSLog(@"Optimal!");
			
			[self.warningManager removeWarning:self.downloadImagesOnDataOrLowStorageWarning];
			break;
		}
		case LMImageManagerConditionLevelSuboptimal: {
//			[self setWarningButtonShowing:YES];
			NSLog(@"Sub");
			
			[self.warningManager addWarning:self.downloadImagesOnDataOrLowStorageWarning];
			
			break;
		}
		case LMImageManagerConditionLevelNever: {
//			[self setWarningButtonShowing:NO];
			NSLog(@"Never");
			break;
		}
	}
}

- (void)tutorialFinishedWithKey:(NSString *)key {
    NSLog(@"Tutorial %@ finished, start another?", key);
    
    self.view.userInteractionEnabled = YES;
    self.buttonNavigationBar.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
	
	[UIView animateWithDuration:0.5 animations:^{
		self.backgroundBlurView.effect = nil;
	} completion:^(BOOL finished) {
		self.backgroundBlurView.hidden = YES;
	}];
	
    if([key isEqualToString:LMTutorialKeyBottomNavigation]){
        [self.buttonNavigationBar setSelectedTab:LMNavigationTabMiniplayer];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
            if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyMiniPlayer]){
                self.view.userInteractionEnabled = NO;
                self.buttonNavigationBar.userInteractionEnabled = NO;
                
                LMTutorialView *tutorialView = [[LMTutorialView alloc] initForAutoLayoutWithTitle:NSLocalizedString(@"TutorialMiniPlayerTitle", nil)
                                                                                      description:NSLocalizedString(@"TutorialMiniPlayerDescription", nil)
                                                                                              key:LMTutorialKeyMiniPlayer];
                [self.navigationController.view addSubview:tutorialView];
                tutorialView.boxAlignment = LMTutorialViewAlignmentBottom;
                tutorialView.arrowAlignment = LMTutorialViewAlignmentBottom;
                tutorialView.icon = [LMAppIcon imageForIcon:LMIconTutorialScroll];
                tutorialView.delegate = self;
				
				NSArray *tutorialViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
					[tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTop];
					[tutorialView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonNavigationBar.miniPlayerCoreView];
				}];
				[LMLayoutManager addNewPortraitConstraints:tutorialViewPortraitConstraints];
				
				NSArray *tutorialViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
					[tutorialView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
					[tutorialView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonNavigationBar.miniPlayerCoreView];
				}];
				[LMLayoutManager addNewLandscapeConstraints:tutorialViewLandscapeConstraints];
				
				self.backgroundBlurView.hidden = NO;
				[UIView animateWithDuration:0.5 animations:^{
					self.backgroundBlurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
				}];
            }
        } repeats:NO];
    }
    else if([key isEqualToString:LMTutorialKeyMiniPlayer]){
        [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
            if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyTopBar]){
                self.navigationController.navigationBar.userInteractionEnabled = NO;
                
                LMTutorialView *tutorialView = [[LMTutorialView alloc] initForAutoLayoutWithTitle:NSLocalizedString(@"TutorialTopBarTitle", nil)
                                                                                      description:NSLocalizedString(@"TutorialTopBarDescription", nil)
                                                                                              key:LMTutorialKeyTopBar];
                [self.navigationController.view addSubview:tutorialView];
                tutorialView.boxAlignment = LMTutorialViewAlignmentTop;
                tutorialView.arrowAlignment = LMTutorialViewAlignmentTop;
                tutorialView.icon = [LMAppIcon imageForIcon:LMIconTutorialTap];
                tutorialView.delegate = self;
				
				NSArray *tutorialViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
					[tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
					[tutorialView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.navigationController.navigationBar];
				}];
				[LMLayoutManager addNewPortraitConstraints:tutorialViewPortraitConstraints];
				
				NSArray *tutorialViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
					[tutorialView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
					[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
					[tutorialView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.landscapeNavigationBar];
				}];
				[LMLayoutManager addNewLandscapeConstraints:tutorialViewLandscapeConstraints];
            }
        } repeats:NO];
    }
    
    if(![LMTutorialView tutorialShouldRunForKey:LMTutorialKeyNowPlaying] && self.nowPlayingCoreView.tutorialView){
        [self.nowPlayingCoreView.tutorialView removeFromSuperview];
        self.nowPlayingCoreView.tutorialView = nil;
    }
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
//	NSLog(@"Got new playback state %d", newState);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
//	NSLog(@"HEY! Got new track, title %@", newTrack.title);
    
//    if(!self.buttonNavigationBar.isCompletelyHidden){
//		[self.buttonNavigationBar maximize:YES];
//        [self.buttonNavigationBar setSelectedTab:LMNavigationTabMiniplayer];
//    }
	
//	[self launchNowPlayingFromNavigationBar];
}

- (void)trackAddedToQueue:(LMMusicTrack*)trackAdded {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"TrackQueued", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
}

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_favourite_hud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"Favourited", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
	
	if(self.titleView.favourites && (self.currentSource == self.titleView)){
		[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
		
		self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
		[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
														 withAssociatedMusicType:LMMusicTypeTitles];
	}
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_unfavourite_hud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"Unfavourited", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
	
	if(self.titleView.favourites && (self.currentSource == self.titleView)){
		[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
		
		self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
		[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
														 withAssociatedMusicType:LMMusicTypeTitles];
	}
}

- (void)musicLibraryDidChange {
	NSLog(@"Changed library for core");
	
	__weak id weakSelf = self;
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInitiated, 0), ^{
		id strongSelf = weakSelf;
		
		if(!strongSelf){
			return;
		}
		
		NSLog(@"Beginning process of syncing new music.");
		
		LMCoreViewController *coreViewController = strongSelf;
		
		NSMutableArray *musicCollections = [NSMutableArray new];
		
		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		coreViewController.syncTimeStamp = startTime;
		
		for(int i = 0; i <= LMMusicTypeCompilations; i++){
			if(coreViewController.syncTimeStamp != startTime){
				NSLog(@"Abandoning this thread, another sync notification has come in.");
				return;
			}
			
			LMMusicType musicType = i;
			NSLog(@"Loading %d", musicType);
			NSArray *shitpost = [coreViewController.musicPlayer queryCollectionsForMusicType:musicType];
			[musicCollections addObject:shitpost];
		}
		
		coreViewController.musicCollectionsArray = [NSArray arrayWithArray:musicCollections];
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		
		NSLog(@"Took %f seconds to complete sync.", endTime-startTime);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[coreViewController reloadCurrentBrowsingView];
		});
	});
}

- (void)reloadCurrentBrowsingView {
	if(self.currentSource == self.titleView){
		[self.titleView rebuildTrackCollection];
	}
	else{
		[self setupBrowsingViewWithMusicType:[self.currentSource musicType]];
	}
}

- (void)setupBrowsingViewWithMusicType:(LMMusicType)musicType {
	if(self.musicCollectionsArray){
		NSLog(@"Loading music from cache.");
		self.compactView.musicTrackCollections = [self.musicCollectionsArray objectAtIndex:musicType];
	}
	else{
		NSLog(@"Loading music directly.");
		self.compactView.musicTrackCollections = [self.musicPlayer queryCollectionsForMusicType:musicType];
	}

	self.compactView.musicType = musicType;
	
	[self.compactView reloadContents];
	
	NSLog(@"Done setting up (is layed? %d)", self.buttonNavigationBar.browsingBar.didLayoutConstraints);
	
	self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
		[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.compactView.musicTrackCollections
														 withAssociatedMusicType:musicType];
	
	NSLog(@"Setup letters dictionary");
}

- (BOOL)prefersStatusBarHidden {	
	if(!self.loaded){
		NSLog(@"Loading");
		return YES;
	}
	
	return self.nowPlayingCoreView.isOpen //If now playing is open, hide it
		|| self.layoutManager.isLandscape //If the device is landscape, hide it
		|| (![LMLayoutManager isiPad] && ![LMLayoutManager isiPhoneX] && self.buttonNavigationBar.currentlySelectedTab == LMNavigationTabView && !self.buttonNavigationBar.isMinimized && !self.buttonNavigationBar.isCompletelyHidden); //If the view tab is open and the whole thing isn't minimized (doesn't apply to iPad as iPad has compact button navigation bar, also doesn't apply to iPhone X because it has the infamous notch)
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (void)logMusicTypeView:(LMMusicType)type {
	NSString *viewName = @"";
	switch(type){
		case LMMusicTypeArtists:
			viewName = @"Artist";
			break;
		case LMMusicTypeAlbums:
			viewName = @"Album";
			break;
		case LMMusicTypePlaylists:
			viewName = @"Playlist";
			break;
		case LMMusicTypeComposers:
			viewName = @"Composer";
			break;
		case LMMusicTypeGenres:
			viewName = @"Genre";
			break;
		case LMMusicTypeCompilations:
			viewName = @"Compilation";
			break;
		case LMMusicTypeTitles:
			viewName = @"Title";
			break;
		case LMMusicTypeFavourites:
			viewName = @"Favourites";
			break;
	}
	[LMAnswers logContentViewWithName:[NSString stringWithFormat:@"%@ View", viewName]
						  contentType:@"Browsing View"
							contentId:[NSString stringWithFormat:@"browsing_view_%@", [viewName lowercaseString]]
					 customAttributes:@{}];
}

- (void)sourceSelected:(LMSource *)source {
	if(!source.shouldNotHighlight){
		[self.currentSource setHidden:YES];
		[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
		
		[self.buttonNavigationBar setCurrentSourceIcon:[[source.icon averageColour] isLight] ? source.icon : [LMAppIcon invertImage:source.icon]];
	}
	
	NSLog(@"New source %@", source.title);
	
	[self.compactView setPhoneLandscapeViewDisplaying:NO forIndex:-1];
	
	switch(source.sourceID){
		case LMIconArtists:
		case LMIconGenres:
		case LMIconPlaylists:
		case LMIconComposers:
		case LMIconCompilations:
		case LMIconAlbums: {
			self.compactView.hidden = NO;
			self.titleView.hidden = YES;
			
			LMMusicType associatedMusicType = LMMusicTypeAlbums;
			
			switch(source.sourceID){
				case LMIconArtists:
					associatedMusicType = LMMusicTypeArtists;
					break;
				case LMIconAlbums:
					associatedMusicType = LMMusicTypeAlbums;
					break;
				case LMIconPlaylists:
					associatedMusicType = LMMusicTypePlaylists;
					break;
				case LMIconComposers:
					associatedMusicType = LMMusicTypeComposers;
					break;
				case LMIconGenres:
					associatedMusicType = LMMusicTypeGenres;
					break;
				case LMIconCompilations:
					associatedMusicType = LMMusicTypeCompilations;
					break;
			}
			
			self.musicType = associatedMusicType;
			
			[self logMusicTypeView:associatedMusicType];
			
			NSLog(@"Type %d", associatedMusicType);
			
			[self setupBrowsingViewWithMusicType:associatedMusicType];
			
			[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.compactView.musicTrackCollections.count > 0];
			
			self.currentSource = self.compactView;
			break;
		}
		case LMIconTitles: {
			BOOL requiresReload = self.titleView.favourites == YES;
			
			self.musicType = LMMusicTypeTitles;
			
			self.titleView.favourites = NO;
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			if(requiresReload){
				[self.titleView rebuildTrackCollection];
				[self.titleView.songListTableView reloadSubviewData];
				[self.titleView.songListTableView reloadData];
				
				[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
			}
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeTitles];
			break;
		}
		case LMIconFavouriteBlackFilled: {
			self.titleView.favourites = YES;
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			self.musicType = LMMusicTypeFavourites;
			
			[self.titleView rebuildTrackCollection];
			[self.titleView.songListTableView reloadSubviewData];
			[self.titleView.songListTableView reloadData];
			
			[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeFavourites];
			break;
		}
		case LMIconSettings: {
			[self.buttonNavigationBar completelyHide];
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			[self.navigationController pushViewController:settingsViewController animated:YES];
			break;
		}
		case LMIconBug: {
//			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.lignite.io/feedback/"]];
			
			
			LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
			
			LMRestorableNavigationController *navigation = [[LMRestorableNavigationController alloc] initWithRootViewController:feedbackController];
			[navigation setNavigationBarHidden:YES];
			
			[self.navigationController presentViewController:navigation animated:YES completion:nil];
			NSLog(@"Debug menu");
			break;
		}
		default:
			NSLog(@"Unknown index of source %@.", source);
			break;
	}
	
	[self.landscapeNavigationBar setMode:self.musicType == LMMusicTypePlaylists ? LMLandscapeNavigationBarModePlaylistView : LMLandscapeNavigationBarModeOnlyLogo];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:NO];
	[self.landscapeNavigationBar setMode:LMLandscapeNavigationBarModeWithBackButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:YES];
	[self.landscapeNavigationBar setMode:self.musicType == LMMusicTypePlaylists ? LMLandscapeNavigationBarModePlaylistView : LMLandscapeNavigationBarModeOnlyLogo];
	
	if(self.musicType == LMMusicTypePlaylists){
		[self.landscapeNavigationBar setEditing:self.compactView.editing];
	}
	
	self.searchViewController = nil;
}

- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration {
//	NSLog(@"rHeight changed to %f", requiredHeight);

    
    CGFloat bottomSpacing = requiredHeight + 10;
    [self.compactView changeBottomSpacing:bottomSpacing];
    self.titleView.songListTableView.bottomSpacing = bottomSpacing;
//    if(self.currentDetailViewController){
//        self.currentDetailViewController.browsingDetailView.tableView.bottomSpacing = bottomSpacing;
//        if(self.currentDetailViewController.nextDetailViewController){
//            self.currentDetailViewController.nextDetailViewController.browsingDetailView.tableView.bottomSpacing = bottomSpacing;
//        }
//    }
}

- (void)launchOnboarding {
	LMGuideViewPagerController *controller = [LMGuideViewPagerController new];
	controller.guideMode = GuideModeOnboarding;
	controller.coreViewController = self;
	[self presentViewController:controller animated:YES completion:nil];
}

- (void)prepareToLoadView {
	NSLog(@"Preparing to load view");
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(viewDidLoad) userInfo:nil repeats:NO];
}

// http://stackoverflow.com/questions/18946302/uinavigationcontroller-interactive-pop-gesture-not-working
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//	NSLog(@"%@ work with %@", [[gestureRecognizer class] description], [[otherGestureRecognizer class]description]);
//	return [otherGestureRecognizer class] != [UIPanGestureRecognizer class];
////	return YES;
//}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	NSLog(@"Changed to %@", searchTerm);
}

- (void)searchDialogueOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	NSLog(@"Search was opened: %d", opened);
	
	if(!self.searchViewController){
//		[self attachBrowsingAssistantToView:self.view];
		
		self.searchViewController = [LMSearchViewController new];
		self.searchViewController.delegate = self;
		[self.navigationController presentViewController:self.searchViewController animated:YES completion:nil];
	}
}

- (void)searchEntryTappedWithPersistentID:(MPMediaEntityPersistentID)persistentID forMusicType:(LMMusicType)musicType; {
	NSLog(@"Tapped %lld for type %d.", persistentID, musicType);
	
	[self sourceSelected:[self.sourcesForSourceSelector objectAtIndex:musicType]];
	
	if([self.currentSource isEqual:self.titleView]){
		[self.titleView scrollToTrackWithPersistentID:persistentID];
	}
	else{
		LMCompactBrowsingView *compactView = self.currentSource;
		[compactView scrollToItemWithPersistentID:persistentID];
	}
	
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)letterSelected:(NSString *)letter atIndex:(NSUInteger)index {
	if([LMLayoutManager isiPad]){
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		
		hud.mode = MBProgressHUDModeText;
		hud.label.text = [NSString stringWithFormat:@"%@", letter];
		hud.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:44.0f];
		hud.userInteractionEnabled = NO;
		
		[hud hideAnimated:YES afterDelay:0.5f];
	}
	if([self.currentSource isEqual:self.titleView]){
		[self.titleView scrollToTrackIndex:index == 0 ? 0 : index-1];
	}
	else{
		[self.currentSource scrollViewToIndex:index];
	}
}

- (void)swipeDownGestureOccurredOnLetterTabBar {
	[self.buttonNavigationBar minimize:NO];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
//	NSLog(@"And it's getting to the point where even I have a problem with it");
	return UIBarPositionTopAttached;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
	NSLog(@"Item %@ was pop popped!", item.title);
	if(self.settingsOpen > 0){
		self.settingsOpen--;
	}
    if(self.settingsOpen == 0){
		[self.buttonNavigationBar maximize:YES];
		
		[self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
	NSLog(@"Item %@ was pushed!", item.title);
    if(self.settingsOpen > 0 || self.willOpenSettings){
        self.settingsOpen++;
    }
	
    self.willOpenSettings = NO;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
	NSLog(@"Pop? %@", item);

	[self.navigationController popViewControllerAnimated:YES];

	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[self.buttonNavigationBar maximize:YES];
	
	if(self.requiresRefresh){ //For when the view is out of view during state restoration
		[self.compactView reloadContents];
		[self.titleView.songListTableView reloadData];
		[self.buttonNavigationBar reloadLayout];
		
		if([LMLayoutManager isiPhoneX]){
			[self notchPositionChanged:LMLayoutManager.notchPosition];
		}
		
		[self.navigationController.view bringSubviewToFront:self.buttonNavigationBar];
		[self.navigationController.view bringSubviewToFront:self.nowPlayingCoreView];
	}
}

- (void)launchNowPlayingFromNavigationBar {
    if(!self.musicPlayer.nowPlayingTrack){
		NSLog(@"Nothing's playing mate");
        return;
    }
    
	[self.nowPlayingCoreView.superview layoutIfNeeded];
	
	self.nowPlayingCoreView.topConstraint.constant = 0;
	
	self.nowPlayingCoreView.isOpen = YES;

	[UIView animateWithDuration:0.25 animations:^{
		[self.nowPlayingCoreView.superview layoutIfNeeded];
	} completion:^(BOOL finished) {
		if(finished){
			[UIView animateWithDuration:0.25 animations:^{
				[self setNeedsStatusBarAppearanceUpdate];
			}];
		}
	}];
}

- (void)panNowPlayingUp:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:recognizer.view];
	
    NSLog(@"Dick is not a bone 哈哈哈");
    
	if(self.originalPoint.y == 0){
		self.originalPoint = self.view.frame.origin;
		self.currentPoint = self.nowPlayingCoreView.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
    NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	if(self.musicPlayer.nowPlayingTrack){
		self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.frame.size.height+translation.y;
		
		[self.nowPlayingCoreView.superview layoutIfNeeded];
	}
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		if(self.musicPlayer.nowPlayingTrack){
			self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
			
			[self.nowPlayingCoreView.superview layoutIfNeeded];
		}
		
		if(translation.y > self.nowPlayingCoreView.frame.size.height/10.0){			
			if(translation.y > self.nowPlayingCoreView.frame.size.height/8.0){
				[self.buttonNavigationBar minimize:NO];
			}
			
			self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.frame.size.height;
			
			self.nowPlayingCoreView.isOpen = NO;
		}
		else if(self.musicPlayer.nowPlayingTrack) {
			self.nowPlayingCoreView.topConstraint.constant = 0.0;
			
			self.nowPlayingCoreView.isOpen = YES;
		}
		
		NSLog(@"Is open %d", self.nowPlayingCoreView.isOpen);
		
		[UIView animateWithDuration:0.25 animations:^{
			[self.nowPlayingCoreView.superview layoutIfNeeded];
		} completion:^(BOOL finished) {
			if(finished){
				[UIView animateWithDuration:0.25 animations:^{
					[self setNeedsStatusBarAppearanceUpdate];
				}];
			}
		}];
	}
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView*)controlBar {
	return 3;
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar {
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView*)controlBar {
	return YES;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"Changed to %@", NSStringFromCGSize(newSize));
}

- (UIResponder*)nextResponder {
    [[APIdleManager sharedInstance] didReceiveInput];
    return [super nextResponder];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	self.layoutManager.traitCollection = self.traitCollection;
	[self.layoutManager traitCollectionDidChange:previousTraitCollection];
	
	if([LMLayoutManager isiPad]){
		self.splashImageView.image = [UIImage imageNamed:@"ipad_splashscreen_abbey.png"];
	}
	else{
		self.splashImageView.image = [UIImage imageNamed:[LMLayoutManager sharedLayoutManager].isLandscape ? @"splash_landscape_abbey_fixed.png" : @"splash_portrait_abbey_fixed.png"];
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
//	return;
	
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[self.layoutManager rootViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
//	return;
	
	BOOL willBeLandscape = size.width > size.height;
	if([LMLayoutManager isiPad]){
		willBeLandscape = NO;
	}
	
	NSLog(@"Starting rotation");
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotating");
		
		[self.navigationController setNavigationBarHidden:NO];
		self.landscapeNavigationBar.hidden = NO;
		
		self.navigationController.navigationBar.layer.opacity = willBeLandscape ? 0.0 : 1.0;
		self.landscapeNavigationBar.layer.opacity = !willBeLandscape ? 0.0 : 1.0;
		
//		if(@available(iOS 11, *)){
//			self.navigationController.navigationBar.frame = CGRectMake(0, 20, size.width, willBeLandscape ? 0 : 64.0);
//		}
//		else{
//			self.navigationController.navigationBar.frame = CGRectMake(0, 0, size.width, willBeLandscape ? 0 : 64.0);
//		}
		
		self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.isOpen ? 0 : (size.height*1.50);
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotated");
		
		UITraitCollection *previousCollection = self.traitCollection;
		self.layoutManager.traitCollection = self.traitCollection;
		[self.layoutManager traitCollectionDidChange:previousCollection];
		
		self.layoutManager.size = self.view.frame.size;
				
		[self.navigationController setNavigationBarHidden:willBeLandscape];
		self.landscapeNavigationBar.hidden = !willBeLandscape;
		
		if([LMLayoutManager isiPhoneX]){
			self.landscapeNavigationBar.frame = CGRectMake(0, 0, ([LMLayoutManager notchPosition] == LMNotchPositionLeft) ? 94.0 : 64.0, self.layoutManager.isLandscape ? (self.view.frame.size.height + self.navigationController.navigationBar.frame.size.height) : self.view.frame.size.width);
		}
		
		if(!self.view.window){
			self.orientationChangedOutsideOfView = YES;
		}
		
		[self.navigationController.view bringSubviewToFront:self.buttonNavigationBar];
		[self.navigationController.view bringSubviewToFront:self.nowPlayingCoreView];
		
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			[UIView animateWithDuration:0.25 animations:^{
				[self setNeedsStatusBarAppearanceUpdate];
			}];
		} repeats:NO];
	}];
}



- (void)buttonTappedOnLandscapeNavigationBar:(LMLandscapeNavigationBarButton)buttonPressed {
	switch(buttonPressed){
		case LMLandscapeNavigationBarButtonBack: {
			NSLog(@"Go back");
			
			if(!self.view.window){
				[self.navigationController popViewControllerAnimated:YES];
			}
			else{
				[self.compactView backButtonPressed];
			}
			break;
		}
		case LMLandscapeNavigationBarButtonLogo: {
			NSLog(@"Now playing nav bar please");
			
			[self launchNowPlayingFromNavigationBar];
			break;
		}
		case LMLandscapeNavigationBarButtonCreate: {
			[self.compactView addPlaylistButtonTapped];
			break;
		}
		case LMLandscapeNavigationBarButtonEdit: {
			[self.compactView editPlaylistButtonTapped];
			break;
		}
	}
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
	
	NSLog(@"What boi encoding restore state %d", (int)self.compactView.indexOfCurrentlyOpenDetailView);
	
//	[coder encodeObject:self.navigationController.navigationBar.items forKey:LMNavigationBarItemsKey];
	
	LMCoreViewControllerRestorationState newRestorationState = LMCoreViewControllerRestorationStateBrowsing;
	
	if(self.navigationController.viewControllers.count > 1 || (self.view.window == nil)){
		newRestorationState = LMCoreViewControllerRestorationStateOutOfView;
	}
	else if(self.nowPlayingCoreView.isOpen){
		newRestorationState = LMCoreViewControllerRestorationStateNowPlaying;
	}
	
	[coder encodeInteger:newRestorationState forKey:LMCoreViewControllerRestorationStateKey];
	[coder encodeInteger:self.buttonNavigationBar.currentlySelectedTab forKey:LMCoreViewControllerStateRestoredNavigationTabKey];
	[coder encodeBool:self.buttonNavigationBar.isMinimized forKey:LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey];
	[coder encodeInteger:self.compactView.indexOfCurrentlyOpenDetailView
				  forKey:LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex];
	[coder encodeInteger:[self.titleView topTrackPersistentID] forKey:LMCoreViewControllerStateRestoredTitleViewTopPersistentID];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	NSLog(@"What boi!! got %@", [coder decodeObjectForKey:LMCoreViewControllerRestorationStateKey]);
	
	LMCoreViewControllerRestorationState newRestorationState = [coder decodeIntegerForKey:LMCoreViewControllerRestorationStateKey];
	LMNavigationTab navigationTab = [coder decodeIntegerForKey:LMCoreViewControllerStateRestoredNavigationTabKey];
	BOOL navigationBarWasMinimized = [coder decodeBoolForKey:LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey];
	NSInteger previouslyOpenedDetailViewIndex = [coder decodeIntegerForKey:LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex];
	MPMediaEntityPersistentID titleViewTopPersistentID = [coder decodeIntegerForKey:LMCoreViewControllerStateRestoredTitleViewTopPersistentID];
	
	self.restorationState = newRestorationState;
	self.stateRestoredNavigationTab = navigationTab;
	self.stateRestoredNavigationBarWasMinimized = navigationBarWasMinimized;
	self.previouslyOpenedDetailViewIndex = previouslyOpenedDetailViewIndex;
	self.previousTitleViewTopPersistentID = titleViewTopPersistentID;
	
	[self.navigationController setNavigationBarHidden:!(self.restorationState == LMCoreViewControllerRestorationStateOutOfView)];
}

- (UINavigationItem*)navigationItem {
	UIImageView *titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
	titleImageView.contentMode = UIViewContentModeScaleAspectFit;
	titleImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
	titleImageView.userInteractionEnabled = YES;

	UITapGestureRecognizer *nowPlayingTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(launchNowPlayingFromNavigationBar)];
	[titleImageView addGestureRecognizer:nowPlayingTapGestureRecognizer];

	UINavigationItem *navigationItem = [[UINavigationItem alloc]initWithTitle:@""];
	navigationItem.titleView = titleImageView;
	
	return navigationItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
	
	NSLog(@"View did load core");

	
	static dispatch_once_t basicSetupToken;
	dispatch_once(&basicSetupToken, ^{
		self.view.backgroundColor = [UIColor whiteColor];
		
		//Themeing? Bet you wish you didn't make it this way ;)  - Past Edwin, Dec. 15th 2017
		UIView *statusBarCover = [UIView newAutoLayoutView];
		statusBarCover.backgroundColor = [LMColour whiteColour];
		[self.navigationController.navigationBar addSubview:statusBarCover];
		
		[statusBarCover autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[statusBarCover autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-20.0f];
		[statusBarCover autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[statusBarCover autoSetDimension:ALDimensionHeight toSize:20.0f];
		
		
		self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
		self.navigationController.navigationBar.tintColor = [UIColor blackColor];
		self.navigationController.navigationBar.translucent = NO;
		
		self.navigationController.navigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
		self.navigationController.navigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
		self.navigationController.navigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationController.navigationBar.layer.shadowRadius/2);
		self.navigationController.navigationBar.layer.shadowOpacity = 0.25f;
		
		[self.navigationController setNavigationBarHidden:!(self.restorationState == LMCoreViewControllerRestorationStateOutOfView)];
		
		self.loaded = NO;
		self.previouslyOpenedDetailViewIndex = -1;
		
		if(!self.layoutManager){
			self.layoutManager = [LMLayoutManager sharedLayoutManager];
			self.layoutManager.traitCollection = self.traitCollection;
			NSLog(@"Trait collection %@ %ld", self.traitCollection, (long)self.traitCollection.horizontalSizeClass);
			self.layoutManager.size = self.view.frame.size;
		}
		
#ifdef SPEED_DEMON_MODE
		[UIView setAnimationsEnabled:NO];
#endif
		
		
		NSLog(@"Frame set %@", NSStringFromCGRect(self.view.frame));
		
		self.splashImageView = [UIImageView newAutoLayoutView];
		self.splashImageView.backgroundColor = [UIColor orangeColor];
		if([LMLayoutManager isiPad]){
			self.splashImageView.image = [UIImage imageNamed:@"splash_ipad.png"];
		}
		else{
			self.splashImageView.image = [UIImage imageNamed:[LMLayoutManager sharedLayoutManager].isLandscape ? @"splash_landscape_g.png" : @"splash_portrait_g.png"];
		}
		self.splashImageView.contentMode = UIViewContentModeScaleAspectFill;
		[self.view addSubview:self.splashImageView];

		[self.splashImageView autoPinEdgesToSuperviewEdges];
	});
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if(![userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
		NSLog(@"Launching onboarding...");
		
		[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
			[self launchOnboarding];
		} repeats:NO];
	}
	else if([SKCloudServiceController authorizationStatus] != SKCloudServiceAuthorizationStatusAuthorized){ //If not authorized
		NSLog(@"Launching issues...");
		
		//Launch tutorial on how to fix
		dispatch_async(dispatch_get_main_queue(), ^{
			LMGuideViewPagerController *guideViewPager = [LMGuideViewPagerController new];
			guideViewPager.guideMode = GuideModeMusicPermissionDenied;
			[self presentViewController:guideViewPager animated:YES completion:nil];
		});

	}
	else{
		static dispatch_once_t mainSetupToken;
		dispatch_once(&mainSetupToken, ^{
			NSLog(@"Launch main view controller contents");
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
				if(!(self.restorationState == LMCoreViewControllerRestorationStateOutOfView)){
					self.loadingActivityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
					
					[self.navigationController.view addSubview:self.loadingActivityIndicator];
					
					if([LMLayoutManager isiPad]){
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:WINDOW_FRAME.size.height/([LMLayoutManager isLandscape] ? 1.5 : 2.0)];
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.loadingActivityIndicator autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view withMultiplier:(2.0/4.0)];
					}
					else{
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:WINDOW_FRAME.size.height/([LMLayoutManager isLandscape] ? 1.5 : 2.0)];
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.loadingActivityIndicator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.loadingActivityIndicator autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view withMultiplier:(1.0/4.0)];
					}
					
					[self.loadingActivityIndicator startAnimating];
					
					UIImageView *loadingIndicatorImageView = nil;
					
					for(UIView *subview in self.loadingActivityIndicator.subviews){
						if([subview class] == [UIImageView class]){
							loadingIndicatorImageView = (UIImageView*)subview;
						}
					}
					
					if(loadingIndicatorImageView){
						self.loadingLabel = [UILabel newAutoLayoutView];
						self.loadingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
						self.loadingLabel.text = NSLocalizedString(@"LoadingMusic", nil);
						self.loadingLabel.textAlignment = NSTextAlignmentCenter;
						self.loadingLabel.textColor = [UIColor blackColor];
						[self.loadingActivityIndicator addSubview:self.loadingLabel];
						
						[self.loadingLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.loadingLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.loadingLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:loadingIndicatorImageView withOffset:10];
					}
				}
				else {
					UIView *viewToAddTo = self.navigationController.view;
					if(self.pendingStateRestoredPlaylistEditor){
						viewToAddTo = self.pendingStateRestoredPlaylistEditor.navigationController.view;
					}
					else if(self.pendingStateRestoredEnhancedPlaylistEditor){
						viewToAddTo = self.pendingStateRestoredEnhancedPlaylistEditor.navigationController.view;
					}
					else if(self.pendingFeedbackViewController){
						viewToAddTo = self.pendingFeedbackViewController.navigationController.view;
					}
					else{
						NSLog(@"[Warning] Defaulting addition of progress hud to the root navigation controller");
					}
					self.loadingProgressHUD = [MBProgressHUD showHUDAddedTo:viewToAddTo animated:YES];
					
					self.loadingProgressHUD.mode = MBProgressHUDModeIndeterminate;
					self.loadingProgressHUD.label.text = NSLocalizedString(@"HangOn", nil);
					self.loadingProgressHUD.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
					self.loadingProgressHUD.userInteractionEnabled = NO;
				}
				
				[NSTimer scheduledTimerWithTimeInterval:0.05 block:^{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self loadSubviews];
					});
				} repeats:NO];
			} repeats:NO];
		});
	}
}

- (void)themeChanged:(LMTheme)theme {
	if([LMLayoutManager isiPhoneX]){
		self.buttonNavigationBarBottomCoverView.backgroundColor = [LMThemeEngine mainColour];
	}
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	CGFloat landscapeNavigationBarWidth = (notchPosition == LMNotchPositionLeft) ? 94.0f : 64.0f;
	
	if(notchPosition == LMNotchPositionTop || notchPosition == LMNotchPositionBottom){
		landscapeNavigationBarWidth = 0;
	}
	
	for(NSLayoutConstraint *constraint in self.landscapeNavigationBar.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeWidth
		   && constraint.firstItem == self.landscapeNavigationBar
		   && !constraint.secondItem){
			[self.landscapeNavigationBar removeConstraint:constraint];
		}
	}
	[self.landscapeNavigationBar autoSetDimension:ALDimensionWidth toSize:landscapeNavigationBarWidth];
	
	for(NSLayoutConstraint *constraint in self.view.constraints){
		if(constraint.firstItem == self.compactView
		   && constraint.firstAttribute == NSLayoutAttributeLeading
		   && constraint.secondAttribute == NSLayoutAttributeLeading){
			constraint.constant = landscapeNavigationBarWidth;
		}
	}
}

- (void)warningTapped:(LMWarning*)warning {
	if(warning == self.downloadImagesOnDataOrLowStorageWarning){
		[[LMImageManager sharedImageManager] displayDataAndStorageExplicitPermissionAlertOnView:self.navigationController.view
																		  withCompletionHandler:^(BOOL authorized) {
																			  NSLog(@"Authorized: %d", authorized);
																			  [self.warningManager removeWarning:self.downloadImagesOnDataOrLowStorageWarning];
																			  [[LMImageManager sharedImageManager] downloadIfNeededForAllCategories];
																		  }];
	}
}

- (void)loadSubviews {
//	[self.navigationController setNavigationBarHidden:NO animated:YES];
//
//	LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//	[self.navigationController pushViewController:settingsViewController animated:YES];
	
	if(self.buttonNavigationBar){
		return;
	}
	
//	LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
//	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
//	[self presentViewController:navigation animated:YES completion:^{
//		
//	}];
//
//	
//	return;
	
	self.loadingProgressHUD.hidden = YES;
	
	[self.loadingActivityIndicator stopAnimating];
	self.loadingLabel.hidden = YES;
	
	if(!self.layoutManager){
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		self.layoutManager.traitCollection = self.traitCollection;
		self.layoutManager.size = self.view.frame.size;
	}
	
	[self.layoutManager addDelegate:self];
	
//	LMPhoneLandscapeDetailView *phoneLandscapeDetailView = [LMPhoneLandscapeDetailView newAutoLayoutView];
//	[self.view addSubview:phoneLandscapeDetailView];
//	[phoneLandscapeDetailView autoPinEdgesToSuperviewEdges];
//	
//	phoneLandscapeDetailView.musicType = LMMusicTypeAlbums;
//	phoneLandscapeDetailView.musicTrackCollection = [[[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums] objectAtIndex:0];
//	
//	
//	return;
	
//	LMLagDetectionThread *lagThread = [LMLagDetectionThread new];
//	lagThread.viewToDisplayAlertsOn = self.navigationController.view;
//	lagThread.lagDelayInSeconds = 0.05;
//	[lagThread start];
	
	NSTimeInterval loadStartTime = [[NSDate new] timeIntervalSince1970];
				
	NSArray *sourceTitles = @[
							  @"Favourites", @"Artists", @"Albums", @"Titles", @"Playlists", @"Genres", @"Compilations", @"Settings", @"ReportBugOrSendFeedback"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"", @"", @"", @"", @"", @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconFavouriteBlackFilled, LMIconArtists, LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconGenres, LMIconCompilations, LMIconSettings, LMIconBug
	};
	BOOL notHighlight[] = {
		NO, NO, NO, NO, NO, NO, NO, YES, YES
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
	
	self.sourcesForSourceSelector = [NSArray arrayWithArray:sources];
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
	LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
	[pebbleManager attachToViewController:self];
	
	
	LMAppleWatchBridge *appleWatchBridge = [LMAppleWatchBridge sharedAppleWatchBridge];
	[appleWatchBridge attachToViewController:self];
	
	
//		self.navigationController.navigationBar = [LMNavigationBar newAutoLayoutView];
//		[self.navigationController.view addSubview:self.navigationController.navigationBar];
//
//		[self.navigationController.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.navigationController.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
//		[self.navigationController.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.navigationController.navigationBar autoSetDimension:ALDimensionHeight toSize:64.0f];
	
	NSLog(@"Fuck %@ %@", [self.navigationController class], self.navigationController.navigationBar);
	
	[self.navigationController setNavigationBarHidden:NO];
	[self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
	
//		self.navigationController.navigationBar = [[LMNavigationBar alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 64.0f)];
//		self.navigationController.navigationBar.prefersLargeTitles = NO;
//
//

	
//	if(self.statePreservedNavigationBarItems){
//		[self.navigationController.navigationBar setItems:self.statePreservedNavigationBarItems];
//		self.settingsOpen = self.statePreservedNavigationBarItems.count-1;
//		self.statePreservedNavigationBarItems = nil;
//	}
//	else{
//		[self.navigationController.navigationBar pushNavigationItem:[self nowPlayingNavigationItem] animated:YES];
//	}
	
	
	
	CGFloat landscapeNavigationBarWidth = 64.0f;
	if([LMLayoutManager isiPhoneX]){
		landscapeNavigationBarWidth = ([LMLayoutManager notchPosition] == LMNotchPositionLeft) ? 94.0f : 64.0f;
	}
	
	self.landscapeNavigationBar = [LMLandscapeNavigationBar newAutoLayoutView];
	self.landscapeNavigationBar.delegate = self;
	self.landscapeNavigationBar.mode = (self.navigationController.navigationBar.items.count > 1)
	? LMLandscapeNavigationBarModeWithBackButton
	: LMLandscapeNavigationBarModeOnlyLogo;
//	self.landscapeNavigationBar.mode = LMLandscapeNavigationBarModePlaylistView;
	[self.navigationController.view addSubview:self.landscapeNavigationBar];

	[self.landscapeNavigationBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.landscapeNavigationBar autoSetDimension:ALDimensionWidth toSize:landscapeNavigationBarWidth];
	
	self.landscapeNavigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
	self.landscapeNavigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
	self.landscapeNavigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationController.navigationBar.layer.shadowRadius/2);
	self.landscapeNavigationBar.layer.shadowOpacity = 0.25f;
	
	
	
	[self.navigationController setNavigationBarHidden:self.layoutManager.isLandscape];
	self.navigationController.navigationBar.layer.opacity = self.navigationController.navigationBar.hidden ? 0.0 : 1.0;
	//						self.navigationController.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.navigationController.navigationBar.hidden ? 0 : 64.0f);
	self.landscapeNavigationBar.hidden = !self.layoutManager.isLandscape;
	self.landscapeNavigationBar.layer.opacity = self.landscapeNavigationBar.hidden ? 0.0 : 1.0;
	
	
	self.warningManager = [LMWarningManager sharedWarningManager];
	[self.view addSubview:self.warningManager.warningBar];
	
	[self.warningManager.warningBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.warningManager.warningBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.warningManager.warningBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.warningManager.warningBar autoSetDimension:ALDimensionHeight toSize:0.0f];
	
	self.downloadImagesOnDataOrLowStorageWarning = [LMWarning warningWithText:NSLocalizedString(@"DownloadImagesOnDataWarning", nil) priority:LMWarningPriorityHigh];
	self.downloadImagesOnDataOrLowStorageWarning.delegate = self;
	
	
	
	self.compactView = [LMCompactBrowsingView newAutoLayoutView];
	self.compactView.rootViewController = self;
	[self.view addSubview:self.compactView];
	
	if(self.pendingStateRestoredPlaylistEditor){
		self.pendingStateRestoredPlaylistEditor.delegate = self.compactView;
	}
	
	if(self.pendingStateRestoredEnhancedPlaylistEditor){
		self.pendingStateRestoredEnhancedPlaylistEditor.delegate = self.compactView;
	}
	
	[self.compactView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningManager.warningBar];
	
	NSArray *compactViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	}];
	[LMLayoutManager addNewPortraitConstraints:compactViewPortraitConstraints];
	
	NSArray *compactViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.compactView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:landscapeNavigationBarWidth];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	}];
	[LMLayoutManager addNewLandscapeConstraints:compactViewLandscapeConstraints];
	
	
	
	
	self.titleView = [LMTitleView newAutoLayoutView];
	self.titleView.backgroundColor = [UIColor whiteColor];
	self.titleView.rootViewController = self;
	[self.view addSubview:self.titleView];
	
	[self.titleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.compactView];
	[self.titleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.compactView];
	[self.titleView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.compactView];
	[self.titleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.compactView];
	
	[self.titleView setup];
	self.titleView.hidden = YES;
	
	
	
	
	
	
	self.buttonNavigationBar = [LMButtonNavigationBar newAutoLayoutView];
	self.buttonNavigationBar.rootViewController = self;
	self.buttonNavigationBar.sourcesForSourceSelector = self.sourcesForSourceSelector;
	self.buttonNavigationBar.delegate = self;
	self.buttonNavigationBar.searchBarDelegate = self;
	self.buttonNavigationBar.letterTabBarDelegate = self;
//	self.buttonNavigationBar.hidden = YES;
	[self.navigationController.view addSubview:self.buttonNavigationBar];
	
	//						self.navigationController.view.hidden = YES;
	
	self.buttonNavigationBar.backgroundColor = [UIColor purpleColor];
	
	NSLog(@"Class %@", [self.navigationController.view class]);
	
	NSArray *buttonNavigationBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}];
	[LMLayoutManager addNewPortraitConstraints:buttonNavigationBarPortraitConstraints];
	
	NSArray *buttonNavigationBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}];
	[LMLayoutManager addNewLandscapeConstraints:buttonNavigationBarLandscapeConstraints];
	
	
	NSArray *buttonNavigationBariPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.buttonNavigationBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view withMultiplier:(2.0/3.0)];
	}];
	[LMLayoutManager addNewiPadConstraints:buttonNavigationBariPadConstraints];
	
	//						[self.navigationController.view insertSubview:self.landscapeNavigationBar aboveSubview:self.buttonNavigationBar];
	
	[self.musicPlayer addMusicDelegate:self];
	
	
//	if([LMLayoutManager isiPhoneX]){
//		self.buttonNavigationBarBottomCoverView = [UIView newAutoLayoutView];
//		self.buttonNavigationBarBottomCoverView.backgroundColor = [LMColour mainColour];
//		[self.navigationController.view addSubview:self.buttonNavigationBarBottomCoverView];
//
//
////		NSArray *buttonNavigationBarBottomCoverViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//			[self.buttonNavigationBarBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//			[self.buttonNavigationBarBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//			[self.buttonNavigationBarBottomCoverView autoSetDimension:ALDimensionHeight toSize:69];
//			[self.buttonNavigationBarBottomCoverView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonNavigationBar];
////		}];
////		[LMLayoutManager addNewPortraitConstraints:buttonNavigationBarBottomCoverViewPortraitConstraints];
//	}
	
	
	
	self.nowPlayingCoreView = [LMNowPlayingCoreView newAutoLayoutView];
	self.nowPlayingCoreView.rootViewController = self;
	[self.navigationController.view addSubview:self.nowPlayingCoreView];
	
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.nowPlayingCoreView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view];
	self.nowPlayingCoreView.topConstraint =
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height * 1.5];
	
	
	
	
	
	
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	imageManager.viewToDisplayAlertsOn = self.navigationController.view;
	[imageManager addDelegate:self];
	
	
	
	self.loaded = YES;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self setNeedsStatusBarAppearanceUpdate];
	}];
	
	[APIdleManager sharedInstance].onTimeout = ^(void){
		if(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying && self.view.window){
			[self launchNowPlayingFromNavigationBar];
		}
	};
	
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
		self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
		self.backgroundBlurView.userInteractionEnabled = NO;
		[self.navigationController.view addSubview:self.backgroundBlurView];
		
		[self.backgroundBlurView autoPinEdgesToSuperviewEdges];
		
		[self.navigationController.view insertSubview:self.buttonNavigationBar aboveSubview:self.backgroundBlurView];
		[self.navigationController.view insertSubview:self.buttonNavigationBarBottomCoverView aboveSubview:self.buttonNavigationBar];
		[self.navigationController.view insertSubview:self.nowPlayingCoreView aboveSubview:self.buttonNavigationBar];

		
		if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyBottomNavigation]){
			self.view.userInteractionEnabled = NO;
			self.buttonNavigationBar.userInteractionEnabled = NO;
			
			
			LMTutorialView *tutorialView = [[LMTutorialView alloc] initForAutoLayoutWithTitle:NSLocalizedString(@"TutorialMainNavigationTitle", nil)
																				  description:NSLocalizedString(@"TutorialMainNavigationDescription", nil)
																						  key:LMTutorialKeyBottomNavigation];
			[self.navigationController.view addSubview:tutorialView];
			tutorialView.boxAlignment = LMTutorialViewAlignmentBottom;
			tutorialView.arrowAlignment = LMTutorialViewAlignmentBottom;
			//                                tutorialView.icon = [LMAppIcon imageForIcon:LMIconLookAndFeel];
			tutorialView.delegate = self;
			
			NSArray *tutorialViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
				[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTop];
				[tutorialView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonNavigationBar.browsingBar];
			}];
			[LMLayoutManager addNewPortraitConstraints:tutorialViewPortraitConstraints];
			
			NSArray *tutorialViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[tutorialView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
				[tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[tutorialView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonNavigationBar.browsingBar];
			}];
			[LMLayoutManager addNewLandscapeConstraints:tutorialViewLandscapeConstraints];
			
			[UIView animateWithDuration:0.5 animations:^{
				self.backgroundBlurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			}];
		}
		else{
			NSArray *tutorialKeys = @[ LMTutorialKeyBottomNavigation, LMTutorialKeyMiniPlayer, LMTutorialKeyTopBar ];
			for(NSInteger i = 0; i < tutorialKeys.count; i++){
				NSString *key = tutorialKeys[i];
				NSString *nextKey = (i+1 < tutorialKeys.count) ? tutorialKeys[i+1] : key;
				if(![LMTutorialView tutorialShouldRunForKey:key] && [LMTutorialView tutorialShouldRunForKey:nextKey]){
					[self tutorialFinishedWithKey:key];
				}
			}
		}
	} repeats:NO];
	
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
//		LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
//		LMPlaylist *playlist = [LMPlaylist new];
////		playlist.title = @"Nice meme";
////		playlist.image = [LMAppIcon imageForIcon:LMIconBug];
////		playlist.trackCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums].firstObject;
//		playlistViewController.playlist = playlist;
//		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:playlistViewController];
//		[self presentViewController:navigation animated:YES completion:^{
//
//		}];
		
		
//		LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
//		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
//		[self presentViewController:navigation animated:YES completion:^{
//
//		}];

		
		if(self.restorationState != LMCoreViewControllerRestorationStateNotRestored){
			[self.buttonNavigationBar setSelectedTab:self.stateRestoredNavigationTab];
		}
		else{
			[self.buttonNavigationBar setSelectedTab:LMNavigationTabMiniplayer];
		}
		
		if(self.stateRestoredNavigationBarWasMinimized){
			[self.buttonNavigationBar minimize:NO];
		}
		
		if(self.navigationController.navigationBar.items.count > 1){
			[self.buttonNavigationBar completelyHide];
		}
		
		if(self.restorationState == LMCoreViewControllerRestorationStateNowPlaying){
			[self launchNowPlayingFromNavigationBar];
		}
		
		if(self.previousTitleViewTopPersistentID > 0){
			[self.titleView scrollToTrackWithPersistentID:self.previousTitleViewTopPersistentID];
		}
		
		if(self.titleView.favourites && (self.currentSource == self.titleView)){
			[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
		}
		
		if(self.previouslyOpenedDetailViewIndex > -1 && self.previouslyOpenedDetailViewIndex < self.compactView.musicTrackCollections.count){
			[self.compactView scrollViewToIndex:self.previouslyOpenedDetailViewIndex];
			NSInteger rowLimit = [LMLayoutManager amountOfCollectionViewItemsPerRowForScreenSizeClass:LMScreenSizeClassPhone isLandscape:NO];
			if(![LMLayoutManager isLandscape] && (self.previouslyOpenedDetailViewIndex < self.compactView.musicTrackCollections.count - rowLimit)){
#warning this is a temporay fix for a crash that occurs if a detail view is open on the last row. at the time I do not have the time or the fucks to give to fix this so I will fix it later, hopefully.
				[self.compactView tappedBigListEntryAtIndex:self.previouslyOpenedDetailViewIndex];
			}
		}
		
//		LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//		[self.navigationController pushViewController:settingsViewController animated:YES];
		
//		LMThemePickerViewController *themePicker = [LMThemePickerViewController new];
//		[self.navigationController pushViewController:themePicker animated:YES];
		
//		UIViewController *controller = [
		
//		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//		LMSettingsViewController *settingsViewController = (LMSettingsViewController*)[storyboard instantiateViewControllerWithIdentifier:@"LMSettingsViewController"];
//		[self.navigationController pushViewController:settingsViewController animated:YES];
	} repeats:NO];
	
	
	NSTimeInterval loadEndTime = [[NSDate new] timeIntervalSince1970];
	NSLog(@"Loaded view in %f seconds.", loadEndTime-loadStartTime);
	
	
	//						[self setupBrowsingViewWithMusicType:LMMusicTypeArtists];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

