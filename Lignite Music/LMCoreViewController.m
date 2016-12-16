//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAppDelegate.h"
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMNowPlayingViewController.h"
#import "LMBrowsingView.h"
#import "LMBrowsingAssistantView.h"
#import "LMTitleView.h"
#import "LMSource.h"
#import "LMExtras.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "LMSettings.h"
#import "LMGuideViewPagerController.h"
#import "LMImageManager.h"
#import "LMSettingsView.h"
#import "LMSettingsViewController.h"
#import "LMBrowsingDetailViewController.h"
#import "LMSearchView.h"
#import "LMSearchViewController.h"

#import "LMContactView.h"
#import "LMDebugView.h"
#import "LMCreditsView.h"
#import "LMProgressSlider.h"
#import "LMBrowsingBar.h"
#import "LMFeedbackViewController.h"

#define SKIP_ONBOARDING
#define SPEED_DEMON_MODE

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, LMBrowsingAssistantDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingViewController *nowPlayingViewController;

@property LMBrowsingView *browsingView;
@property LMTitleView *titleView;

@property LMSettingsView *settingsView;

@property LMBrowsingAssistantView *browsingAssistant;

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

@end

@implementation LMCoreViewController

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
	
	[self.browsingView setup];
	[self.browsingView layoutIfNeeded];
	
	self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
	[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.browsingView.musicTrackCollections
													 withAssociatedMusicType:musicType];
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

BOOL didAutomaticallyClose = NO;

- (void)openBrowsingAssistant {
	if(didAutomaticallyClose){
		[self.browsingAssistant open];
		didAutomaticallyClose = NO;
	}
}

- (void)closeBrowsingAssistant {
	didAutomaticallyClose = [self.browsingAssistant close];
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
		[self.browsingAssistant closeSourceSelectorAndOpenPreviousTab:YES];
		
		[self.browsingAssistant setCurrentSourceIcon:[[source.icon averageColour] isLight] ? source.icon : [LMAppIcon invertImage:source.icon]];
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
			self.titleView.hidden = NO;
			[self.titleView reloadSourceSelectorInfo];
			self.currentSource = self.titleView;
			
			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			break;
		}
		case LMIconSettings: {
			[self attachBrowsingAssistantToView:self.view];
			
			LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
			settingsViewController.coreViewController = self;
			[self.navigationController pushViewController:settingsViewController animated:YES];
			break;
		}
		case LMIconBug: {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.lignite.io/feedback/"]];
			NSLog(@"Debug menu");
			break;
		}
		default:
			NSLog(@"Unknown index of source %@.", source);
			break;
	}
}

- (void)attachBrowsingAssistantToView:(UIView*)view {
	NSLog(@"Attaching browsing assistant to view navigation ? %d", view == self.navigationController.view);
	[self.browsingAssistant removeFromSuperview];
	[view addSubview:self.browsingAssistant];
	[view bringSubviewToFront:self.statusBarBlurView];
	
	self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:view];
	[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:view];
	[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:view];
	
	self.browsingAssistantViewAttachedTo = view;
	
//	if(view == self.view){
//		[self.view bringSubviewToFront:self.nowPlayingView];
//	}
}

- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"View did appear animated %d", animated);
	
	[self attachBrowsingAssistantToView:self.navigationController.view];
	
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

- (void)heightRequiredChangedTo:(CGFloat)heightRequired forBrowsingView:(LMBrowsingAssistantView *)browsingView {
	NSLog(@"Height required %f", heightRequired);
	
	BOOL isDynamic = (heightRequired < 0.0);
	
	if(isDynamic){
		heightRequired = 0.0;
	}
	
	if(self.currentDetailViewController){
		[(LMBrowsingDetailViewController*)self.currentDetailViewController setRequiredHeight:(WINDOW_FRAME.size.height-heightRequired) + 10];;
	}
	
	if(!isDynamic){
		if(!self.browsingAssistantHeightConstraint){
			self.browsingAssistantHeightConstraint = [self.browsingAssistant autoSetDimension:ALDimensionHeight toSize:heightRequired+TAB_HEIGHT];
			
			[self.browsingAssistantViewAttachedTo layoutIfNeeded];
			return;
		}
		
		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
	}
	
	if(heightRequired < self.view.frame.size.height/2.0){
		for(int i = 0; i < self.heightConstraintArray.count; i++){
			NSLayoutConstraint *constraint = [self.heightConstraintArray objectAtIndex:i];
			constraint.constant = (WINDOW_FRAME.size.height-heightRequired) + 10;
		}
		[UIView animateWithDuration:(heightRequired < self.browsingAssistantHeightConstraint.constant) ? 0.10 : 0.75 animations:^{
			[self.browsingAssistantViewAttachedTo layoutIfNeeded];
		}];
	}
	
	if(!isDynamic){
		self.browsingAssistantHeightConstraint.constant = heightRequired+TAB_HEIGHT;
	}
	
	[UIView animateWithDuration:0.75 animations:^{
		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
	}];
}

