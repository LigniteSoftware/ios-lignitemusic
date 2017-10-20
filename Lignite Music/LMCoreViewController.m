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
#import "LMPurchaseManager.h"
#import "UIColor+isLight.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "MBProgressHUD.h"
#import "APIdleManager.h"
#import "LMMusicPlayer.h"
#import "LMAppDelegate.h"
#import "LMSearchView.h"
#import "LMAlertView.h"
#import "LMTitleView.h"
#import "LMSettings.h"
#import "LMAnswers.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMSource.h"

#import "LMLagDetectionThread.h"

#import "LMFeedbackViewController.h"
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

#ifdef SPOTIFY
#import "Spotify.h"
#endif

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

#define LMNavigationBarItemsKey @"LMNavigationBarItemsKey"
#define LMNowPlayingWasOpen @"LMNowPlayingWasOpen"

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate, LMPurchaseManagerDelegate, LMButtonNavigationBarDelegate, UINavigationBarDelegate, UINavigationControllerDelegate,
LMTutorialViewDelegate, LMImageManagerDelegate, LMLandscapeNavigationBarDelegate,

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

@property LMPurchaseManager *purchaseManager;

@property CGPoint originalPoint, currentPoint;

@property LMCompactBrowsingView *compactView;

@property NSInteger settingsOpen;
@property BOOL willOpenSettings;
@property NSTimer *settingsCheckTimer; //for activity checks

@property LMLayoutManager *layoutManager;

@property UIImageView *splashImageView;

/**
 The view which goes in the background to blur out the rest of the app.
 */
@property UIVisualEffectView *backgroundBlurView;

@property NSArray<UINavigationItem*> *statePreservedNavigationBarItems;

@property BOOL statePreservedNowPlayingWasOpen;

@property UIActivityIndicatorView *loadingActivityIndicator;
@property UILabel *loadingLabel;

@property UIButton *navigationBarWarningButton;

@end

@implementation LMCoreViewController

@dynamic navigationController;

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

- (void)warningBarButtonItemTapped {
	NSLog(@"Tapped warning");
	
	[[LMImageManager sharedImageManager] launchExplicitPermissionRequestOnView:self.navigationController.view
				  withCompletionHandler:^(LMImageManagerPermissionStatus permissionStatus) {
					  if(permissionStatus == LMImageManagerPermissionStatusAuthorized) {
						  NSLog(@"Cleared!");
					  }
				  }];
}

