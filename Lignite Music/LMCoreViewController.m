//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <ApIdleManager/APIdleManager.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "LMBrowsingDetailViewController.h"
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

#ifdef SPOTIFY
#import "Spotify.h"
#endif

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

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
        [self.compactView.collectionView reloadData];
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
	if(self.currentDetailViewController){
		[self.navigationBar popNavigationItemAnimated:NO];
		if(self.navigationBar.items.count > 1){
			[self.navigationBar popNavigationItemAnimated:NO];
		}
	}
	
	
	if(!source.shouldNotHighlight){
		[self.currentSource setHidden:YES];
		[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
		
		[self.buttonNavigationBar setCurrentSourceIcon:[[source.icon averageColour] isLight] ? source.icon : [LMAppIcon invertImage:source.icon]];
	}
	
	NSLog(@"New source %@", source.title);
	
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
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeTitles];
			break;
		}
		case LMIconSettings: {
			self.willOpenSettings = YES;
            self.settingsCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                [[APIdleManager sharedInstance] didReceiveInput];
            } repeats:YES];
            
			[self.buttonNavigationBar completelyHide];
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			settingsViewController.coreViewController = self;
			[self.navigationController pushViewController:settingsViewController animated:YES];
			
//			[self.buttonNavigationBar.browsingBar setShowingLetterTabs:NO];
			
			[self pushItemOntoNavigationBarWithTitle:NSLocalizedString(@"Settings", nil) withNowPlayingButton:NO];
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

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	self.currentDetailViewController = nil;
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
    if(!self.musicPlayer.nowPlayingTrack){
        return;
    }
    
	CGPoint translation = [recognizer translationInView:recognizer.view];
	
    NSLog(@"Dick is not a bone 哈哈哈");
    
	if(self.originalPoint.y == 0){
		self.originalPoint = self.view.frame.origin;
		self.currentPoint = self.nowPlayingCoreView.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
    NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.frame.size.height+translation.y;
	
	[self.nowPlayingCoreView.superview layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		[self.nowPlayingCoreView.superview layoutIfNeeded];
		
		if(translation.y > self.nowPlayingCoreView.frame.size.height/10.0){			
			if(translation.y > self.nowPlayingCoreView.frame.size.height/8.0){
				[self.buttonNavigationBar minimize:NO];
			}
			
			self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.frame.size.height;
			
			self.nowPlayingCoreView.isOpen = NO;
		}
		else{
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
		self.splashImageView.image = [UIImage imageNamed:@"splash_ipad.png"];
	}
	else{
		self.splashImageView.image = [UIImage imageNamed:[LMLayoutManager sharedLayoutManager].isLandscape ? @"splash_landscape_g.png" : @"splash_portrait_g.png"];
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
		
		self.navigationBar.frame = CGRectMake(0, 0, size.width, willBeLandscape ? 0 : 64.0);
		
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

- (void)buttonTappedOnLandscapeNavigationBar:(BOOL)backButtonPressed {
	if(backButtonPressed){
		NSLog(@"Go back");
		
//		[self.navigationController popViewControllerAnimated:YES];
		
		if(self.navigationBar.backItem){
			[self.navigationBar popNavigationItemAnimated:NO];
		}
	}
	else{
		NSLog(@"Now playing nav bar please");
		
		[self launchNowPlayingFromNavigationBar];
	}
}

- (void)handlePopGesture:(UIGestureRecognizer *)gesture{
	if(self.navigationController.topViewController == self){
		if(gesture.state == UIGestureRecognizerStateEnded){
			[self.navigationBar popNavigationItemAnimated:YES];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
	
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	[self.navigationController.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
	
	self.loaded = NO;
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	self.layoutManager.traitCollection = self.traitCollection;
	self.layoutManager.size = self.view.frame.size;
	
	
//	LMExpandableTrackListControlBar *testView = [LMExpandableTrackListControlBar newAutoLayoutView];
//	testView.backgroundColor = [UIColor orangeColor];
//	testView.mode = LMExpandableTrackListControlBarModeGeneralControl;
//	[self.view addSubview:testView];
//	
//	[testView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[testView autoCenterInSuperview];
//	[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/10.0)];
//	
//	return;
	
//	LMCompactBrowsingView *testView = [LMCompactBrowsingView newAutoLayoutView];
//	testView.backgroundColor = [UIColor orangeColor];
//	[self.view addSubview:testView];
//	
//	[testView autoPinEdgesToSuperviewEdges];
//	
//	return;
	
//	NSArray *testViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[testView autoPinEdgesToSuperviewEdges];
//	}];
//	[LMLayoutManager addNewPortraitConstraints:testViewPortraitConstraints];
//	
//	NSArray *testViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[testView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[testView autoCenterInSuperview];
//		[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.5];
//	}];
//	[LMLayoutManager addNewLandscapeConstraints:testViewLandscapeConstraints];
//	
//	NSArray *testViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[testView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[testView autoCenterInSuperview];
//		[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.75];
//	}];
//	[LMLayoutManager addNewiPadConstraints:testViewiPadConstraints];
//	
//	return;
	
	
//	LMButtonBar *buttonBar = [LMButtonBar newAutoLayoutView];
//	buttonBar.amountOfButtons = 3;
//	buttonBar.buttonIconsArray = @[ @(LMIconBrowse), @(LMIconMiniplayer), @(LMIconSource) ];
//	buttonBar.buttonScaleFactorsArray = @[ @(1.0/2.5), @(1.0/2.5), @(1.0/2.5) ];
//	buttonBar.buttonIconsToInvertArray = @[ @(LMNavigationTabBrowse), @(LMNavigationTabView) ];
////	buttonBar.delegate = self;
//	buttonBar.backgroundColor = [UIColor whiteColor];
//	[self.view addSubview:buttonBar];
//	
//	
//	NSArray *buttonBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.125];
//	}];
//	[LMLayoutManager addNewPortraitConstraints:buttonBarPortraitConstraints];
//	
//	NSArray *buttonBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.125];
//	}];
//	[LMLayoutManager addNewLandscapeConstraints:buttonBarLandscapeConstraints];
//	
//	
//	return;
	
	
#ifdef SPEED_DEMON_MODE
	[UIView setAnimationsEnabled:NO];
#endif
	
	
	NSLog(@"Frame set %@", NSStringFromCGRect(self.view.frame));
	
	    
	self.splashImageView = [UIImageView newAutoLayoutView];
	if([LMLayoutManager isiPad]){
		self.splashImageView.image = [UIImage imageNamed:@"splash_ipad.png"];
	}
	else{
		self.splashImageView.image = [UIImage imageNamed:[LMLayoutManager sharedLayoutManager].isLandscape ? @"splash_landscape_g.png" : @"splash_portrait_g.png"];
	}
	self.splashImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:self.splashImageView];
	
	[self.splashImageView autoPinEdgesToSuperviewEdges];
    
    //If user is using an iPad
//    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]){
//        LMAlertView *alertView = [LMAlertView newAutoLayoutView];
//        alertView.title = NSLocalizedString(@"OhBoy", nil);
//        alertView.body = NSLocalizedString(@"NoiPadSupport", nil);
//		alertView.alertOptionColours = @[];
//        alertView.alertOptionTitles = @[];
//        [alertView launchOnView:self.view withCompletionHandler:nil];
//        
//        return;
//    }
	
	
	NSArray *sourceTitles = @[
							  @"Artists", @"Albums", @"Titles", @"Playlists", @"Genres", @"Compilations", @"Settings", @"ReportBugOrSendFeedback"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"", @"", @"", @"", @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconArtists, LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconGenres, LMIconCompilations, LMIconSettings, LMIconBug
	};
	BOOL notHighlight[] = {
		NO, NO, NO, NO, NO, NO, YES, YES
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
	
	
#ifdef SKIP_ONBOARDING
	if(true == false){
		NSLog(@"Warning: Onboarding is disabled.");
#else
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if(![userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
#endif
		NSLog(@"User has not yet completed onboarding, launching onboarding.");
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(launchOnboarding) userInfo:nil repeats:NO];
	}
	else{
		[SKCloudServiceController requestAuthorization:^(SKCloudServiceAuthorizationStatus status) {
			switch(status){
				case SKCloudServiceAuthorizationStatusNotDetermined:
				case SKCloudServiceAuthorizationStatusRestricted:
				case SKCloudServiceAuthorizationStatusDenied: {
					//Launch tutorial on how to fix
					dispatch_async(dispatch_get_main_queue(), ^{
						LMGuideViewPagerController *guideViewPager = [LMGuideViewPagerController new];
						guideViewPager.guideMode = GuideModeMusicPermissionDenied;
						[self presentViewController:guideViewPager animated:YES completion:nil];
					});
					break;
				}
				case SKCloudServiceAuthorizationStatusAuthorized: {
					dispatch_async(dispatch_get_main_queue(), ^{
						NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
						
						self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
						self.purchaseManager = [LMPurchaseManager sharedPurchaseManager];
						[self.purchaseManager addDelegate:self];

						LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
						[pebbleManager attachToViewController:self];
						
						
						
						
						self.navigationBar = [[LMNavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64.0f)];
						self.navigationBar.delegate = self;
						[self.navigationController.view addSubview:self.navigationBar];
						
						self.navigationBar.barTintColor = [UIColor whiteColor];
						self.navigationBar.tintColor = [UIColor blackColor];
						self.navigationBar.translucent = NO;
						
						self.navigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
						self.navigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
						self.navigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationBar.layer.shadowRadius/2);
						self.navigationBar.layer.shadowOpacity = 0.25f;
						
						UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
						titleView.backgroundColor = [UIColor orangeColor];
						
						UIImageView *titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
						titleImageView.contentMode = UIViewContentModeScaleAspectFit;
						titleImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
						titleImageView.userInteractionEnabled = YES;
						
						UITapGestureRecognizer *nowPlayingTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(launchNowPlayingFromNavigationBar)];
						[titleImageView addGestureRecognizer:nowPlayingTapGestureRecognizer];
						
						UINavigationItem *navigationItem = [[UINavigationItem alloc]initWithTitle:@""];
						navigationItem.titleView = titleImageView;
						[self.navigationBar pushNavigationItem:navigationItem animated:YES];
						
						
						
						
						self.landscapeNavigationBar = [[LMLandscapeNavigationBar alloc] initWithFrame:CGRectMake(0, 0, 64.0, self.layoutManager.isLandscape ? self.view.frame.size.height : self.view.frame.size.width)];
						self.landscapeNavigationBar.delegate = self;
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
							[self.buttonNavigationBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(2.0/3.0)];
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
						
						
						NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
						
						NSLog(@"Took %f seconds.", (endTime-startTime));
						

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
                            if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyBottomNavigation]){
                                self.view.userInteractionEnabled = NO;
                                self.buttonNavigationBar.userInteractionEnabled = NO;
								
								
								self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
								[self.navigationController.view addSubview:self.backgroundBlurView];
								
								[self.backgroundBlurView autoPinEdgesToSuperviewEdges];
								
								
								[self.navigationController.view insertSubview:self.buttonNavigationBar aboveSubview:self.backgroundBlurView];
								[self.navigationController.view insertSubview:self.nowPlayingCoreView aboveSubview:self.buttonNavigationBar];
                                
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
                        } repeats:NO];
						
						
						[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
//							self.nowPlayingCoreView.hidden = YES;
//							
//							LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//							settingsViewController.coreViewController = self;
//							[self.navigationController pushViewController:settingsViewController animated:YES];
//							[self pushItemOntoNavigationBarWithTitle:NSLocalizedString(@"Settings", nil) withNowPlayingButton:NO];
							
//							self.landscapeNavigationBar.hidden = YES;
							
							[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
							
//							self.buttonNavigationBar.hidden = YES;
							
//							[self.buttonNavigationBar minimize:NO];
							
//							[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
							
//							self.navigationController.view.hidden = YES;
							
//							[self launchNowPlayingFromNavigationBar];
							
//							LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
//							[self.navigationController presentViewController:feedbackController animated:YES completion:nil];
						} repeats:NO];
						
						
//						[self setupBrowsingViewWithMusicType:LMMusicTypeArtists];
					});
					break;
				}
			}
		}];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
