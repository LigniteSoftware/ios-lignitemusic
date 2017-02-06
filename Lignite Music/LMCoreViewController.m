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
#import "LMSettingsViewController.h"
#import "LMSearchViewController.h"
#import "LMButtonNavigationBar.h"
#import "UIImage+AverageColour.h"
#import "LMCoreViewController.h"
#import "LMPurchaseManager.h"
#import "LMNowPlayingView.h"
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
#import "LMCreditsViewController.h"
#import "LMCompactBrowsingView.h"
#import "LMProgressSlider.h"
#import "LMBrowsingBar.h"

//#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate, LMPurchaseManagerDelegate, LMButtonNavigationBarDelegate, UINavigationBarDelegate, UINavigationControllerDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingView *nowPlayingView;

@property LMBrowsingView *browsingView;
@property LMTitleView *titleView;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property id currentSource;

@property UIView *statusBarBlurView;
@property NSLayoutConstraint *statusBarBlurViewHeightConstraint;

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
 The navigation bar that goes at the bottom.
 */
@property LMButtonNavigationBar *buttonNavigationBar;

/**
 The height constraint for the navigation bar.
 */
@property NSLayoutConstraint *buttonNavigationBarHeightConstraint;

@property CGPoint originalPoint, currentPoint;

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
	
	self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
		[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.browsingView.musicTrackCollections
														 withAssociatedMusicType:musicType];
	
	NSLog(@"Setup letters dictionary");
}

