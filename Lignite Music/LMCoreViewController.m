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
#import "LMGuideViewController.h"
#import "LMCoreViewController.h"
#import "LMNowPlayingCoreView.h"
#import "LMNowPlayingCoreView.h"
#import "UIColor+isLight.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "LMThemeEngine.h"
#import "MBProgressHUD.h"
#import "LMMusicPlayer.h"
#import "LMApplication.h"
#import "LMAppDelegate.h"
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
#import "LMButtonBar.h"
#import "LMExpandableTrackListControlBar.h"
#import "LMPhoneLandscapeDetailView.h"
#import "LMPlaylistEditorViewController.h"
#import "LMEnhancedPlaylistEditorViewController.h"
#import "LMAppleWatchBridge.h"
#import "LMThemePickerViewController.h"
#import "LMWarningManager.h"
#import "LMAlertViewController.h"
#import "Lignite_Music-Swift.h"
#import "LMTutorialViewController.h"
#import "LMDebugViewController.h"
//#import "Lignite Music-Bridging-Header.h"
//#import "Popover-Swift.h"

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

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate, UIGestureRecognizerDelegate, LMSearchBarDelegate, LMLetterTabDelegate, LMSearchViewControllerResultDelegate, LMButtonNavigationBarDelegate, UINavigationBarDelegate, UINavigationControllerDelegate, LMImageManagerDelegate, LMLandscapeNavigationBarDelegate, LMThemeEngineDelegate, LMLayoutChangeDelegate, LMWarningDelegate, LMApplicationIdleDelegate,

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

@property NSArray *cachedMusicTrackCollections;

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
@property MBProgressHUD *playPauseStatusHUD;

@property UIView *buttonNavigationBarBottomCoverView;

@property BOOL orientationChangedOutsideOfView;
@property (readonly) BOOL requiresRefresh;

@property LMWarningManager *warningManager;
@property LMWarning *downloadImagesOnDataOrLowStorageWarning;
@property LMWarning *librarySyncingWarning;

@property LMSource *selectedSource;

@property Popover *nowPlayingHintPopover;

//@property UIView *iPhoneXStatusBarCoverView;

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

- (void)musicLibraryChanged:(BOOL)finished {
	if(!finished && !self.librarySyncingWarning){
		self.librarySyncingWarning = [LMWarning warningWithText:NSLocalizedString(@"SyncingLibrary", nil) priority:LMWarningPriorityHigh];
		[self.warningManager addWarning:self.librarySyncingWarning];
	}
	else if(finished){
		[self asyncReloadCachedMusicTrackCollections];

		if(self.musicPlayer.nowPlayingCollection.count == 0 && self.musicPlayer.nowPlayingWasSetWithinLigniteMusic){
			[self dismissNowPlaying];
			[self.musicPlayer pause];
			self.musicPlayer.nowPlayingTrack = nil;
		}
		
		[self.warningManager removeWarning:self.librarySyncingWarning];
		
		if((self.selectedSource.lmIcon != LMIconSettings) && (self.selectedSource.lmIcon != LMIconBug)){
			[self sourceSelected:self.selectedSource];
		}
		
		self.librarySyncingWarning = nil;
		
		LMWarning *libraryFinishedWarning = [LMWarning warningWithText:NSLocalizedString(@"LibraryFinishedSyncing", nil) priority:LMWarningPrioritySuccess];
		[self.warningManager addWarning:libraryFinishedWarning];
		
		[NSTimer scheduledTimerWithTimeInterval:5.0 block:^{
			[self.warningManager removeWarning:libraryFinishedWarning];
		} repeats:NO];
	}
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

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
//	NSLog(@"Got new playback state %d", newState);
	BOOL isPlaying = (newState == LMMusicPlaybackStatePlaying);
	
	if(self.playPauseStatusHUD){
		[self.playPauseStatusHUD hideAnimated:YES];
	}
		
	self.playPauseStatusHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	
	self.playPauseStatusHUD.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:isPlaying ? @"icon_play_padded.png" : @"icon_pause_padded.png"]
					  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	self.playPauseStatusHUD.customView = [[UIImageView alloc] initWithImage:image];
	self.playPauseStatusHUD.square = YES;
	self.playPauseStatusHUD.userInteractionEnabled = NO;
	self.playPauseStatusHUD.label.text = NSLocalizedString(isPlaying ? @"Playing" : @"Paused", nil);
	
	[self.playPauseStatusHUD hideAnimated:YES afterDelay:1.5f];	
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
//	NSLog(@"HEY! Got new track, title %@", newTrack.title);
    