- (void)setWarningButtonShowing:(BOOL)showing {
	//Set custom warning button onto navigationBar
	if(!self.navigationBarWarningButton){
		UIButton *iconWarningView = [UIButton newAutoLayoutView];
		iconWarningView.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[iconWarningView setImage:[LMAppIcon imageForIcon:LMIconWarning] forState:UIControlStateNormal];
		[iconWarningView addTarget:self action:@selector(warningBarButtonItemTapped) forControlEvents:UIControlEventTouchUpInside];
		
		[self.navigationBar addSubview:iconWarningView];
		
		[iconWarningView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:6.0f];
		[iconWarningView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[iconWarningView autoSetDimension:ALDimensionHeight toSize:44.0f];
		[iconWarningView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:iconWarningView];
		
		self.navigationBarWarningButton = iconWarningView;
	}

	self.navigationBarWarningButton.hidden = !showing;
	
	
	//Set the landscape navigation bar to display the warning as well
	self.landscapeNavigationBar.showWarningButton = showing;
}

- (void)imageDownloadConditionLevelChanged:(LMImageManagerConditionLevel)newConditionLevel {
	switch(newConditionLevel){
		case LMImageManagerConditionLevelOptimal: {
			[self setWarningButtonShowing:NO];
			NSLog(@"Optimal!");
			break;
		}
		case LMImageManagerConditionLevelSuboptimal: {
			[self setWarningButtonShowing:YES];
			NSLog(@"Sub");
			break;
		}
		case LMImageManagerConditionLevelNever: {
			[self setWarningButtonShowing:NO];
			NSLog(@"Never");
			break;
		}
	}
}

- (void)tutorialFinishedWithKey:(NSString *)key {
    NSLog(@"Tutorial %@ finished, start another?", key);
    
    self.view.userInteractionEnabled = YES;
    self.buttonNavigationBar.userInteractionEnabled = YES;
    self.navigationBar.userInteractionEnabled = YES;
	
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
                self.navigationBar.userInteractionEnabled = NO;
                
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
					[tutorialView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.navigationBar];
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

- (void)appOwnershipStatusChanged:(LMPurchaseManagerAppOwnershipStatus)newOwnershipStatus {
	NSLog(@"The app ownership status changed:");
	switch(newOwnershipStatus){
		case LMPurchaseManagerAppOwnershipStatusInTrial:
			NSLog(@"The user is currently in trial.");
			break;
		case LMPurchaseManagerAppOwnershipStatusTrialExpired: {
			NSLog(@"The user's trial has expired.");
			[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
				[self.purchaseManager showPurchaseViewControllerOnViewController:self.navigationController present:YES];
			} repeats:NO];
			break;
		}
		case LMPurchaseManagerAppOwnershipStatusPurchased:
			NSLog(@"The user purchased the app.");
			break;
		case LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker:
			NSLog(@"The user is logged in as a backer.");
			break;
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
}

- (void)trackRemovedFromFavourites:(LMMusicTrack *)track {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_favourite_hud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"Un-favourited", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
}

#ifndef SPOTIFY
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
#endif

- (void)reloadCurrentBrowsingView {
	if(self.currentSource == self.titleView){
		[self.titleView rebuildTrackCollection];
	}
	else{
		[self setupBrowsingViewWithMusicType:[self.currentSource musicType]];
	}
}

- (void)setupBrowsingViewWithMusicType:(LMMusicType)musicType {
#ifdef SPOTIFY
	self.browsingView.musicTrackCollections = [self.musicPlayer queryCollectionsForMusicType:musicType];
#else
	if(self.musicCollectionsArray){
		NSLog(@"Loading music from cache.");
		self.compactView.musicTrackCollections = [self.musicCollectionsArray objectAtIndex:musicType];
	}
	else{
		NSLog(@"Loading music directly.");
		self.compactView.musicTrackCollections = [self.musicPlayer queryCollectionsForMusicType:musicType];
	}
#endif
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
	
	return self.nowPlayingCoreView.isOpen || self.layoutManager.isLandscape || (![LMLayoutManager isiPad] && self.buttonNavigationBar.currentlySelectedTab == LMNavigationTabView && !self.buttonNavigationBar.isMinimized && !self.buttonNavigationBar.isCompletelyHidden);
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
			
			[self logMusicTypeView:associatedMusicType];
			
			NSLog(@"Type %d", associatedMusicType);
			
			[self setupBrowsingViewWithMusicType:associatedMusicType];
			
			self.currentSource = self.compactView;
			break;
		}
		case LMIconTitles: {
			BOOL requiresReload = self.titleView.favourites == YES;
			
			self.titleView.favourites = NO;
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			if(requiresReload){
				[self.titleView rebuildTrackCollection];
				[self.titleView.songListTableView reloadSubviewData];
				[self.titleView.songListTableView reloadData];
			}
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeTitles];
			break;
		}
		case LMIconFavouriteBlack: {
			BOOL requiresReload = self.titleView.favourites == NO;
			
			self.titleView.favourites = YES;
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			if(requiresReload){
				[self.titleView rebuildTrackCollection];
				[self.titleView.songListTableView reloadSubviewData];
				[self.titleView.songListTableView reloadData];
			}
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeFavourites];
			break;
		}
		case LMIconSettings: {
            self.settingsCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                [[APIdleManager sharedInstance] didReceiveInput];
            } repeats:YES];
            
			[self.buttonNavigationBar completelyHide];
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			[self.navigationController pushViewController:settingsViewController animated:YES];
			break;
		}
		case LMIconBug: {
//			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.lignite.io/feedback/"]];
			LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
			[self.navigationController presentViewController:feedbackController animated:YES completion:nil];
			NSLog(@"Debug menu");
			break;
		}
		default:
			NSLog(@"Unknown index of source %@.", source);
			break;
	}
}

