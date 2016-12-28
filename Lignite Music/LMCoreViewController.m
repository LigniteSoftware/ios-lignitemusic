//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMBrowsingDetailViewController.h"
#import "LMGuideViewPagerController.h"
#import "LMNowPlayingViewController.h"
#import "LMSettingsViewController.h"
#import "LMSearchViewController.h"
#import "UIImage+AverageColour.h"
#import "LMCoreViewController.h"
#import "LMPurchaseManager.h"
#import "LMNavigationBar.h"
#import "UIColor+isLight.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "LMBrowsingView.h"
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
#import "LMProgressSlider.h"
#import "LMBrowsingBar.h"

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate, LMPurchaseManagerDelegate, LMNavigationBarDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingViewController *nowPlayingViewController;

@property LMBrowsingView *browsingView;
@property LMTitleView *titleView;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property NSMutableArray<NSLayoutConstraint*>*heightConstraintArray;

@property id currentSource;

@property UIVisualEffectView *statusBarBlurView;
@property NSLayoutConstraint *statusBarBlurViewHeightConstraint;

@property UIView *browsingAssistantViewAttachedTo;

@property LMSearchViewController *searchViewController;

@property NSArray *musicCollectionsArray;

/**
 The time stamp for syncing.
 */
@property NSTimeInterval syncTimeStamp;

@property BOOL loaded;

@property LMPurchaseManager *purchaseManager;

/**
 The navigation bar that goes at the bottom.
 */
@property LMNavigationBar *navigationBar;

/**
 The height constraint for the navigation bar.
 */
@property NSLayoutConstraint *navigationBarHeightConstraint;

@end

@implementation LMCoreViewController

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
}

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
		self.browsingView.musicTrackCollections = [self.musicCollectionsArray objectAtIndex:musicType];
	}
	else{
		NSLog(@"Loading music directly.");
		self.browsingView.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:musicType];
	}
	self.browsingView.musicType = musicType;
	self.browsingView.hidden = NO;
	
	NSLog(@"Setting up browsing view");
	
	[self.browsingView setup];
	[self.browsingView layoutIfNeeded];
	
	NSLog(@"Done setting up");
	
	self.navigationBar.browsingBar.letterTabBar.lettersDictionary =
		[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.browsingView.musicTrackCollections
														 withAssociatedMusicType:musicType];
	
	NSLog(@"Setup letters dictionary");
}

- (BOOL)prefersStatusBarHidden {
	if(!self.loaded){
		NSLog(@"Loading");
		return YES;
	}
	
	BOOL shown = [LMSettings shouldShowStatusBar];
	
	return (!shown || (self.nowPlayingViewController != nil));
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (void)openNowPlayingView {
//	[self attachBrowsingAssistantToView:self.view];
	
	self.nowPlayingViewController = [[LMNowPlayingViewController alloc] init];
	self.nowPlayingViewController.modalPresentationStyle = UIModalPresentationPopover;
	[self.navigationController presentViewController:self.nowPlayingViewController animated:YES completion:nil];
	
	[self.navigationController.view layoutIfNeeded];
	
	self.statusBarBlurViewHeightConstraint.constant = 0;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self setNeedsStatusBarAppearanceUpdate];
		[self.navigationController.view layoutIfNeeded];
	}];
}