- (BOOL)prefersStatusBarHidden {
	if(!self.loaded){
		NSLog(@"Loading");
		return YES;
	}
	
	return self.nowPlayingView.isOpen;
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
			
			[self.browsingView reloadSourceSelectorInfo];
			self.currentSource = self.browsingView;
//
////			if(self.albumView.showingDetailView){
////				[self.browsingAssistant close];
////			}
			break;
		}
		case LMIconTitles: {
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
			self.buttonNavigationBar.hidden = YES;
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			settingsViewController.coreViewController = self;
			[self.navigationController pushViewController:settingsViewController animated:YES];
			
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

- (void)attachButtonNavigationBarToView:(UIView*)view {
	if(view == self.browsingAssistantViewAttachedTo){
		return;
	}
	
	CGFloat constantBeforeReload = self.buttonNavigationBarHeightConstraint.constant;
	
	NSLog(@"Attaching browsing assistant to view navigation ? %d", view == self.navigationController.view);
	
	[self.buttonNavigationBar.constraints autoRemoveConstraints];
	for(NSLayoutConstraint *constraint in self.browsingAssistantViewAttachedTo.constraints){
		if(constraint.firstItem == self.buttonNavigationBar){
			[self.browsingAssistantViewAttachedTo removeConstraint:constraint];
		}
	}
	
	[self.buttonNavigationBar removeFromSuperview];
	[view addSubview:self.buttonNavigationBar];
	
	[self.navigationController.view bringSubviewToFront:self.nowPlayingView];
	[view bringSubviewToFront:self.statusBarBlurView];
	
	[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.buttonNavigationBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	self.buttonNavigationBarHeightConstraint = [self.buttonNavigationBar autoSetDimension:ALDimensionHeight toSize:constantBeforeReload];
	
	self.browsingAssistantViewAttachedTo = view;
	
//	if(view == self.view){
//		[self.view bringSubviewToFront:self.nowPlayingView];
//	}
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

- (void)setStatusBarBlurHidden:(BOOL)hidden {
	[self.navigationController.view layoutIfNeeded];
	
	self.statusBarBlurViewHeightConstraint.constant = hidden ? 0 : 20;
	
	[UIView animateWithDuration:0.25 animations:^{
//		[self setNeedsStatusBarAppearanceUpdate];
		[self.navigationController.view layoutIfNeeded];
	}];
}

- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration {
	NSLog(@"Height changed to %f", requiredHeight);
	
	
	[self.navigationController.view layoutIfNeeded];
	
	self.buttonNavigationBarHeightConstraint.constant = requiredHeight;
	
//	[UIView animateWithDuration:animationDuration animations:^{
		[self.navigationController.view layoutIfNeeded];
//	}];
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

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
//	NSLog(@"And it's getting to the point where even I have a problem with it");
	return UIBarPositionTopAttached;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
	NSLog(@"Item %@ was pop popped!", item.title);
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
//	NSLog(@"Item %@ was pushed!", item.title);
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
	[self.nowPlayingView.superview layoutIfNeeded];
	
	self.nowPlayingView.topConstraint.constant = 0;
	
	self.nowPlayingView.isOpen = YES;

	[UIView animateWithDuration:0.25 animations:^{
		[self.nowPlayingView.superview layoutIfNeeded];
	} completion:^(BOOL finished) {
		if(finished){
			[UIView animateWithDuration:0.25 animations:^{
				[self setNeedsStatusBarAppearanceUpdate];
				[self setStatusBarBlurHidden:self.nowPlayingView.isOpen];
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
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.view.frame.origin;
		self.currentPoint = self.nowPlayingView.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	if(totalTranslation < 0){ //Moving downward
		return;
	}
	else{ //Moving downward
		self.nowPlayingView.topConstraint.constant = self.nowPlayingView.frame.size.height+translation.y;
	}
	
	[self.nowPlayingView.superview layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		[self.nowPlayingView.superview layoutIfNeeded];
		
		if((-translation.y <= self.nowPlayingView.frame.size.height/10.0)){
			self.nowPlayingView.topConstraint.constant = self.nowPlayingView.frame.size.height;
			
			self.nowPlayingView.isOpen = NO;
		}
		else{
			self.nowPlayingView.topConstraint.constant = 0.0;
			
			self.nowPlayingView.isOpen = YES;
		}
		
		[UIView animateWithDuration:0.25 animations:^{
			[self.nowPlayingView.superview layoutIfNeeded];
		} completion:^(BOOL finished) {
			if(finished){
				[UIView animateWithDuration:0.25 animations:^{
					[self setNeedsStatusBarAppearanceUpdate];
					[self setStatusBarBlurHidden:self.nowPlayingView.isOpen];
				}];
			}
		}];
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
	
	
	NSLog(@"Frame set %@", NSStringFromCGRect(self.view.frame));
	
//	LMCompactBrowsingView *compactBrowsingView = [LMCompactBrowsingView newAutoLayoutView];
//	[self.view addSubview:compactBrowsingView];
//	
//	[compactBrowsingView autoPinEdgesToSuperviewEdges];
//	
//	return;
	
	
	
	UIImageView *hangOnImage = [UIImageView newAutoLayoutView];
	hangOnImage.image = [UIImage imageNamed:@"splash_wings.png"];
	hangOnImage.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:hangOnImage];
	
	[hangOnImage autoPinEdgesToSuperviewEdges];
	
	
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
						
						
						
						self.navigationBar = [LMNavigationBar newAutoLayoutView];
						self.navigationBar.delegate = self;
						[self.navigationController.view addSubview:self.navigationBar];
						
						//						self.navigationController.navigationBar
						
						[self.navigationBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
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
						
						
						UIPanGestureRecognizer *miniPlayerDragUpPanGesture =
							[[UIPanGestureRecognizer alloc] initWithTarget:self
																	action:@selector(panNowPlayingUp:)];
						[self.buttonNavigationBar.miniPlayerView addGestureRecognizer:miniPlayerDragUpPanGesture];
						
						
						
						self.nowPlayingView = [LMNowPlayingView newAutoLayoutView];
						self.nowPlayingView.coreViewController = self;
						[self.navigationController.view addSubview:self.nowPlayingView];
						
						[self.nowPlayingView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.nowPlayingView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						self.nowPlayingView.topConstraint = [self.nowPlayingView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height];
						[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.navigationController.view];
						
						
						
						self.titleView = [LMTitleView newAutoLayoutView];
						self.titleView.backgroundColor = [UIColor redColor];
						[self.view addSubview:self.titleView];

						[self.titleView autoPinEdgesToSuperviewEdges];

						[self.titleView setup];
						self.titleView.hidden = YES;
						
						
						
						self.browsingView = [LMBrowsingView newAutoLayoutView];
						self.browsingView.rootViewController = self;
						[self.view addSubview:self.browsingView];
						
						[self.browsingView setup];
						
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
						self.browsingView.hidden = YES;
		
				
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