- (void)prepareForOpenSettings {
	if(!self.buttonNavigationBar){
		self.statePreservedSettingsAlreadyOpen = YES;
	}
	else{
		self.willOpenSettings = YES;
		[self.buttonNavigationBar completelyHide];
		if(!self.statePreservedSettingsAlreadyOpen && self.settingsOpen == 0){
			[self pushItemOntoNavigationBarWithTitle:NSLocalizedString(@"Settings", nil) withNowPlayingButton:NO];
		}
		self.statePreservedSettingsAlreadyOpen = NO;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	self.searchViewController = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:NO];
	[self.landscapeNavigationBar setMode:LMLandscapeNavigationBarModeWithBackButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:YES];
	[self.landscapeNavigationBar setMode:LMLandscapeNavigationBarModeOnlyLogo];
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

//http://stackoverflow.com/questions/18946302/uinavigationcontroller-interactive-pop-gesture-not-working
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//	NSLog(@"%@ work with %@", [[gestureRecognizer class] description], [[otherGestureRecognizer class]description]);
	return [otherGestureRecognizer class] != [UIPanGestureRecognizer class];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	NSLog(@"Changed to %@", searchTerm);
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	NSLog(@"Search was opened: %d", opened);
	
	if(!self.searchViewController){
//		[self attachBrowsingAssistantToView:self.view];
		
		self.searchViewController = [LMSearchViewController new];
		self.searchViewController.searchSelectedDelegate = self;
		[self.navigationController presentViewController:self.searchViewController animated:YES completion:nil];
	}
}

- (void)searchEntryTappedWithPersistentID:(LMMusicTrackPersistentID)persistentID withMusicType:(LMMusicType)musicType {
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
		
        [self.settingsCheckTimer invalidate];
        self.settingsCheckTimer = nil;
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
	
	if(![item isEqual:self.itemPopped]){ //Pressed back instead of swipped back
		NSLog(@"Dismissing shit too");
		[self.navigationController popViewControllerAnimated:YES];
	}
	
	self.itemPopped = nil;
		
	return YES;
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

- (void)pushItemOntoNavigationBarWithTitle:(NSString*)title withNowPlayingButton:(BOOL)nowPlayingButton {
	UINavigationItem *navigationItem = [[UINavigationItem alloc]initWithTitle:title];
	
	if(nowPlayingButton){
		UIImageView *titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
		titleImageView.contentMode = UIViewContentModeScaleAspectFit;
		titleImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		titleImageView.userInteractionEnabled = YES;
		
		UITapGestureRecognizer *nowPlayingTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(launchNowPlayingFromNavigationBar)];
		[titleImageView addGestureRecognizer:nowPlayingTapGestureRecognizer];
		
		UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc]initWithCustomView:titleImageView];
		
		navigationItem.rightBarButtonItem = barButtonItem;
	}
    
//    if([title isEqualToString:@""]){
//        [self.navigationController.view layoutIfNeeded];
//        
////        self.statusBarBlurViewTopConstraint.constant = -20 - self.navigationBar.frame.size.height - 15;
//        
//        [UIView animateWithDuration:0.5 animations:^{
//            [self.navigationController.view layoutIfNeeded];
//        }];
//    }
	
	[self.navigationBar pushNavigationItem:navigationItem animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	//Check if swipe gesture backward went through or not, if it did, pop the nav item
	id<UIViewControllerTransitionCoordinator> tc = navigationController.topViewController.transitionCoordinator;
	[tc notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		if(![context isCancelled]){
			NSLog(@"Shit");
			self.itemPopped = self.navigationBar.topItem;
			[self.navigationBar popNavigationItemAnimated:YES];
			NSLog(@"Is this anybody's water? %@", self.itemPopped);
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
		
		self.navigationBar.hidden = NO;
		self.landscapeNavigationBar.hidden = NO;
		
		self.navigationBar.layer.opacity = willBeLandscape ? 0.0 : 1.0;
		self.landscapeNavigationBar.layer.opacity = !willBeLandscape ? 0.0 : 1.0;
		
		self.navigationBar.frame = CGRectMake(0, 20, size.width, willBeLandscape ? 0 : 64.0);
		
		self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.isOpen ? 0 : size.height;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotated");
		
		UITraitCollection *previousCollection = self.traitCollection;
		self.layoutManager.traitCollection = self.traitCollection;
		[self.layoutManager traitCollectionDidChange:previousCollection];
		
		self.layoutManager.size = self.view.frame.size;
				
		self.navigationBar.hidden = willBeLandscape;
		self.landscapeNavigationBar.hidden = !willBeLandscape;
		
		
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
			
			if(self.navigationBar.backItem){
				[self.navigationBar popNavigationItemAnimated:NO];
			}
			else{
				[self.compactView backButtonPressed];
			}
			break;
		}
		case LMLandscapeNavigationBarButtonWarning: {
			[self warningBarButtonItemTapped];
			break;
		}
		case LMLandscapeNavigationBarButtonLogo: {
			NSLog(@"Now playing nav bar please");
			
			[self launchNowPlayingFromNavigationBar];
			break;
		}
	}
}