- (void)closeNowPlayingView {
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
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
		[self.navigationBar setSelectedTab:LMNavigationTabBrowse];
		
//		[self.browsingAssistant setCurrentSourceIcon:[[source.icon averageColour] isLight] ? source.icon : [LMAppIcon invertImage:source.icon]];
	}
	
	NSLog(@"New source %@", source.title);
	
	switch(source.sourceID){
		case LMIconArtists:
		case LMIconGenres:
		case LMIconPlaylists:
		case LMIconComposers:
		case LMIconCompilations:
		case LMIconAlbums: {
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
			
//			[self.albumView reloadSourceSelectorInfo];
			self.currentSource = self.browsingView;
//
////			if(self.albumView.showingDetailView){
////				[self.browsingAssistant close];
////			}
			break;
		}
		case LMIconTitles: {
//			self.titleView.hidden = NO;
//			[self.titleView reloadSourceSelectorInfo];
//			self.currentSource = self.titleView;
//			
//			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
//			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
//															 withAssociatedMusicType:LMMusicTypeTitles];
//			
//			[self logMusicTypeView:LMMusicTypeTitles];
			break;
		}
		case LMIconSettings: {
//			[self attachBrowsingAssistantToView:self.view];
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			settingsViewController.coreViewController = self;
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

//- (void)attachBrowsingAssistantToView:(UIView*)view {
//	NSLog(@"Attaching browsing assistant to view navigation ? %d", view == self.navigationController.view);
//	[self.browsingAssistant removeFromSuperview];
//	[view addSubview:self.browsingAssistant];
//	[view bringSubviewToFront:self.statusBarBlurView];
//	
//	self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:view];
//	[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:view];
//	[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:view];
//	
//	self.browsingAssistantViewAttachedTo = view;
//	
////	if(view == self.view){
////		[self.view bringSubviewToFront:self.nowPlayingView];
////	}
//}

- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"View did appear animated %d", animated);
	
//	[self attachBrowsingAssistantToView:self.navigationController.view];
	
	self.currentDetailViewController = nil;
	self.searchViewController = nil;
	self.nowPlayingViewController = nil;
	
	if(self.statusBarBlurViewHeightConstraint.constant < 0.1 && ![self prefersStatusBarHidden]){
		[self setStatusBarBlurHidden:NO];
	}
}

- (void)setStatusBarBlurHidden:(BOOL)hidden {
	[self.navigationController.view layoutIfNeeded];
	
	self.statusBarBlurViewHeightConstraint.constant = hidden ? 0 : 20;
	
	[UIView animateWithDuration:0.25 animations:^{
//		[self setNeedsStatusBarAppearanceUpdate];
		[self.navigationController.view layoutIfNeeded];
	}];
}

- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight {	
	BOOL isDecreasing = requiredHeight < self.navigationBarHeightConstraint.constant;
	
	[self.navigationController.view layoutIfNeeded];
	
	self.navigationBarHeightConstraint.constant = requiredHeight;
	
	[UIView animateWithDuration:isDecreasing ? 0.10 : 0.50 animations:^{
		[self.navigationController.view layoutIfNeeded];
	}];
}

//- (void)heightRequiredChangedTo:(CGFloat)heightRequired forBrowsingView:(LMBrowsingAssistantView *)browsingView {
//	NSLog(@"Height required %f", heightRequired);
//	
//	BOOL isDynamic = (heightRequired < 0.0);
//	
//	if(isDynamic){
//		heightRequired = 0.0;
//	}
//	
//	if(self.currentDetailViewController){
//		[(LMBrowsingDetailViewController*)self.currentDetailViewController setRequiredHeight:(WINDOW_FRAME.size.height-heightRequired) + 10];;
//	}
//	
//	if(!isDynamic){
//		if(!self.browsingAssistantHeightConstraint){
////			self.browsingAssistantHeightConstraint = [self.browsingAssistant autoSetDimension:ALDimensionHeight toSize:heightRequired+TAB_HEIGHT];
//			
//			[self.browsingAssistantViewAttachedTo layoutIfNeeded];
//			return;
//		}
//		
//		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
//	}
//	
//	if(heightRequired < self.view.frame.size.height/2.0){
//		for(int i = 0; i < self.heightConstraintArray.count; i++){
//			NSLayoutConstraint *constraint = [self.heightConstraintArray objectAtIndex:i];
//			constraint.constant = (WINDOW_FRAME.size.height-heightRequired) + 10;
//		}
//		[UIView animateWithDuration:(heightRequired < self.browsingAssistantHeightConstraint.constant) ? 0.10 : 0.75 animations:^{
//			[self.browsingAssistantViewAttachedTo layoutIfNeeded];
//		}];
//	}
//	
//	if(!isDynamic){
//		self.browsingAssistantHeightConstraint.constant = heightRequired+TAB_HEIGHT;
//	}
//	
//	[UIView animateWithDuration:0.75 animations:^{
//		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
//	}];
//}