- (void)showWhatsPoppin {
	NSArray *currentBuildChanges = @[
									 @"Added now playing queue within the now playing screen",
									 @"Added AirPlay support",
									 @"Improved app loading time (please contact us if the app takes longer than 7 seconds to load)",
									 ];
	
	NSArray *currentBuildIssues = @[
									
									@"\nPlease do not report already known issues to us, thanks!"
									];
	
	NSString *currentAppBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString *lastAppBuildString = @"0";
	if([userDefaults objectForKey:@"LastVersionBuildString"]){
		lastAppBuildString = [userDefaults objectForKey:@"LastVersionBuildString"];
	}
	
	if(![currentAppBuildString isEqualToString:lastAppBuildString]){
		NSLog(@"Spooked Super!");
		
		NSMutableString *changesString = [NSMutableString stringWithFormat:@"\nChanges\n---------\n"];
		for(int i = 0; i < currentBuildChanges.count; i++){
			[changesString appendFormat:@"%@%@", [currentBuildChanges objectAtIndex:i], ((i+1) == currentBuildChanges.count && currentBuildIssues.count > 1) ? @"\n\n" : @"\n"];
		}
		if(currentBuildIssues.count > 1){
			[changesString appendString:@"New issues\n-------------\n"];
			for(int i = 0; i < currentBuildIssues.count; i++){
				[changesString appendFormat:@"%@%@", [currentBuildIssues objectAtIndex:i], (i+1) == currentBuildIssues.count ? @"" : @"\n"];
			}
		}
		
		UIAlertController *alert = [UIAlertController
									alertControllerWithTitle:[NSString stringWithFormat:@"What's Poppin' in Build %@", currentAppBuildString]
									message:changesString
									preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *yesButton = [UIAlertAction
									actionWithTitle:@"👌"
									style:UIAlertActionStyleDefault
									handler:^(UIAlertAction *action) {
										[userDefaults setObject:currentAppBuildString forKey:@"LastVersionBuildString"];
										[userDefaults synchronize];
									}];
		
		[alert addAction:yesButton];
		
		NSArray *viewArray = [[[[[[[[[[[[alert view] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews]; //lol
//		UILabel *alertTitle = viewArray[0];
		UILabel *alertMessage = viewArray[1];
		alertMessage.textAlignment = NSTextAlignmentLeft;
		
		[self presentViewController:alert animated:YES completion:nil];
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
	return YES;
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	NSLog(@"Changed to %@", searchTerm);
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	NSLog(@"Search was opened: %d", opened);
	
	if(!self.searchViewController){
		[self attachBrowsingAssistantToView:self.view];
		
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
	
	
	self.automaticallyAdjustsScrollViewInsets = YES;
	
	LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
	[self.navigationController presentViewController:feedbackController animated:YES completion:nil];
	
	return;
	
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
	
//	self.settingsView = [LMSettingsView newAutoLayoutView];
//	self.settingsView.coreViewController = self;
//	[self.view addSubview:self.settingsView];
//	
//	[self.settingsView autoPinEdgesToSuperviewEdges];
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
	hangOnImage.image = [UIImage imageNamed:@"splash_portrait.png"];
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

						LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
						[pebbleManager attachToViewController:self];

						NSArray *sourceTitles = @[
												  @"Artists", @"Albums", @"Titles", @"Playlists", @"Genres", @"Compilations", @"Settings", @"ReportBug"
												  ];
						NSArray *sourceSubtitles = @[
													 @"", @"", @"", @"", @"", @"", @"", @"OrSendFeedback"
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
						
						
						
						self.titleView = [LMTitleView newAutoLayoutView];
						self.titleView.backgroundColor = [UIColor redColor];
						[self.view addSubview:self.titleView];

						[self.titleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.titleView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.titleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];

						[self.titleView setup];
//						self.titleView.hidden = YES;
						
						self.browsingView = [LMBrowsingView newAutoLayoutView];
						self.browsingView.rootViewController = self;
						[self.view addSubview:self.browsingView];
						
						[self.browsingView setup];
						
						[self.browsingView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.browsingView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.browsingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						self.browsingView.hidden = YES;
						

						self.browsingAssistant = [[LMBrowsingAssistantView alloc]initForAutoLayout];
						self.browsingAssistant.coreViewController = self;
						self.browsingAssistant.backgroundColor = [UIColor orangeColor];
						self.browsingAssistant.sourcesForSourceSelector = self.sourcesForSourceSelector;
						self.browsingAssistant.delegate = self;
						self.browsingAssistant.searchBarDelegate = self;
						self.browsingAssistant.letterTabBarDelegate = self;
						[self.navigationController.view addSubview:self.browsingAssistant];

						self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.navigationController.view];
						[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.navigationController.view];
						[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.navigationController.view];
						
						self.browsingAssistantViewAttachedTo = self.navigationController.view;
						
						self.musicPlayer.browsingAssistant = self.browsingAssistant;
				
						[self.musicPlayer addMusicDelegate:self];
						
						[NSTimer scheduledTimerWithTimeInterval:1.0
														 target:self selector:@selector(showWhatsPoppin) userInfo:nil repeats:NO];
											
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
