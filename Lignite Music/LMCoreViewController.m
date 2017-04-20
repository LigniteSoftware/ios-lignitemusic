//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <ApIdleManager/APIdleManager.h>

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
#import "LMTutorialView.h"

#ifdef SPOTIFY
#import "Spotify.h"
#endif

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate, LMPurchaseManagerDelegate, LMButtonNavigationBarDelegate, UINavigationBarDelegate, UINavigationControllerDelegate,
LMTutorialViewDelegate, LMImageManagerDelegate,

LMControlBarViewDelegate
>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingCoreView *nowPlayingCoreView;

@property LMTitleView *titleView;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property id currentSource;

@property UIView *statusBarBlurView;
@property NSLayoutConstraint *statusBarBlurViewHeightConstraint;
@property NSLayoutConstraint *statusBarBlurViewTopConstraint;

@property UIView *browsingAssistantViewAttachedTo;

@property LMSearchViewController *searchViewController;

@property NSArray *musicCollectionsArray;

@property UINavigationItem *itemPopped;

/**
 The time stamp for syncing.
 */
@property NSTimeInterval syncTimeStamp;

@property BOOL loaded;

@property LMPurchaseManager *purchaseManager;

/**
 The height constraint for the navigation bar.
 */
@property NSLayoutConstraint *buttonNavigationBarHeightConstraint;

@property CGPoint originalPoint, currentPoint;

@property LMCompactBrowsingView *compactView;

@property NSInteger settingsOpen;
@property BOOL willOpenSettings;
@property NSTimer *settingsCheckTimer; //for activity checks

@property LMLayoutManager *layoutManager;

@property UIImageView *splashImageView;

@end