//- (void)showWhatsPoppin {
//	NSArray *currentBuildChanges = @[
//									 @"Added album browsing through individual artists",
//									 @"Fixed Pebble app lists getting cut off at about 150 items",
//									 @"Fixed Pebble app crash"
//									 ];
//	
//	NSArray *currentBuildIssues = @[
//									@"Hey there",
//									@"\nPlease do not report already known issues to us, thanks!"
//									];
//	
//	NSString *currentAppBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
//	
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//	
//	NSString *lastAppBuildString = @"0";
//	if([userDefaults objectForKey:@"LastVersionBuildString"]){
//		lastAppBuildString = [userDefaults objectForKey:@"LastVersionBuildString"];
//	}
//	
//	if(![currentAppBuildString isEqualToString:lastAppBuildString]){
//		NSLog(@"Spooked Super!");
//		
//		NSMutableString *changesString = [NSMutableString stringWithFormat:@"\n|  Changes  |\n\n"];
//		for(int i = 0; i < currentBuildChanges.count; i++){
//			[changesString appendFormat:@"- %@%@", [currentBuildChanges objectAtIndex:i], ((i+1) == currentBuildChanges.count && currentBuildIssues.count > 1) ? @"\n\n" : @"\n"];
//		}
//		if(currentBuildIssues.count > 1){
//			[changesString appendString:@"|  New issues  |\n\n"];
//			for(int i = 0; i < currentBuildIssues.count; i++){
//				int isLastIndex = (i+1) == currentBuildIssues.count;
//				[changesString appendFormat:@"%@%@%@", isLastIndex ? @"" : @"- ", [currentBuildIssues objectAtIndex:i], isLastIndex ? @"" : @"\n"];
//			}
//		}
//		
//		LMAlertView *alertView = [LMAlertView newAutoLayoutView];
//		
//		alertView.title = [NSString stringWithFormat:@"What's new in this build"];
//		alertView.body = changesString;
//		alertView.alertOptionColours = @[[LMColour ligniteRedColour]];
//		alertView.alertOptionTitles = @[NSLocalizedString(@"Awesome", nil)];
//		
//		[alertView launchOnView:self.navigationController.view withCompletionHandler:^(NSUInteger optionSelected) {
//			[userDefaults setObject:currentAppBuildString forKey:@"LastVersionBuildString"];
//			[userDefaults synchronize];
//		}];
//	}
//}

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
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//	return YES;
//}

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
		LMBrowsingView *browsingView = self.currentSource;
		[browsingView scrollToItemWithPersistentID:persistentID];
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

- (void)viewDidLoad {
	
    [super viewDidLoad];
    // Do any additional setup after loading the view
	
//	self.view.backgroundColor = [UIColor lightGrayColor];
	
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	
	self.loaded = NO;
	
	
#ifdef SPEED_DEMON_MODE
	[UIView setAnimationsEnabled:NO];
#endif
	
	
//	self.automaticallyAdjustsScrollViewInsets = YES;
//	
//	LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
//	[self.navigationController presentViewController:feedbackController animated:YES completion:nil];
//	
//	return;
	
//	LMBrowsingBar *browsingBar = [LMBrowsingBar newAutoLayoutView];
//	[self.view addSubview:browsingBar];
//	
//	[browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[browsingBar autoCenterInSuperview];
//	[browsingBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/20.0)];
//	
//	return;
	
//	LMLetterTabView *letterTab = [LMLetterTabView newAutoLayoutView];
//	[self.view addSubview:letterTab];
//	
//	[letterTab autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[letterTab autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[letterTab autoCenterInSuperview];
//	[letterTab autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/20.0)];
//
//	return;
	
//	NSLog(@"Loading view %@", self.navigationController);
	
//	LMCreditsView *view = [LMCreditsView newAutoLayoutView];
//	[self.view addSubview:view];
//	
//	[view autoPinEdgesToSuperviewEdges];
//	
//	return;
	
//	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^() {
//		[[LMPurchaseManager sharedPurchaseManager] showPurchaseViewControllerOnViewController:self.navigationController present:YES];
//	}];
//	
//	LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//	settingsViewController.coreViewController = self;
//	[self.navigationController pushViewController:settingsViewController animated:YES];
//	
//	return;
	
//	LMImageManager *imageManager = [LMImageManager sharedImageManager];
//	[imageManager launchPermissionRequestOnView:self.view
//									forCategory:LMImageManagerCategoryAlbumImages
//						  withCompletionHandler:^(LMImageManagerPermissionStatus permissionStatus) {
//							  NSLog(@"Done. Got permission status %d.", permissionStatus);
//						  }];
//	
//	return;
	
//	NSLog(@"Query %@", query);
	
	
	UIImageView *hangOnImage = [UIImageView newAutoLayoutView];
	hangOnImage.image = [UIImage imageNamed:@"splash_redesigned.png"];
	hangOnImage.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:hangOnImage];
	
	[hangOnImage autoPinEdgesToSuperviewEdges];
	
