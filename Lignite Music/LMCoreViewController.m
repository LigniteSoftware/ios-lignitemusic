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
#import "LMSourceSelectorView.h"
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

@import SDWebImage;
@import StoreKit;

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, LMBrowsingAssistantDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingView *nowPlayingView;

@property LMAlbumView *albumView;
@property LMTitleView *titleView;
@property LMPlaylistView *playlistView;
@property LMGenreView *genreView;
@property LMArtistView *artistView;

@property LMSettingsView *settingsView;

@property LMBrowsingAssistantView *browsingAssistant;
@property LMSourceSelectorView *sourceSelector;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *topConstraint;
@property NSLayoutConstraint *browsingAssistantHeightConstraint;

@property NSMutableArray<NSLayoutConstraint*>*heightConstraintArray;

@property id currentSource;

@end

@implementation LMCoreViewController

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
//	NSLog(@"Got new playback state %d", newState);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
//	NSLog(@"Got new track, title %@", newTrack.title);
}

- (BOOL)prefersStatusBarHidden {
	BOOL settingEnabled = YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyStatusBar]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] integerForKey:LMSettingsKeyStatusBar];
	}
	
	return !settingEnabled;
}

- (void)pause {
	NSLog(@"Dude!");
	[self.musicPlayer pause];
}

- (void)play {
	NSLog(@"Dude");
	
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
		NSLog(@"Now playing view already exists, rejecting");
		return;
	}
	
	NSLog(@"Opening now playing view");
	
	self.nowPlayingView = [LMNowPlayingView new];
	self.nowPlayingView.translatesAutoresizingMaskIntoConstraints = NO;
	self.nowPlayingView.backgroundColor = [UIColor blueColor];
	self.nowPlayingView.rootViewController = self;
	[self.view addSubview:self.nowPlayingView];
	
	[self.nowPlayingView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.topConstraint = [self.nowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:self.view.frame.size.height];
	[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.nowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	NSLog(@"Setting up now playing");
	
	[self.nowPlayingView setup];
	
	NSLog(@"Setup");
	
	[self.view layoutIfNeeded];
	
	NSLog(@"Laying out done");
	
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:1.0 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
							NSLog(@"Spook");
						} completion:nil];
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
	NSLog(@"The index is %d", indexOfSource);
	
	if(!source.shouldNotSelect){
		[self.currentSource setHidden:YES];
		[self.browsingAssistant closeSourceSelector];
	}
	
	switch(indexOfSource){
		case 0:{
			self.albumView.hidden = NO;
			[self.albumView reloadSourceSelectorInfo];
			self.currentSource = self.albumView;
//			if(self.albumView.showingDetailView){
//				[self.browsingAssistant close];
//			}
			break;
		}
		case 1: {
			self.titleView.hidden = NO;
			[self.titleView reloadSourceSelectorInfo];
			self.currentSource = self.titleView;
			break;
		}
		case 2: {
			self.playlistView.hidden = NO;
			[self.playlistView reloadSourceSelectorInfo];
			self.currentSource = self.playlistView;
			break;
		}
		case 3:{
			self.genreView.hidden = NO;
			[self.genreView reloadSourceSelectorInfo];
			self.currentSource = self.genreView;
			break;
		}
		case 4: {
			self.artistView.hidden = NO;
			[self.artistView reloadSourceSelectorInfo];
			self.currentSource = self.artistView;
			break;
		}
		case 5: {
			LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
			[pebbleManager showSettings];
			break;
		}
		case 6: {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.lignite.io/feedback/"]];
			NSLog(@"Debug menu");
			break;
		}
		default:
			NSLog(@"Unknown index of source %@.", source);
			break;
	}
	
	[self.browsingAssistant setCurrentSourceIcon:[[source.icon averageColour] isLight] ? source.icon : [LMAppIcon invertImage:source.icon]];
}

- (void)heightRequiredChangedTo:(float)heightRequired forBrowsingView:(LMBrowsingAssistantView *)browsingView {
	if(!self.browsingAssistantHeightConstraint){
		self.browsingAssistantHeightConstraint = [self.browsingAssistant autoSetDimension:ALDimensionHeight toSize:heightRequired];
		
		[self.view layoutIfNeeded];
		return;
	}
	
	[self.view layoutIfNeeded];
	
	if(heightRequired < self.view.frame.size.height/2.0){
		for(int i = 0; i < self.heightConstraintArray.count; i++){
			NSLayoutConstraint *constraint = [self.heightConstraintArray objectAtIndex:i];
			constraint.constant = (WINDOW_FRAME.size.height-heightRequired) + 10;
		}
		[UIView animateWithDuration:(heightRequired < self.browsingAssistantHeightConstraint.constant) ? 0.10 : 0.75 animations:^{
			[self.view layoutIfNeeded];
		}];
	}
	
	self.browsingAssistantHeightConstraint.constant = heightRequired;
	
	[UIView animateWithDuration:0.75 animations:^{
		[self.view layoutIfNeeded];
	}];
	
	NSLog(@"Spook %f", heightRequired);
}