@implementation LMCoreViewController

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
                tutorialView.leadingLayoutConstraint = [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
                tutorialView.delegate = self;
                [tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
                [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTop];
                [tutorialView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonNavigationBar withOffset:LMNavigationBarGrabberHeight];
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
                tutorialView.leadingLayoutConstraint = [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
                tutorialView.delegate = self;
                [tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
                [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                [tutorialView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.navigationBar];
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
    
    if(!self.buttonNavigationBar.isCompletelyHidden){
        [self.buttonNavigationBar maximize];
        [self.buttonNavigationBar setSelectedTab:LMNavigationTabMiniplayer];
    }
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
	self.compactView.musicType = musicType;
	
	[self.compactView reloadContents];
	
	NSLog(@"Done setting up");
	
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
	
	return self.nowPlayingCoreView.isOpen;
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
	
	int indexOfSource = -1;
	
	for(int i = 0; i < self.sourcesForSourceSelector.count; i++){
		LMSource *indexSource = [self.sourcesForSourceSelector objectAtIndex:i];
		if([source isEqual:indexSource]){
			indexOfSource = i;
			break;
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
			
			[self.compactView reloadSourceSelectorInfo];
			break;
		}
		case LMIconTitles: {
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			[self.titleView reloadSourceSelectorInfo];
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
            
			[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
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
//	NSLog(@"View did appear animated %d", animated);
	
//	[self attachNavigationBarToView:self.navigationController.view];
	
	self.currentDetailViewController = nil;
	self.searchViewController = nil;
	
	self.buttonNavigationBar.hidden = NO;
	
	if(self.statusBarBlurViewHeightConstraint.constant < 0.1 && ![self prefersStatusBarHidden]){
		[self setStatusBarBlurHidden:NO];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:NO];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:YES];
}

- (void)setStatusBarBlurHidden:(BOOL)hidden {
	[self.navigationController.view layoutIfNeeded];
	
	self.statusBarBlurViewHeightConstraint.constant = hidden ? 0 : 20;
	
	if(self.currentDetailViewController){
		[UIView animateWithDuration:0.25 animations:^{
			[self.currentDetailViewController setNeedsStatusBarAppearanceUpdate];
		}];
		if(self.currentDetailViewController.nextDetailViewController){
			[UIView animateWithDuration:0.25 animations:^{
				[self.currentDetailViewController.nextDetailViewController setNeedsStatusBarAppearanceUpdate];
			}];
		}
	}
	
	[UIView animateWithDuration:0.25 animations:^{
//		[self setNeedsStatusBarAppearanceUpdate];
		[self.navigationController.view layoutIfNeeded];
	}];
}

- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration {
//	NSLog(@"rHeight changed to %f", requiredHeight);
	
	
	[self.navigationController.view layoutIfNeeded];
	self.buttonNavigationBarHeightConstraint.constant = requiredHeight;
    [self.navigationController.view layoutIfNeeded];
    
    CGFloat bottomSpacing = requiredHeight + 10;
    [self.compactView changeBottomSpacing:bottomSpacing];
    self.titleView.songListTableView.bottomSpacing = bottomSpacing;
    if(self.currentDetailViewController){
        self.currentDetailViewController.browsingDetailView.tableView.bottomSpacing = bottomSpacing;
        if(self.currentDetailViewController.nextDetailViewController){
            self.currentDetailViewController.nextDetailViewController.browsingDetailView.tableView.bottomSpacing = bottomSpacing;
        }
    }
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
        [self.buttonNavigationBar maximize];
        
        [self.settingsCheckTimer invalidate];
        self.settingsCheckTimer = nil;
        
        if(![self prefersStatusBarHidden] && self.statusBarBlurViewTopConstraint.constant < 0){
            [self.navigationController.view layoutIfNeeded];
            
//            self.statusBarBlurViewTopConstraint.constant = 0;
            
            [UIView animateWithDuration:0.5 animations:^{
                [self.navigationController.view layoutIfNeeded];
            }];
        }
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
				[self setStatusBarBlurHidden:self.nowPlayingCoreView.isOpen];
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
		
		if((-translation.y <= self.nowPlayingCoreView.frame.size.height/10.0)){
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
					[self setStatusBarBlurHidden:self.nowPlayingCoreView.isOpen];
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

- (UIResponder *)nextResponder {
    [[APIdleManager sharedInstance] didReceiveInput];
    return [super nextResponder];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	self.layoutManager.traitCollection = self.traitCollection;
	[self.layoutManager traitCollectionDidChange:previousTraitCollection];
	
	self.splashImageView.image = [UIImage imageNamed:self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? @"splash_landscape_lighter.png" : @"splash_wings.png"];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[self.layoutManager rootViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	NSLog(@"Starting rotation");
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotating");
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotated");
		
		UITraitCollection *previousCollection = self.traitCollection;
		self.layoutManager.traitCollection = self.traitCollection;
		[self.layoutManager traitCollectionDidChange:previousCollection];
		
		self.layoutManager.size = self.view.frame.size;
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
	
//	self.view.backgroundColor = [UIColor lightGrayColor];
	
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	
	self.loaded = NO;
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	self.layoutManager.traitCollection = self.traitCollection;
	self.layoutManager.size = self.view.frame.size;
	
	
#ifdef SPEED_DEMON_MODE
	[UIView setAnimationsEnabled:NO];
#endif
	
	
	NSLog(@"Frame set %@", NSStringFromCGRect(self.view.frame));
	
//	LMControlBarView *controlBarTest = [LMControlBarView newAutoLayoutView];
//	controlBarTest.delegate = self;
//	controlBarTest.backgroundColor = [UIColor orangeColor];
//	[self.view addSubview:controlBarTest];
//	
//	[controlBarTest autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[controlBarTest autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[controlBarTest autoAlignAxisToSuperviewAxis:ALAxisVertical];
//	[controlBarTest autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/9.0)];
//	
//	[controlBarTest setup];
//	
//	return;
//	
//	LMCompactBrowsingView *compactBrowsingView = [LMCompactBrowsingView newAutoLayoutView];
//	[self.view addSubview:compactBrowsingView];
//	
//	[compactBrowsingView autoPinEdgesToSuperviewEdges];
//	
//	return;
	
//	LMMiniPlayerView *miniplayerTest = [LMMiniPlayerView newAutoLayoutView];
//	[self.view addSubview:miniplayerTest];
//	
//	[miniplayerTest autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
//	[miniplayerTest autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
//	[miniplayerTest autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
//	[miniplayerTest autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.20];
//
//	[miniplayerTest setup];

	
//	LMNowPlayingCoreView *coreView = [LMNowPlayingCoreView newAutoLayoutView];
//	[self.view addSubview:coreView];
//	
//	[coreView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
//	[coreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
//	[coreView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
//	[coreView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:1.0];
//
//	return;

//	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
//
//	NSArray *ids = @[ @(5172712687844084401), @(5172712687844084402), @(5172712687844084400), @(5172712687844084404),
//					  @(5172712687844084399), @(5172712687844084405), @(5172712687844084406), @(5172712687844084408) ];
//	NSInteger itemCount = 0;
//	
//	for(NSNumber *theid in ids){
//		MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:theid forProperty:MPMediaItemPropertyPersistentID];
//		
//		MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];
//		
//		NSArray *items = mediaQuery.items;
//		for(MPMediaItem *item in items){
//			itemCount++;
//			NSLog(@"Got item %@", item.title);
//		}
//	}
//	
//	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
//	
//	NSLog(@"Got %ld items in %f seconds.", itemCount, endTime-startTime);
	
//	
//	NSArray *collections = mediaQuery.collections;
//	for(MPMediaItemCollection *collection in collections){
//		NSArray *items = collection.items;
//		for(MPMediaItem *item in items){
//			NSLog(@"Item %@", item.title);
//		}
//	}
	
//	return;
	    
	self.splashImageView = [UIImageView newAutoLayoutView];
	self.splashImageView.image = [UIImage imageNamed:self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? @"splash_landscape_lighter.png" : @"splash_wings.png"];
	self.splashImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:self.splashImageView];
	
	[self.splashImageView autoPinEdgesToSuperviewEdges];
    
    //If user is using an iPad
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]){
        LMAlertView *alertView = [LMAlertView newAutoLayoutView];
        alertView.title = NSLocalizedString(@"OhBoy", nil);
        alertView.body = NSLocalizedString(@"NoiPadSupport", nil);
        alertView.alertOptionColours = @[];
        alertView.alertOptionTitles = @[];
        [alertView launchOnView:self.view withCompletionHandler:nil];
        
        return;
    }
	    
//#ifdef SPOTIFY
//	[[LMSpotifyLibrary sharedLibrary] buildDatabase];
//#endif
//	
//	
//	return;
    
    
    
//    [[LMImageManager sharedImageManager] testDownloadWithCallback:^(UIImage *croppedImage) {
//        UIImageView *hangOnImage = [UIImageView newAutoLayoutView];
//        hangOnImage.image = croppedImage;
//        hangOnImage.contentMode = UIViewContentModeScaleAspectFill;
//        [self.view addSubview:hangOnImage];
//        
//        [hangOnImage autoCenterInSuperview];
//        [hangOnImage autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
//        [hangOnImage autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view];
//    }];
//    
//    return;
    
    
//    if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyBottomNavigation] || true){
//        LMTutorialView *tutorialView = [[LMTutorialView alloc] initForAutoLayoutWithTitle:NSLocalizedString(@"TutorialBottomNavigationTitle", nil)
//                                                                              description:NSLocalizedString(@"TutorialBottomNavigationDescription", nil)
//                                                                                      key:LMTutorialKeyBottomNavigation];
//        [self.view addSubview:tutorialView];
//        tutorialView.boxAlignment = LMTutorialViewAlignmentBottom;
//        tutorialView.arrowAlignment = LMTutorialViewAlignmentTop;
//        tutorialView.icon = [LMAppIcon imageForIcon:LMIconBug];
//        tutorialView.leadingLayoutConstraint = [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//        [tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
//        [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//        [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//    }
//    else{
//        NSLog(@":)");
//    }
	
#ifdef SPOTIFY
	SPTAuth *authorization = [SPTAuth defaultInstance];
	SPTSession *session = authorization.session;
	
	if(!session.isValid){
		NSLog(@"Session isn't valid, renewing first.");
		[authorization renewSession:session callback:^(NSError *error, SPTSession *newSession) {
			if(error){
				NSLog(@"Error renewing session: %@", error);
				return;
			}
			
			authorization.session = newSession;
			
			[self viewDidLoad];
		}];
		return;
	}
	else{
		NSLog(@"Spotify session is valid!");
	}
#endif
	
//	self.titleView = [LMTitleView newAutoLayoutView];
//	self.titleView.backgroundColor = [UIColor redColor];
//	[self.view addSubview:self.titleView];
//	
//	[self.titleView autoPinEdgesToSuperviewEdges];
//	
//	[self.titleView setup];
////	self.titleView.hidden = YES;
//	
//	return;
	
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

#ifdef SPOTIFY
						NSArray *sourceTitles = @[
												  @"Artists", @"Albums", @"Titles", @"Playlists", @"Settings", @"ReportBugOrSendFeedback"
												  ];
						NSArray *sourceSubtitles = @[
													 @"", @"", @"", @"", @"", @""
													 ];
						LMIcon sourceIcons[] = {
							LMIconArtists, LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconSettings, LMIconBug
						};
						BOOL notHighlight[] = {
							NO, NO, NO, NO, YES, YES
						};
#else
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
#endif
						
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
						
						
						
						self.navigationBar = [LMNavigationBar newAutoLayoutView];
						self.navigationBar.delegate = self;
						[self.navigationController.view addSubview:self.navigationBar];
						
						//						self.navigationController.navigationBar
						
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						
						self.navigationBar.barTintColor = [UIColor whiteColor];
						self.navigationBar.tintColor = [UIColor blackColor];
						self.navigationBar.translucent = NO;
						
						self.navigationBar.layer.shadowColor = [UIColor blackColor].CGColor;
						self.navigationBar.layer.shadowRadius = WINDOW_FRAME.size.width / 45 / 2;
						self.navigationBar.layer.shadowOffset = CGSizeMake(0, self.navigationBar.layer.shadowRadius/2);
						self.navigationBar.layer.shadowOpacity = 0.25f;
						
						//						UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Hey" style:UIBarButtonItemStylePlain target:self action:nil];
						
						
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
						//						navigationItem.rightBarButtonItem = barButtonItem;
						
						[self.navigationBar pushNavigationItem:navigationItem animated:YES];
						
						self.navigationController.delegate = self;
						
						
						
						
						self.buttonNavigationBar = [LMButtonNavigationBar newAutoLayoutView];
						self.buttonNavigationBar.rootViewController = self;
						self.buttonNavigationBar.sourcesForSourceSelector = self.sourcesForSourceSelector;
						self.buttonNavigationBar.delegate = self;
						self.buttonNavigationBar.searchBarDelegate = self;
						self.buttonNavigationBar.letterTabBarDelegate = self;
						[self.navigationController.view addSubview:self.buttonNavigationBar];
						
						[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
						self.buttonNavigationBarHeightConstraint = [self.buttonNavigationBar autoSetDimension:ALDimensionHeight toSize:0.0];
						
						self.musicPlayer.navigationBar = self.buttonNavigationBar;
						
						
//						UIPanGestureRecognizer *miniPlayerDragUpPanGesture =
//							[[UIPanGestureRecognizer alloc] initWithTarget:self
//																	action:@selector(panNowPlayingUp:)];
//						miniPlayerDragUpPanGesture.delegate = self;
//						[self.buttonNavigationBar.miniPlayerView addGestureRecognizer:miniPlayerDragUpPanGesture];
//						
						
						
						self.nowPlayingCoreView = [LMNowPlayingCoreView newAutoLayoutView];
						self.nowPlayingCoreView.rootViewController = self;
						[self.navigationController.view addSubview:self.nowPlayingCoreView];
						
						[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						self.nowPlayingCoreView.topConstraint = [self.nowPlayingCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height];
						[self.nowPlayingCoreView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view];
						
						
						
						self.titleView = [LMTitleView newAutoLayoutView];
						self.titleView.backgroundColor = [UIColor whiteColor];
                        self.titleView.rootViewController = self;
						[self.view addSubview:self.titleView];

						[self.titleView autoPinEdgesToSuperviewEdges];

						[self.titleView setup];
						self.titleView.hidden = YES;
						
						
						
						self.compactView = [LMCompactBrowsingView newAutoLayoutView];
						self.compactView.rootViewController = self;
						[self.view addSubview:self.compactView];
						
						[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
						[self.compactView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
						//Stuck on the road with no place to call home, had to just learn the whole game on my own!
						self.compactView.hidden = NO;
		
				
						[self.musicPlayer addMusicDelegate:self];
						
						
//						[NSTimer scheduledTimerWithTimeInterval:1.0
//														 target:self selector:@selector(showWhatsPoppin) userInfo:nil repeats:NO];
						
//						UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
						self.statusBarBlurView = [UIView newAutoLayoutView];
						self.statusBarBlurView.backgroundColor = [UIColor whiteColor];
//						self.statusBarBlurView.translatesAutoresizingMaskIntoConstraints = NO;
						
						[self.navigationController.view addSubview:self.statusBarBlurView];
						
						[self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						self.statusBarBlurViewTopConstraint = [self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						self.statusBarBlurViewHeightConstraint = [self.statusBarBlurView autoSetDimension:ALDimensionHeight toSize:20*[LMSettings shouldShowStatusBar]];
                        
                        [self.navigationBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.statusBarBlurView];

						
						LMImageManager *imageManager = [LMImageManager sharedImageManager];
						imageManager.viewToDisplayAlertsOn = self.navigationController.view;
                        [imageManager addDelegate:self];
						
						
						NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
						
						NSLog(@"Took %f seconds.", (endTime-startTime));
						
//						NSLog(@"Nice algorithm %@", [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:[self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums]
//																									 withAssociatedMusicType:LMMusicTypeAlbums]);
						
						self.loaded = YES;
						
						[UIView animateWithDuration:0.25 animations:^{
							[self setNeedsStatusBarAppearanceUpdate];
						}];
                        
                        [APIdleManager sharedInstance].onTimeout = ^(void){
                            if(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying){
                                [self launchNowPlayingFromNavigationBar];
                            }
                        };
                        
//                        NSUserDefaults* suserDefaults = [NSUserDefaults standardUserDefaults];
//                        [suserDefaults removeObjectForKey:LMTutorialKeyTopBar];
//                        [suserDefaults removeObjectForKey:LMTutorialKeyMiniPlayer];
//                        [suserDefaults removeObjectForKey:LMTutorialKeyBottomNavigation];
//                        [suserDefaults removeObjectForKey:LMTutorialKeyNowPlaying];
//                        [suserDefaults removeObjectForKey:@"LMTutorialViewDontShowHintsKey"];
//                        [suserDefaults synchronize];
						
                        
                        [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
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
                                tutorialView.leadingLayoutConstraint = [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
                                tutorialView.delegate = self;
                                [tutorialView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
                                [tutorialView autoPinEdgeToSuperviewEdge:ALEdgeTop];
                                [tutorialView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonNavigationBar withOffset:LMNavigationBarGrabberHeight];
                            }
                        } repeats:NO];
                        
                        
//						[self musicLibraryDidChange];
						
//						[self launchNowPlayingFromNavigationBar];
						
						[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
//							LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//							settingsViewController.coreViewController = self;
//							[self.navigationController pushViewController:settingsViewController animated:YES];
							
//							[self.buttonNavigationBar completelyHide];
//							self.buttonNavigationBar.hidden = YES;
//							self.nowPlayingCoreView.hidden = YES;
						} repeats:NO];
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