//    if(!self.buttonNavigationBar.isCompletelyHidden){
//		[self.buttonNavigationBar maximize:YES];
//        [self.buttonNavigationBar setSelectedTab:LMNavigationTabMiniplayer];
//    }
	
//	[self launchNowPlayingFromNavigationBar];
}

- (void)userAttemptedToModifyQueueThatIsManagedByiOS {
	LMAlertViewController *alertViewController = [LMAlertViewController new];
	alertViewController.titleText = NSLocalizedString(@"UnableToQueueTitle", nil);
	alertViewController.bodyText = NSLocalizedString(@"UnableToQueueDescription", nil);
	alertViewController.checkboxText = NSLocalizedString(@"UnableToQueueCheckboxText", nil);
	alertViewController.checkboxMoreInformationText = NSLocalizedString(@"TapHereForMoreInformation", nil);
	alertViewController.checkboxMoreInformationLink = @"https://www.LigniteMusic.com/unknown_track";
	alertViewController.alertOptionColours = @[ [LMColour mainColour] ];
	alertViewController.alertOptionTitles = @[ NSLocalizedString(@"Continue", nil) ];
	alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
		NSLog(@"All cool");
	};
	[self.navigationController presentViewController:alertViewController
											animated:YES
										  completion:nil];
}

- (void)trackAddedToQueue:(LMMusicTrack*)trackAdded {
	UIView *view = self.searchViewController.view ? self.searchViewController.view : self.navigationController.view;
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"TrackQueued", nil);
	
	[hud hideAnimated:YES afterDelay:3.f];
}

