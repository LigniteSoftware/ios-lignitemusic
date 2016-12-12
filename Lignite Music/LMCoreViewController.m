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
#import "LMAlbumView.h"
#import "LMNowPlayingView.h"
#import "LMBrowsingAssistantView.h"
#import "LMTitleView.h"
#import "LMSource.h"
#import "LMExtras.h"
#import "LMPlaylistView.h"
#import "LMGenreView.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "LMSettings.h"
#import "LMGuideViewPagerController.h"
#import "LMArtistView.h"
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

#define SKIP_ONBOARDING
//#define SPEED_DEMON_MODE

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, LMBrowsingAssistantDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchSelectedDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingView *nowPlayingView;

@property LMAlbumView *albumView;
@property LMTitleView *titleView;
@property LMPlaylistView *playlistView;
@property LMGenreView *genreView;
@property LMArtistView *artistView;

@property LMSettingsView *settingsView;

@property LMBrowsingAssistantView *browsingAssistant;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *topConstraint;
@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property NSMutableArray<NSLayoutConstraint*>*heightConstraintArray;

@property id currentSource;

@property UIVisualEffectView *statusBarBlurView;
@property NSLayoutConstraint *statusBarBlurViewHeightConstraint;

@property UIView *browsingAssistantViewAttachedTo;

@property LMSearchViewController *searchViewController;

@property BOOL loaded;

@end

@implementation LMCoreViewController

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
//	NSLog(@"Got new playback state %d", newState);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
//	NSLog(@"Got new track, title %@", newTrack.title);
}

- (BOOL)prefersStatusBarHidden {
	if(!self.loaded){
		NSLog(@"Loading");
		return YES;
	}
	
	BOOL shown = [LMSettings shouldShowStatusBar];
	
	return (!shown || (self.nowPlayingView != nil));
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (void)pause {
	[self.musicPlayer pause];
}

- (void)play {
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(pause)
								   userInfo:nil
									repeats:NO];
	
	NSArray *items = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists];
	NSLog(@"Got %lu items.", (unsigned long)items.count);
	
	int random = rand() % items.count;
	NSLog(@"%d", random);
	LMMusicTrackCollection *collection = [items objectAtIndex:random];
	[self.musicPlayer setNowPlayingCollection:collection];
	[self.musicPlayer setNowPlayingTrack:collection.representativeItem];
	[self.musicPlayer play];
}

- (void)openNowPlayingView {
	if(self.nowPlayingView){
		return;
	}
	
	self.nowPlayingView = [LMNowPlayingView newAutoLayoutView];
	self.nowPlayingView.backgroundColor = [UIColor whiteColor];
	self.nowPlayingView.rootViewController = self;
	[self.view addSubview:self.nowPlayingView];
	
	[self.nowPlayingView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.topConstraint = [self.nowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:self.view.frame.size.height];
	[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.nowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
		
	[self.view layoutIfNeeded];
	
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:1.0 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:nil];
	
	[self.navigationController.view layoutIfNeeded];
	
	[self attachBrowsingAssistantToView:self.view];
	
	self.statusBarBlurViewHeightConstraint.constant = 0;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self setNeedsStatusBarAppearanceUpdate];
		[self.navigationController.view layoutIfNeeded];
	}];
}