- (void)handlePopGesture:(UIGestureRecognizer *)gesture{
	if(self.navigationController.topViewController == self){
		if(gesture.state == UIGestureRecognizerStateEnded){
			[self.navigationBar popNavigationItemAnimated:YES];
		}
	}
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	NSLog(@"What boi encoding %@", self.navigationBar.items);
	
	[coder encodeObject:self.navigationBar.items forKey:LMNavigationBarItemsKey];
	[coder encodeBool:self.nowPlayingCoreView.isOpen forKey:LMNowPlayingWasOpen];
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	NSLog(@"What boi!! got %@", [coder decodeObjectForKey:LMNavigationBarItemsKey]);
	
	NSArray *navigationBarItems = [coder decodeObjectForKey:LMNavigationBarItemsKey];
	NSMutableArray *approvedNavigationBarItems = [NSMutableArray new];
	[approvedNavigationBarItems addObject:[self nowPlayingNavigationItem]];
	for(UINavigationItem *navigationItem in navigationBarItems){
		if(navigationItem.title != nil){
			[approvedNavigationBarItems addObject:navigationItem];
		}
		NSLog(@"Nav bar item '%@' '%@' %@", navigationItem.title, navigationItem.titleView, self.navigationBar);
	}
	
	NSLog(@"Preserved %@", approvedNavigationBarItems);
	
	self.statePreservedNavigationBarItems = [NSArray arrayWithArray:approvedNavigationBarItems];
//	self.statePreservedNowPlayingWasOpen = [coder decodeBoolForKey:LMNowPlayingWasOpen];
	
	[super decodeRestorableStateWithCoder:coder];
}

- (UINavigationItem*)nowPlayingNavigationItem {
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
		
		self.navigationController.navigationBarHidden = YES;
		self.navigationController.interactivePopGestureRecognizer.delegate = self;
		[self.navigationController.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
		
		self.loaded = NO;
		
		if(!self.layoutManager){
			self.layoutManager = [LMLayoutManager sharedLayoutManager];
			self.layoutManager.traitCollection = self.traitCollection;
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
			
//			self.loadingProgressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
//			
//			self.loadingProgressHUD.mode = MBProgressHUDModeIndeterminate;
//			self.loadingProgressHUD.label.text = NSLocalizedString(@"LoadingMusic", nil);
//			self.loadingProgressHUD.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
//	//		self.loadingProgressHUD.progress = 0.1;
//			self.loadingProgressHUD.userInteractionEnabled = NO;
//			
//			dispatch_time_t changeLabelTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
//			dispatch_after(changeLabelTime, dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
//				self.loadingProgressHUD.label.text = @"Almost there...";
//			});
			
			NSLog(@"Launch main view controller contents");
			[NSTimer scheduledTimerWithTimeInterval:0.05 block:^{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self loadSubviews];
				});
			} repeats:NO];
		});
	}
}