- (void)trackAddedToFavourites:(LMMusicTrack *)track {
	UIView *view = self.searchViewController.view ? self.searchViewController.view : self.navigationController.view;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	
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
	UIView *view = self.searchViewController.view ? self.searchViewController.view : self.navigationController.view;
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	
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

- (void)asyncReloadCachedMusicTrackCollections {
	__weak id weakSelf = self;
	
	self.cachedMusicTrackCollections = nil;
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceBackground, 0), ^{
		id strongSelf = weakSelf;
		
		if(!strongSelf){
			return;
		}
		
		NSLog(@"Beginning process of syncing new music.");
		
		LMCoreViewController *coreViewController = strongSelf;
		
		NSMutableArray *musicCollections = [NSMutableArray new];
		
		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		coreViewController.syncTimeStamp = startTime;
		
		for(int i = 0; i <= LMMusicTypeComposers; i++){
			if(coreViewController.syncTimeStamp != startTime){
				NSLog(@"Abandoning this thread, another sync notification has come in.");
				return;
			}
			
			LMMusicType musicType = i;
//			NSLog(@"Loading %d", musicType);
			NSArray *shitpost = [coreViewController.musicPlayer queryCollectionsForMusicType:musicType];
			[musicCollections addObject:shitpost];
		}
		
		coreViewController.cachedMusicTrackCollections = [NSArray arrayWithArray:musicCollections];
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		
		NSLog(@"Took %f seconds to complete sync.", endTime-startTime);
		NSLog(@"Cached collections now ready.");
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
	if(self.cachedMusicTrackCollections){
		if(musicType == LMMusicTypePlaylists){
			NSLog(@"I would load from the cache, but instead, I'll load the playlists fresh.");
			self.compactView.musicTrackCollections = [[LMPlaylistManager sharedPlaylistManager] playlistTrackCollections];
		}
		else{
			NSLog(@"Loading music from cache.");
			self.compactView.musicTrackCollections = [self.cachedMusicTrackCollections objectAtIndex:musicType];
		}
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
	
//	NSLog(@"now playing open %d", self.nowPlayingCoreView.isOpen);
	
	return self.nowPlayingCoreView.isOpen //If now playing is open, hide it
	|| self.layoutManager.isLandscape; //If the device is landscape, hide it
//		|| (![LMLayoutManager isiPad] && ![LMLayoutManager isiPhoneX] && self.buttonNavigationBar.currentlySelectedTab == LMNavigationTabView && !self.buttonNavigationBar.isMinimized && !self.buttonNavigationBar.isCompletelyHidden); //If the view tab is open and the whole thing isn't minimized (doesn't apply to iPad as iPad has compact button navigation bar, also doesn't apply to iPhone X because it has the infamous notch)
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
	if(source.lmIcon != LMIconSettings && source.lmIcon != LMIconBug){
		self.selectedSource = source;
	}
	
	if(!source.shouldNotHighlight){
		[self.currentSource setHidden:YES];
		static BOOL initialized = NO;
		if(initialized){
			[self.buttonNavigationBar setSelectedTab:LMNavigationTabBrowse];
		}
		else{
			initialized = YES;
		}
		
		[self.buttonNavigationBar setCurrentSourceIcon:source.lmIcon];
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
				[self.titleView.songListTableView setContentOffset:CGPointZero animated:NO];
				
				[self.titleView rebuildTrackCollection];
				[self.titleView.songListTableView reloadSubviewData];
				[self.titleView.songListTableView reloadData];
				
				//Reload currently highlighted item   
				self.titleView.currentlyHighlighted = -1;
				[self.titleView musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
				
				[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
			}
			
			self.buttonNavigationBar.browsingBar.letterTabBar.lettersDictionary =
			[self.musicPlayer lettersAvailableDictionaryForMusicTrackCollectionArray:@[self.titleView.musicTitles]
															 withAssociatedMusicType:LMMusicTypeTitles];
			
			[self logMusicTypeView:LMMusicTypeTitles];
			break;
		}
		case LMIconFavouriteBlackFilled: {
			BOOL requiresReload = self.titleView.favourites == NO;
			
			self.titleView.favourites = YES;
			self.compactView.hidden = YES;
			self.titleView.hidden = NO;
			self.currentSource = self.titleView;
			
			self.musicType = LMMusicTypeFavourites;
			
			if(requiresReload){
				[self.titleView.songListTableView setContentOffset:CGPointZero animated:NO];
				
				//Reload currently highlighted item
				self.titleView.currentlyHighlighted = -1;
				[self.titleView musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
				//				self.titleView.songListTableView.contentOffset = CGPointZero;
			}
			
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
	
//	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:NO];
	[self.landscapeNavigationBar setMode:LMLandscapeNavigationBarModeWithBackButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
//	[self.buttonNavigationBar.browsingBar setShowingLetterTabs:YES];
	[self.landscapeNavigationBar setMode:self.musicType == LMMusicTypePlaylists ? LMLandscapeNavigationBarModePlaylistView : LMLandscapeNavigationBarModeOnlyLogo];
	
	if(self.musicType == LMMusicTypePlaylists){
		[self.landscapeNavigationBar setEditing:self.compactView.editing];
	}
	
	self.searchViewController = nil;
}

- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration {
//	NSLog(@"rHeight changed to %f", requiredHeight);
    
    CGFloat bottomSpacing = requiredHeight + 10;
//    [self.compactView changeBottomSpacing:bottomSpacing];
    self.titleView.songListTableView.bottomSpacing = bottomSpacing;
	
	if([LMLayoutManager isLandscape]
	   && (self.buttonNavigationBar.currentlySelectedTab != LMNavigationTabView)){
		self.titleView.shuffleButtonLandscapeOffset = self.buttonNavigationBar.isMinimized ? 4.0f : bottomSpacing;
	}
	
	
	if([LMLayoutManager isiPhoneX]){
		bottomSpacing += [LMLayoutManager isLandscape] ? 100.0f : (-50.0f);
	}
		
//	if(self.buttonNavigationBar.isMinimized){
//		bottomSpacing *= 2;
//	}
	
//	bottomSpacing = 0;
	
	UIEdgeInsets newInsets = self.compactView.collectionView.contentInset;
	newInsets.bottom = [LMLayoutManager isLandscape] ? (LMLayoutManager.isiPhoneX ? 200 : 100) : bottomSpacing;
	[UIView animateWithDuration:0.4 animations:^{
		self.compactView.collectionView.contentInset = newInsets;
	}];
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
		NSInteger index = [self.titleView scrollToTrackWithPersistentID:persistentID];
		if(index > -1){
			[NSTimer scheduledTimerWithTimeInterval:0.60 block:^{
				[self.titleView tapEntryAtIndex:index];
			} repeats:NO];
		}
	}
	else{
		LMCompactBrowsingView *compactView = self.currentSource;
		NSInteger indexScrolledTo = [compactView scrollToItemWithPersistentID:persistentID];
		if(indexScrolledTo > -1){
			[NSTimer scheduledTimerWithTimeInterval:0.60 block:^{
				[self.compactView tappedBigListEntryAtIndex:indexScrolledTo];
			} repeats:NO];
		}
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
		[self.currentSource scrollViewToIndex:index animated:NO];
	}
}

- (void)swipeDownGestureOccurredOnLetterTabBar {
//	[self.buttonNavigationBar minimize:NO];
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
//		if([LMLayoutManager isiPhoneX]){
//			[self.navigationController.view bringSubviewToFront:self.iPhoneXStatusBarCoverView];
//		}
		[self.navigationController.view bringSubviewToFront:self.nowPlayingCoreView];
	}
}

- (void)launchNowPlayingFromTap {
	[self launchNowPlaying:YES];
}

- (void)launchNowPlaying:(BOOL)userLaunched {
    if(!self.musicPlayer.nowPlayingTrack){
		if(userLaunched){
			NSLog(@"Nothing's playing mate");
			
			CGPoint startPoint = CGPointZero;
			CGRect aViewFrame = CGRectZero;
			if(LMLayoutManager.isLandscape){
				startPoint = CGPointMake(self.landscapeNavigationBar.frame.size.width / 2.0,
										 (self.landscapeNavigationBar.frame.size.height / 2.0) + 34);
				
				aViewFrame = CGRectMake(0, 0, self.view.frame.size.height - startPoint.x, 80);
			}
			else{
				startPoint = CGPointMake(self.view.frame.size.width / 2.0,
										 self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y + 4);;
				
				aViewFrame = CGRectMake(0, 0, self.view.frame.size.width - 40, 80);
			}
			UIView *aView = [[UIView alloc]initWithFrame:aViewFrame];
			
			UILabel *hintLabel = [UILabel newAutoLayoutView];
			hintLabel.text = NSLocalizedString(@"NowPlayingButtonHint", nil);
			hintLabel.textAlignment = NSTextAlignmentCenter;
			hintLabel.numberOfLines = 0;
			hintLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
			[aView addSubview:hintLabel];
			
			[hintLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
			[hintLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
			[hintLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom];
			[hintLabel autoPinEdgeToSuperviewMargin:ALEdgeTop].constant = 6;
			
			Popover *popover = [Popover new];
			[popover show:aView point:startPoint];
			
			self.nowPlayingHintPopover = popover;
		}
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

- (void)dismissNowPlaying {
	[self.nowPlayingCoreView.superview layoutIfNeeded];
	
	self.nowPlayingCoreView.topConstraint.constant = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height) * 1.50f;
	
	self.nowPlayingCoreView.isOpen = NO;
	
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
	
//    NSLog(@"Dick is not a bone 哈哈哈");
	
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
		
		NSLog(@"What %@", NSStringFromCGPoint(translation));
		
		if((fabs(translation.y) < MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height)/14.0) || (translation.y >= 0)){
//			if(translation.y > self.nowPlayingCoreView.frame.size.height/8.0){
//				[self.buttonNavigationBar minimize:NO];
//			}
			
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	self.layoutManager.traitCollection = self.traitCollection;
	[self.layoutManager traitCollectionDidChange:previousTraitCollection];
	
	if([LMLayoutManager isiPad]){
		self.splashImageView.image = [UIImage imageNamed:@"splash_ipad_2018.png"];
	}
	else{
		self.splashImageView.image = [UIImage imageNamed:[LMLayoutManager sharedLayoutManager].isLandscape ? @"splash_landscape_2018.png" : @"splash_portrait_2018.png"];
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
		NSLog(@"Rotating %@", self.landscapeNavigationBar);
		
		if(self.landscapeNavigationBar){ //The view hasn't been initialized yet if the landscape navigation bar is nil (ie. user is still in onboarding tutorial view)
			[self.navigationController setNavigationBarHidden:NO];
			self.landscapeNavigationBar.hidden = NO;
			
			self.navigationController.navigationBar.layer.opacity = willBeLandscape ? 0.0 : 1.0;
			self.landscapeNavigationBar.layer.opacity = !willBeLandscape ? 0.0 : 1.0;
			
			self.nowPlayingCoreView.topConstraint.constant = self.nowPlayingCoreView.isOpen ? 0 : (size.height*1.50);
			
			[self.nowPlayingHintPopover dismiss];
		}
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		NSLog(@"Rotated");
		
		UITraitCollection *previousCollection = self.traitCollection;
		self.layoutManager.traitCollection = self.traitCollection;
		[self.layoutManager traitCollectionDidChange:previousCollection];
		
		self.layoutManager.size = self.view.frame.size;
		
		if(self.landscapeNavigationBar){ //The view hasn't been initialized yet if the landscape navigation bar is nil (ie. user is still in onboarding tutorial view)
			[self.navigationController setNavigationBarHidden:willBeLandscape];
			self.landscapeNavigationBar.hidden = !willBeLandscape;
			
			if([LMLayoutManager isiPhoneX]){
				self.landscapeNavigationBar.frame = CGRectMake(0, 0, ([LMLayoutManager notchPosition] == LMNotchPositionLeft) ? 94.0 : 64.0, self.layoutManager.isLandscape ? (self.view.frame.size.height + self.navigationController.navigationBar.frame.size.height) : self.view.frame.size.width);
			}
			
			[self.navigationController.view bringSubviewToFront:self.buttonNavigationBar];
			//		if([LMLayoutManager isiPhoneX]){
			//			[self.navigationController.view bringSubviewToFront:self.iPhoneXStatusBarCoverView];
			//		}
			[self.navigationController.view bringSubviewToFront:self.nowPlayingCoreView];
			
			
			[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
				[UIView animateWithDuration:0.25 animations:^{
					[self setNeedsStatusBarAppearanceUpdate];
				}];
			} repeats:NO];
		}
		
		if(!self.view.window){
			self.orientationChangedOutsideOfView = YES;
		}
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
			
			[self launchNowPlaying:YES];
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
	
	NSLog(@"What boi encoding restore state %d", (int)self.compactView.flowLayoutIndexOfItemDisplayingDetailView);
	
//	[coder encodeObject:self.navigationController.navigationBar.items forKey:LMNavigationBarItemsKey];
	
	LMCoreViewControllerRestorationState newRestorationState = LMCoreViewControllerRestorationStateBrowsing;
	
	NSArray<Class> *outofViewLoadingIndicatorSupportingClasses = @[
															[LMSettingsViewController class],
															[LMFeedbackViewController class]
															];
	
	BOOL navigationControllerContainsClass = NO;
	
	for(UIViewController *viewController in self.navigationController.viewControllers){
		for(Class outofViewClass in outofViewLoadingIndicatorSupportingClasses){
			if([viewController class] == outofViewClass){
				navigationControllerContainsClass = YES;
				break;
			}
		}
	}
	
	if(navigationControllerContainsClass && (self.view.window == nil)){
		newRestorationState = LMCoreViewControllerRestorationStateOutOfView;
	}
	else if(self.nowPlayingCoreView.isOpen){
		newRestorationState = LMCoreViewControllerRestorationStateNowPlaying;
	}
	
	[coder encodeInteger:newRestorationState forKey:LMCoreViewControllerRestorationStateKey];
	[coder encodeInteger:self.buttonNavigationBar.currentlySelectedTab forKey:LMCoreViewControllerStateRestoredNavigationTabKey];
	[coder encodeBool:self.buttonNavigationBar.isMinimized forKey:LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey];
	[coder encodeInteger:self.compactView.flowLayoutIndexOfItemDisplayingDetailView
				  forKey:LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex];
	[coder encodeInteger:[self.titleView topTrackPersistentID] forKey:LMCoreViewControllerStateRestoredTitleViewTopPersistentID];
	
	NSLog(@"Nice boi %d", (int)self.compactView.flowLayoutIndexOfItemDisplayingDetailView);
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	NSLog(@"What boi!! got %@", [coder decodeObjectForKey:LMCoreViewControllerRestorationStateKey]);
	
	LMCoreViewControllerRestorationState newRestorationState = [coder decodeIntegerForKey:LMCoreViewControllerRestorationStateKey];
	LMNavigationTab navigationTab = [coder decodeIntegerForKey:LMCoreViewControllerStateRestoredNavigationTabKey];
	BOOL navigationBarWasMinimized = [coder decodeBoolForKey:LMCoreViewControllerStateRestoredNavigationBarWasMinimizedKey];
	NSInteger previouslyOpenedDetailViewIndex = -1;
	if([coder decodeObjectForKey:LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex]){
		previouslyOpenedDetailViewIndex = [coder decodeIntegerForKey:LMCoreViewControllerStateRestoredPreviouslyOpenedDetailViewIndex];
	}
	else{
		NSLog(@"Nope");
	}
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

	UITapGestureRecognizer *nowPlayingTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(launchNowPlayingFromTap)];
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
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		if(![userDefaults objectForKey:LMLastUsedVersionKey]){
			[userDefaults setObject:[LMDebugViewController buildNumberString] forKey:LMLastUsedVersionKey];
			NSLog(@"Set %@", [userDefaults objectForKey:LMLastUsedVersionKey]);
		}
		
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
	
	
	if(!LMMusicPlayer.onboardingComplete){
		NSLog(@"Launching onboarding...");
		
//		[[MPMusicPlayerController systemMusicPlayer] stop];
		
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
	else if([[NSUserDefaults standardUserDefaults] objectForKey:LMGuideViewControllerUserWantsToViewTutorialKey]){
		self.restorationState = LMCoreViewControllerRestorationStateNotRestored;
		
		LMTutorialViewController *tutorialViewer = [LMTutorialViewController new];
		tutorialViewer.wasPresented = YES;
		
		LMRestorableNavigationController *restorableNavigationController = [[LMRestorableNavigationController alloc]initWithRootViewController:tutorialViewer];
		
		[self.navigationController presentViewController:restorableNavigationController animated:YES completion:nil];
	}
	else{
		static dispatch_once_t mainSetupToken;
		dispatch_once(&mainSetupToken, ^{
			NSLog(@"Launch main view controller contents");
			
			[[LMAppleWatchBridge sharedAppleWatchBridge] sendOnboardingStatusToWatch];
			
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
		[[LMImageManager sharedImageManager] displayDataAndStorageExplicitPermissionAlertWithCompletionHandler:
		 ^(BOOL authorized) {
			NSLog(@"Authorized: %d", authorized);
			
//			if(!authorized){
//				[[LMImageManager sharedImageManager] clearAllCaches];
//			}
			
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			
			hud.mode = MBProgressHUDModeCustomView;
			UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			hud.customView = [[UIImageView alloc] initWithImage:image];
			hud.square = YES;
			hud.label.text = NSLocalizedString(authorized ? @"Authorized" : @"DownloadingStopped", nil);
			hud.userInteractionEnabled = NO;
			
			[hud hideAnimated:YES afterDelay:3.f];
			
		    [self.warningManager removeWarning:self.downloadImagesOnDataOrLowStorageWarning];
		    [[LMImageManager sharedImageManager] downloadIfNeededForAllCategories];
		}];
	}
}

- (void)userInteractionBecameIdle {
	if(self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying && self.view.window){
		[self launchNowPlaying:NO];
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
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceBackground, 0), ^{
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		if(![userDefaults objectForKey:@"libraryChecked"]){
			NSInteger titlesCount = [[self.musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles] firstObject].count;
			NSInteger artistsCount = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists].count;
			NSInteger albumsCount = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists].count;
			NSInteger genresCount = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeGenres].count;
			NSInteger playlistsCount = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists].count;
			NSInteger compilationsCount = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeCompilations].count;
			
			NSDictionary *attributesDictionary = @{
												   @"Tracks": @(titlesCount),
												   @"Artists": @(artistsCount),
												   @"Albums": @(albumsCount),
												   @"Genres": @(genresCount),
												   @"Playlists": @(playlistsCount),
												   @"Compilations": @(compilationsCount)
												   };
			
			[LMAnswers logCustomEventWithName:@"Library Information" customAttributes:attributesDictionary];
			[userDefaults setObject:@"checked" forKey:@"libraryChecked"];
		}
	});
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
	
	
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
	
	//Tester
//	[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
//		[self.warningManager addWarning:self.downloadImagesOnDataOrLowStorageWarning];
//
//		[NSTimer scheduledTimerWithTimeInterval:5.0 block:^{
//			[self.warningManager removeWarning:self.downloadImagesOnDataOrLowStorageWarning];
//		} repeats:NO];
//	} repeats:NO];
	
	
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
//		self.iPhoneXStatusBarCoverView = [UIView newAutoLayoutView];
//		self.iPhoneXStatusBarCoverView.backgroundColor = [UIColor blueColor];
//		[self.navigationController.view addSubview:self.iPhoneXStatusBarCoverView];
//
//		[self.iPhoneXStatusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.iPhoneXStatusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[self.iPhoneXStatusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.iPhoneXStatusBarCoverView autoSetDimension:ALDimensionHeight toSize:44.0f];
//	}
	
	
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
	
	
	
	LMApplication *application = (LMApplication*)[UIApplication sharedApplication];
	application.coreViewController = self;
	[application addDelegate:self];
	
	
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	imageManager.navigationController = self.navigationController;
	[imageManager addDelegate:self];
	
	
	LMPlaylistManager *playlistManager = [LMPlaylistManager sharedPlaylistManager];
	playlistManager.navigationController = self.navigationController;
	
	
	
	self.loaded = YES;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self setNeedsStatusBarAppearanceUpdate];
	}];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
		self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
		self.backgroundBlurView.userInteractionEnabled = NO;
		[self.navigationController.view addSubview:self.backgroundBlurView];
		
		[self.backgroundBlurView autoPinEdgesToSuperviewEdges];
		
		[self.navigationController.view insertSubview:self.buttonNavigationBar aboveSubview:self.backgroundBlurView];
		[self.navigationController.view insertSubview:self.buttonNavigationBarBottomCoverView aboveSubview:self.buttonNavigationBar];
		[self.navigationController.view insertSubview:self.nowPlayingCoreView aboveSubview:self.buttonNavigationBar];
	} repeats:NO];
	
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
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
			[self launchNowPlaying:NO];
		}
		
		if(self.previousTitleViewTopPersistentID > 0){
			[self.titleView scrollToTrackWithPersistentID:self.previousTitleViewTopPersistentID];
		}
		
		if(self.titleView.favourites && (self.currentSource == self.titleView)){
			[self.buttonNavigationBar.browsingBar setShowingLetterTabs:self.titleView.musicTitles.count > 0];
		}
		
		
		if(self.previouslyOpenedDetailViewIndex > -1 && self.previouslyOpenedDetailViewIndex < self.compactView.musicTrackCollections.count){
			[self.compactView scrollViewToIndex:self.previouslyOpenedDetailViewIndex animated:YES];
			if(self.previouslyOpenedDetailViewIndex < self.compactView.musicTrackCollections.count){
				[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
					[self.compactView tappedBigListEntryAtIndex:self.previouslyOpenedDetailViewIndex];
				} repeats:NO];
			}
		}
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSString *iOSVersionString = [[UIDevice currentDevice] systemVersion];
		if([iOSVersionString containsString:@"11.2"] && ![userDefaults objectForKey:LMiOS_11_2_LagUnderstandingConfirmationKey]){
			LMAlertViewController *alertViewController = [LMAlertViewController new];
			alertViewController.titleText = NSLocalizedString(@"iOS_11_2_LagTitle", nil);
			alertViewController.bodyText = [NSString stringWithFormat:NSLocalizedString(@"iOS_11_2_LagDescription", nil), iOSVersionString];
			alertViewController.checkboxText = NSLocalizedString(@"iOS_11_2_LagCheckboxConfirmationText", nil);
			alertViewController.checkboxMoreInformationText = NSLocalizedString(@"TapHereForMoreInformation", nil);
			alertViewController.checkboxMoreInformationLink = @"https://www.LigniteMusic.com/ios_11.2_lag";
			alertViewController.alertOptionColours = @[ [LMColour mainColour] ];
			alertViewController.alertOptionTitles = @[ NSLocalizedString(@"Continue", nil) ];
			alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
				if(checkboxChecked){
					[userDefaults setObject:iOSVersionString forKey:LMiOS_11_2_LagUnderstandingConfirmationKey];
					
					NSLog(@"iOS 11.2 lag understood by user");
				}
			};
			[self.navigationController presentViewController:alertViewController
													animated:YES
												  completion:nil];
		}
		
		self.splashImageView.image = nil;
		self.splashImageView.backgroundColor = [UIColor whiteColor];
		
		[self asyncReloadCachedMusicTrackCollections];
		
		