- (void)showWhatsPoppin {
	NSArray *currentBuildChanges = @[
									 @"Added Apple Music support",
									 @"Added iTunes Match support (experimental)",
									 @"Added onboarding",
									 @"Added actual tutorial",
									 @"Fixed app crashing due to Apple Music song",
									 @"Fixed app automatically skipping over Apple Music/cloud songs",
									 @"Fixed a crash due to overloading music player",
									 @"Fixed music not playing sometimes",
									 @"Fixed not being able to handle rejection of music permission",
									 @"Improved app's self confidence across the board :)"
									 ];
	
	NSArray *currentBuildIssues = @[
									@"Music library changes (such as adding new songs) do not work",
									@"\nPlease do not report already known issues to us, thanks!"
									];
	
	NSString *currentAppBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString *lastAppBuildString = @"0";
	if([userDefaults objectForKey:@"LastVersionBuildString"]){
		NSLog(@"Did get %@ from storage", [userDefaults objectForKey:@"LastVersionBuildString"]);
		lastAppBuildString = [userDefaults objectForKey:@"LastVersionBuildString"];
	}
	
	NSLog(@"Current app %@ last app %@", currentAppBuildString, lastAppBuildString);
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
	LMGuideViewPagerController *controller = [[LMGuideViewPagerController alloc]init];
	controller.guideMode = GuideModeOnboarding;
	controller.coreViewController = self;
	[self presentViewController:controller animated:YES completion:nil];
}

- (void)prepareToLoadView {
	NSLog(@"Preparing to load view");
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(viewDidLoad) userInfo:nil repeats:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
	
	NSLog(@"Loading view");
	
//	self.settingsView = [LMSettingsView newAutoLayoutView];
//	self.settingsView.coreViewController = self;
//	[self.view addSubview:self.settingsView];
//	
//	[self.settingsView autoPinEdgesToSuperviewEdges];
	
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
	hangOnImage.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	hangOnImage.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:hangOnImage];
	
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height/4.0];
	[hangOnImage autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/3.0)];
	
	UILabel *hangOnLabel = [UILabel newAutoLayoutView];
	hangOnLabel.text = NSLocalizedString(@"HangOn", nil);
	hangOnLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
	hangOnLabel.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:hangOnLabel];
	
	[hangOnLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:hangOnImage withOffset:10];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if(![userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
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
						self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
						
						LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
						[pebbleManager attachToViewController:self];
						
						NSArray *sourceTitles = @[
												  @"Albums", @"Titles", @"Playlists", @"Genres", @"Artists", @"Settings", @"Report Bug"
												  ];
						NSArray *sourceSubtitles = @[
													 @"", @"", @"", @"", @"", @"", @"Or send feedback"
													 ];
						LMIcon sourceIcons[] = {
							LMIconAlbums, LMIconTitles, LMIconPlaylists, LMIconGenres, LMIconArtists, LMIconSettings, LMIconBug
						};
						BOOL notSelect[] = {
							NO, NO, NO, NO, NO, YES, YES
						};
						
						NSMutableArray *sources = [NSMutableArray new];
						
						for(int i = 0; i < sourceTitles.count; i++){
							NSString *subtitle = [sourceSubtitles objectAtIndex:i];
							LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
															 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
																 andIcon:sourceIcons[i]];
							source.shouldNotSelect = notSelect[i];
							source.delegate = self;
							[sources addObject:source];
						}
						
						self.sourcesForSourceSelector = [NSArray arrayWithArray:sources];

						self.heightConstraintArray = [NSMutableArray new];
						
						//Album View
						
						self.albumView = [LMAlbumView newAutoLayoutView];
						[self.view addSubview:self.albumView];

						[self.albumView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.albumView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.albumView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						
						[self.albumView setup];
						self.albumView.hidden = YES;
						
						//Title view
						
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
						[self.view addSubview:self.playlistView];
						
						[self.playlistView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.playlistView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.playlistView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						
						[self.playlistView setup];
						self.playlistView.hidden = YES;
						
						//Genre view
						
						self.genreView = [LMGenreView newAutoLayoutView];
						self.genreView.backgroundColor = [UIColor whiteColor];
						[self.view addSubview:self.genreView];
						
						[self.genreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.genreView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.genreView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						
						[self.genreView setup];
						self.genreView.hidden = YES;
						
						
						self.artistView = [LMArtistView newAutoLayoutView];
						self.artistView.backgroundColor = [UIColor whiteColor];
						[self.view addSubview:self.artistView];
						
						[self.artistView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[self.heightConstraintArray addObject:[self.artistView autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height]];
						[self.artistView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
						
						[self.artistView setup];
						self.artistView.hidden = YES;
						

						self.browsingAssistant = [[LMBrowsingAssistantView alloc]initForAutoLayout];
						self.browsingAssistant.coreViewController = self;
						self.browsingAssistant.backgroundColor = [UIColor orangeColor];
						self.browsingAssistant.sourcesForSourceSelector = self.sourcesForSourceSelector;
						self.browsingAssistant.delegate = self;
						[self.view addSubview:self.browsingAssistant];
						[self.browsingAssistant setup];
						
						self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
						[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
						[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
					//	self.browsingAssistantHeightConstraint = [self.browsingAssistant autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height];
						
						[self.view bringSubviewToFront:self.sourceSelector];
						
						[self.musicPlayer addMusicDelegate:self];
						
						[NSTimer scheduledTimerWithTimeInterval:1.0
														 target:self selector:@selector(showWhatsPoppin) userInfo:nil repeats:NO];
						
						NSLog(@"Loaded shit");
						
						[self.sourceSelector setup];
						
						UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
						UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
						blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
						
						[self.view addSubview:blurEffectView];
						
						[blurEffectView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
						[blurEffectView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
						[blurEffectView autoPinEdgeToSuperviewEdge:ALEdgeTop];
						[blurEffectView autoSetDimension:ALDimensionHeight toSize:20];
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