- (void)loadSubviews {
	if(self.buttonNavigationBar){
		return;
	}

	
//	return;
	
//	self.loadingProgressHUD.hidden = YES;
	
	[self.loadingActivityIndicator stopAnimating];
	self.loadingLabel.hidden = YES;
	
	if(!self.layoutManager){
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		self.layoutManager.traitCollection = self.traitCollection;
		self.layoutManager.size = self.view.frame.size;
	}
	
	
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
							  @"Artists", @"Albums", @"Titles", @"Playlists", @"Genres", @"Compilations", @"Favourites", @"Settings", @"ReportBugOrSendFeedback"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"", @"", @"", @"", @"", @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconArtists, LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconGenres, LMIconCompilations, LMIconFavouriteBlack, LMIconSettings, LMIconBug
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
	self.purchaseManager = [LMPurchaseManager sharedPurchaseManager];
	[self.purchaseManager addDelegate:self];
	
	LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
	[pebbleManager attachToViewController:self];
	
	
	if(@available(iOS 11, *)){
		self.navigationBar = [[LMNavigationBar alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 64.0f)];
	}
	else{
		self.navigationBar = [[LMNavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64.0f)];
	}
	self.navigationBar.delegate = self;
	[self.navigationController.view addSubview:self.navigationBar];
	
	self.navigationBar.barTintColor = [UIColor whiteColor];
	self.navigationBar.tintColor = [UIColor blackColor];
	self.navigationBar.translucent = NO;
	
	self.navigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
	self.navigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
	self.navigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationBar.layer.shadowRadius/2);
	self.navigationBar.layer.shadowOpacity = 0.25f;
	
	if(self.statePreservedNavigationBarItems){
		[self.navigationBar setItems:self.statePreservedNavigationBarItems];
		self.settingsOpen = self.statePreservedNavigationBarItems.count-1;
		self.statePreservedNavigationBarItems = nil;
	}
	else{
		[self.navigationBar pushNavigationItem:[self nowPlayingNavigationItem] animated:YES];
	}
	
	
	
	
	self.landscapeNavigationBar = [[LMLandscapeNavigationBar alloc] initWithFrame:CGRectMake(0, 0, 64.0, self.layoutManager.isLandscape ? self.view.frame.size.height : self.view.frame.size.width)];
	self.landscapeNavigationBar.delegate = self;
	self.landscapeNavigationBar.mode = (self.navigationBar.items.count > 1) ? LMLandscapeNavigationBarModeWithBackButton : LMLandscapeNavigationBarModeOnlyLogo;
	[self.navigationController.view addSubview:self.landscapeNavigationBar];
	
	//						NSArray *landscapeNavigationBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
	//							[self.landscapeNavigationBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	//							[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	//							[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
	//							[self.landscapeNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	//						[self.landscapeNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.landscapeNavigationBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:64.0f]];
	//							[self.landscapeNavigationBar autoSetDimension:ALDimensionWidth toSize:64.0f];
	//						}];
	//						[LMLayoutManager addNewLandscapeConstraints:landscapeNavigationBarLandscapeConstraints];
	
	self.landscapeNavigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
	self.landscapeNavigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
	self.landscapeNavigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationBar.layer.shadowRadius/2);
	self.landscapeNavigationBar.layer.shadowOpacity = 0.25f;
	
	
	self.navigationBar.hidden = self.layoutManager.isLandscape;
	self.navigationBar.layer.opacity = self.navigationBar.hidden ? 0.0 : 1.0;
	//						self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.navigationBar.hidden ? 0 : 64.0f);
	self.landscapeNavigationBar.hidden = !self.layoutManager.isLandscape;
	self.landscapeNavigationBar.layer.opacity = self.landscapeNavigationBar.hidden ? 0.0 : 1.0;
	
	
	
	
	self.compactView = [LMCompactBrowsingView newAutoLayoutView];
	self.compactView.rootViewController = self;
	[self.view addSubview:self.compactView];
	
	NSArray *compactViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	}];
	[LMLayoutManager addNewPortraitConstraints:compactViewPortraitConstraints];
	
	NSArray *compactViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.compactView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:self.landscapeNavigationBar.frame.size.width];
		[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTop];
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
		[self.buttonNavigationBar autoPinEdgesToSuperviewEdges];
	}];
	[LMLayoutManager addNewPortraitConstraints:buttonNavigationBarPortraitConstraints];
	
	NSArray *buttonNavigationBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.buttonNavigationBar autoPinEdgesToSuperviewEdges];
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
	
	
	
	
	self.nowPlayingCoreView = [LMNowPlayingCoreView newAutoLayoutView];
	self.nowPlayingCoreView.rootViewController = self;
	[self.navigationController.view addSubview:self.nowPlayingCoreView];
	
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.nowPlayingCoreView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view];
	self.nowPlayingCoreView.topConstraint =
	[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height];
	
	
	
	
	
	
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	imageManager.viewToDisplayAlertsOn = self.navigationController.view;
	[imageManager addDelegate:self];
	
	
	
	self.loaded = YES;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self setNeedsStatusBarAppearanceUpdate];
	}];
	
	[APIdleManager sharedInstance].onTimeout = ^(void){
		if(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying){
			[self launchNowPlayingFromNavigationBar];
		}
	};
	
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
		self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
		self.backgroundBlurView.userInteractionEnabled = NO;
		[self.navigationController.view addSubview:self.backgroundBlurView];
		
		[self.backgroundBlurView autoPinEdgesToSuperviewEdges];
		
		[self.navigationController.view insertSubview:self.buttonNavigationBar aboveSubview:self.backgroundBlurView];
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
		[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
		
		if(self.statePreservedSettingsAlreadyOpen){
			[self prepareForOpenSettings];
		}
		if(self.navigationBar.items.count > 1){
			[self.buttonNavigationBar completelyHide];
		}
		
		if(self.statePreservedNowPlayingWasOpen){
			[self launchNowPlayingFromNavigationBar];
			self.statePreservedNowPlayingWasOpen = NO;
		}
		
		
//		LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
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