#ifdef DEBUG //Will not run in production
		
		/*
		 *
		 * Test area
		 *
		 */
		
		
//		self.buttonNavigationBar.hidden = YES;
//
//
//		LMTutorialViewController *tutorialViewer = [LMTutorialViewController new];
//		[self.navigationController pushViewController:tutorialViewer animated:YES];

		
		
//		LMFeedbackViewController *feedbackController = [LMFeedbackViewController new];
//
//		LMRestorableNavigationController *navigation = [[LMRestorableNavigationController alloc] initWithRootViewController:feedbackController];
//		[navigation setNavigationBarHidden:YES];
//
//		[self.navigationController presentViewController:navigation animated:YES completion:nil];
		
//		[self launchNowPlaying];
		
//		LMSettingsViewController *settingsViewController = [LMSettingsViewController new];
//		[self.navigationController pushViewController:settingsViewController animated:YES];
		
//		LMThemePickerViewController *themePicker = [LMThemePickerViewController new];
//		[self.navigationController pushViewController:themePicker animated:YES];
		
//		UIViewController *controller = [
		
//		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//		LMSettingsViewController *settingsViewController = (LMSettingsViewController*)[storyboard instantiateViewControllerWithIdentifier:@"LMSettingsViewController"];
//		[self.navigationController pushViewController:settingsViewController animated:YES];
		
//		[playlistManager setUserUnderstandsPlaylistCreation:NO];
//		[playlistManager setUserUnderstandsPlaylistEditing:NO];

		
		
		
		//THIS TEST PLAYLIST CODE WILL CAUSE YOUR COMPACT VIEW TO NOT SYNC PROPERLY. DO NOT BE SPOOKED.
		
//		LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
//		LMPlaylist *playlist = [LMPlaylist new];
//		playlist.title = @"Nice meme";
//		playlist.image = [LMAppIcon imageForIcon:LMIconBug];
//		playlist.trackCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums].firstObject;
//		playlistViewController.playlist = playlist;
//		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:playlistViewController];
//		[self presentViewController:navigation animated:YES completion:^{
//
//		}];


//		LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
//		enhancedPlaylistViewController.delegate = self.compactView;
//		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
//		[self presentViewController:navigation animated:YES completion:^{
//
//		}];
		
//		[self searchDialogueOpened:YES withKeyboardHeight:0.0f];
		
#endif //DEBUG test area
		
		
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