//	UILabel *hangOnLabel = [UILabel newAutoLayoutView];
//	hangOnLabel.text = NSLocalizedString(@"HangOn", nil);
//	hangOnLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
//	hangOnLabel.textAlignment = NSTextAlignmentCenter;
//	[self.view addSubview:hangOnLabel];
//	
//	[hangOnLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:hangOnImage withOffset:10];
//	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
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
						
						self.heightConstraintArray = [NSMutableArray new];
						
						
						
						self.navigationBar = [LMNavigationBar newAutoLayoutView];
						self.navigationBar.sourcesForSourceSelector = self.sourcesForSourceSelector;
						self.navigationBar.delegate = self;
						[self.navigationController.view addSubview:self.navigationBar];
						
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
						self.navigationBarHeightConstraint = [self.navigationBar autoSetDimension:ALDimensionHeight toSize:0.0];
						
						self.musicPlayer.navigationBar = self.navigationBar;
						
						
						
						self.titleView = [LMTitleView newAutoLayoutView];
						self.titleView.backgroundColor = [UIColor redColor];
						[self.view addSubview:self.titleView];

						[self.titleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//						[self.heightConstraintArray addObject:[self.titleView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.titleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.navigationBar];
						[self.titleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];

						[self.titleView setup];
//						self.titleView.hidden = YES;
						
						
						
						self.browsingView = [LMBrowsingView newAutoLayoutView];
						self.browsingView.rootViewController = self;
						[self.view addSubview:self.browsingView];
						
						[self.browsingView setup];
						
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//						[self.heightConstraintArray addObject:[self.browsingView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.browsingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.navigationBar];
						[self.browsingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						self.browsingView.hidden = YES;
		
				
						[self.musicPlayer addMusicDelegate:self];
						
						
//						[NSTimer scheduledTimerWithTimeInterval:1.0
//														 target:self selector:@selector(showWhatsPoppin) userInfo:nil repeats:NO];
						
						UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
						self.statusBarBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
						self.statusBarBlurView.translatesAutoresizingMaskIntoConstraints = NO;
						
						[self.navigationController.view addSubview:self.statusBarBlurView];
						
						[self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.statusBarBlurView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						self.statusBarBlurViewHeightConstraint = [self.statusBarBlurView autoSetDimension:ALDimensionHeight toSize:20*[LMSettings shouldShowStatusBar]];

						
						LMImageManager *imageManager = [LMImageManager sharedImageManager];
						imageManager.viewToDisplayAlertsOn = self.navigationController.view;
						
						
						NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
						
						NSLog(@"Took %f seconds.", (endTime-startTime));
						
//						NSLog(@"Nice algorithm %@", [self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:[self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums]
//																									 withAssociatedMusicType:LMMusicTypeAlbums]);
						
						self.loaded = YES;
						
						[UIView animateWithDuration:0.25 animations:^{
							[self setNeedsStatusBarAppearanceUpdate];
						}];
						
						[self musicLibraryDidChange];
						
//						[NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//							NSLog(@"Firing library shit");
//							[self musicLibraryDidChange];
//						}];
						
//						[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//							[self openNowPlayingView];
//						}];
						
//						[NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//							[self.purchaseManager makePurchaseWithProductIdentifier:LMPurchaseManagerProductIdentifierLifetimeMusic];
//						}];
					});
					break;
				}
			}
		}];
	}
		
//	[NSTimer scheduledTimerWithTimeInterval:0.75
//									 target:self
//								   selector:@selector(openNowPlayingView)
//								   userInfo:nil
//									repeats:NO];
	
//	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(play)];
//	[self.view addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