- (void)closeNowPlayingView {
	[self.view layoutIfNeeded];
	self.topConstraint.constant = self.view.frame.size.height*1.5;
	[UIView animateWithDuration:1.0 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:^(BOOL finished) {
							self.nowPlayingView = nil;
							
							[self.navigationController.view layoutIfNeeded];
							
							self.statusBarBlurViewHeightConstraint.constant = 20;
							
							[UIView animateWithDuration:0.25 animations:^{
								[self setNeedsStatusBarAppearanceUpdate];
								[self.navigationController.view layoutIfNeeded];
							}];
							
							[self attachBrowsingAssistantToView:self.navigationController.view];
						}];
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
		case LMIconAlbums:{
			self.albumView.hidden = NO;
			[self.albumView reloadSourceSelectorInfo];
			self.currentSource = self.albumView;
			
			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
				[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.albumView.browsingView.musicTrackCollections
																 withAssociatedMusicType:LMMusicTypeAlbums];
//			if(self.albumView.showingDetailView){
//				[self.browsingAssistant close];
//			}
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
		case LMIconPlaylists: {
			self.playlistView.hidden = NO;
			[self.playlistView reloadSourceSelectorInfo];
			self.currentSource = self.playlistView;
			
			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.playlistView.browsingView.musicTrackCollections
															 withAssociatedMusicType:LMMusicTypePlaylists];
			break;
		}
		case LMIconGenres:{
			self.genreView.hidden = NO;
			[self.genreView reloadSourceSelectorInfo];
			self.currentSource = self.genreView;
			
			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.genreView.browsingView.musicTrackCollections
															 withAssociatedMusicType:LMMusicTypeGenres];
			break;
		}
		case LMIconArtists: {
			self.artistView.hidden = NO;
			[self.artistView reloadSourceSelectorInfo];
			self.currentSource = self.artistView;
			
			self.browsingAssistant.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:self.artistView.browsingView.musicTrackCollections
															 withAssociatedMusicType:LMMusicTypeArtists];
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
	[self.browsingAssistant removeFromSuperview];
	[view addSubview:self.browsingAssistant];
	[view bringSubviewToFront:self.statusBarBlurView];
	
	self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:view];
	[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:view];
	[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:view];
	
	self.browsingAssistantViewAttachedTo = view;
	
	if(view == self.view){
		[self.view bringSubviewToFront:self.nowPlayingView];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[self attachBrowsingAssistantToView:self.navigationController.view];
	
	self.currentDetailViewController = nil;
	self.searchViewController = nil;
	
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
	if(self.currentDetailViewController){
		[(LMBrowsingDetailViewController*)self.currentDetailViewController setRequiredHeight:(WINDOW_FRAME.size.height-heightRequired) + 10];;
	}
	
	if(!self.browsingAssistantHeightConstraint){
		self.browsingAssistantHeightConstraint = [self.browsingAssistant autoSetDimension:ALDimensionHeight toSize:heightRequired];
		
		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
		return;
	}
	
	[self.browsingAssistantViewAttachedTo layoutIfNeeded];
	
	if(heightRequired < self.view.frame.size.height/2.0){
		for(int i = 0; i < self.heightConstraintArray.count; i++){
			NSLayoutConstraint *constraint = [self.heightConstraintArray objectAtIndex:i];
			constraint.constant = (WINDOW_FRAME.size.height-heightRequired) + 10;
		}
		[UIView animateWithDuration:(heightRequired < self.browsingAssistantHeightConstraint.constant) ? 0.10 : 0.75 animations:^{
			[self.browsingAssistantViewAttachedTo layoutIfNeeded];
		}];
	}
	
	self.browsingAssistantHeightConstraint.constant = heightRequired;
	
	[UIView animateWithDuration:0.75 animations:^{
		[self.browsingAssistantViewAttachedTo layoutIfNeeded];
	}];
}

- (void)showWhatsPoppin {
	NSArray *currentBuildChanges = @[
									 @"Added search (finally!)",
									 @"Added letter tab browsing",
									 @"Added new music progress bar",
									 @"Added icon credits",
									 @"Added license links in credits",
									 @"Fixed music sometimes not playing",
									 @"Fixed crash on some older devices",
									 @"Improved many visual things",
									 @"Improved app loading time",
									 @"Removed godforsaken hang on screen",
									 ];
	
	NSArray *currentBuildIssues = @[
									@"The artist detail view is still not complete",
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
		LMBrowsingView *browsingView = [self.currentSource browsingView];
		[browsingView scrollToItemWithPersistentID:persistentID];
	}
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)letterSelected:(NSString *)letter atIndex:(NSUInteger)index {
	if([self.currentSource isEqual:self.titleView]){
		[self.titleView scrollToTrackIndex:index == 0 ? 0 : index-1];
	}
	else{
		[[self.currentSource browsingView] scrollViewToIndex:index];
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
												  @"Artists", @"Albums", @"Titles", @"Playlists", @"Genres", @"Settings", @"Report Bug"
												  ];
						NSArray *sourceSubtitles = @[
													 @"", @"", @"", @"", @"", @"", @"Or send feedback"
													 ];
						LMIcon sourceIcons[] = {
							LMIconArtists, LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconGenres, LMIconSettings, LMIconBug
						};
						BOOL notHighlight[] = {
							NO, NO, NO, NO, NO, YES, YES
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
						self.titleView.hidden = YES;

						//Playlist view

						self.playlistView = [LMPlaylistView newAutoLayoutView];
						self.playlistView.backgroundColor = [UIColor whiteColor];
						self.playlistView.coreViewController = self;
						[self.view addSubview:self.playlistView];

						[self.playlistView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.playlistView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.playlistView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];

						[self.playlistView setup];
						self.playlistView.hidden = YES;

						//Genre view

						self.genreView = [LMGenreView newAutoLayoutView];
						self.genreView.backgroundColor = [UIColor whiteColor];
						self.genreView.coreViewController = self;
						[self.view addSubview:self.genreView];

						[self.genreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.genreView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.genreView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];

						[self.genreView setup];
						self.genreView.hidden = YES;


						self.artistView = [LMArtistView newAutoLayoutView];
						self.artistView.backgroundColor = [UIColor whiteColor];
						self.artistView.coreViewController = self;
						[self.view addSubview:self.artistView];

						[self.artistView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.artistView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.artistView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						
						[self.artistView setup];
						self.artistView.hidden = YES;
						
						
						self.albumView = [LMAlbumView newAutoLayoutView];
						self.albumView.coreViewController = self;
						[self.view addSubview:self.albumView];
						
						[self.albumView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.albumView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.albumView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						self.albumView.hidden = YES;
						

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
