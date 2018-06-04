//
//  LMSettingsViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/24/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMThemePickerViewController.h"
#import "LMSettingsViewController.h"
#import "LMTutorialViewController.h"
#import "LMContactViewController.h"
#import "LMCreditsViewController.h"
#import "LMAlertViewController.h"
#import "LMDebugViewController.h"
#import "LMDemoViewController.h"
#import "LMSectionTableView.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "LMThemeEngine.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "LMSettings.h"
#import "LMAnswers.h"
#import "LMAppIcon.h"
#import "LMColour.h"

#define LMIndexPathOfCurrentlyOpenAlertViewKey @"LMIndexPathOfCurrentlyOpenAlertViewKey"

@interface LMSettingsViewController ()<LMSectionTableViewDelegate, LMImageManagerDelegate, UIViewControllerRestoration, LMThemeEngineDelegate, LMLayoutChangeDelegate>

@property LMSectionTableView *sectionTableView;

@property int debugTapCount;
@property int demoTapCount;

@property LMImageManager *imageManager;

@property UIAlertController *pendingViewController;

@property NSIndexPath *indexPathOfCurrentlyOpenAlertView;

@property LMLayoutManager *layoutManager;

@end

@implementation LMSettingsViewController

- (instancetype)init {
	self = [super init];
	if(self) {
		self.restorationIdentifier = [[LMSettingsViewController class] description];
		self.restorationClass = [LMSettingsViewController class];
	}
	return self;
}

- (UINavigationItem*)navigationItem {
	UINavigationItem *navigationItem = [super navigationItem];
	
	navigationItem.title = NSLocalizedString(@"Settings", nil);
	
	return navigationItem;
}

+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	return [LMSettingsViewController new];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	self.indexPathOfCurrentlyOpenAlertView = [coder decodeObjectForKey:LMIndexPathOfCurrentlyOpenAlertViewKey];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		if(self.indexPathOfCurrentlyOpenAlertView){
			[self tappedIndexPath:self.indexPathOfCurrentlyOpenAlertView forSectionTableView:self.sectionTableView];
			self.indexPathOfCurrentlyOpenAlertView = nil;
		}
	} repeats:NO];
	
	[super decodeRestorableStateWithCoder:coder];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	if(self.indexPathOfCurrentlyOpenAlertView){
		[coder encodeObject:self.indexPathOfCurrentlyOpenAlertView forKey:LMIndexPathOfCurrentlyOpenAlertViewKey];
	}
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)tappedCloseButtonForSectionTableView:(LMSectionTableView *)sectionTableView {
	[(UINavigationController*)self.view.window.rootViewController popViewControllerAnimated:YES];
}

- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return [LMAppIcon imageForIcon:LMIconLookAndFeel];
		case 1:
			return [LMAppIcon imageForIcon:LMIconFunctionality];
		case 2:
			return [LMAppIcon imageForIcon:LMIconCloudDownload];
		case 3:
			return [LMAppIcon imageForIcon:LMIconAbout];
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return NSLocalizedString(@"LookAndFeel", nil);
		case 1:
			return NSLocalizedString(@"Functionality", nil);
		case 2:
			return NSLocalizedString(@"ImageDownloads", nil);
		case 3:
			return NSLocalizedString(@"About", nil);
	}
	return @"Unknown section";
}

- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return 3;
		case 1:
			return 1;
		case 2:
			return 2;
		case 3:
			return 4;
	}
	return 0;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	if(self.navigationController.viewControllers.count > 0){
		if(!self.coreViewController){
			for(UIViewController *viewController in self.navigationController.viewControllers){
				NSLog(@"Settings subviewcontroller %@", [[viewController class] description]);
				if([viewController class] == [LMCoreViewController class]){
					self.coreViewController = (LMCoreViewController*)viewController;
				}
			}
			NSLog(@"%d subviewcontrollers", (int)self.navigationController.viewControllers.count);
		}
	}
	
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ScrollingTextTitle", nil);
				case 1:
					return NSLocalizedString(@"Theme", nil);
				case 2:
					return NSLocalizedString(@"NowPlayingKeepScreenOnTitle", nil);
			}
			break;
		case 1:
			switch (indexPath.row){
				case 0:
					return NSLocalizedString(@"OptimiseLoadTimeTitle", nil);
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ImagesDownloadWarningTitle", nil);
				case 1:
					return NSLocalizedString(@"ExplicitImageDownloadingTitle", nil);
//				case 2:
//					return NSLocalizedString(@"HighQualityImagesTitle", nil);
			}//
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Tutorial", nil);
				case 1:
					return NSLocalizedString(@"LeaveAReviewTitle", nil);
				case 2:
					return NSLocalizedString(@"Credits", nil);
				case 3:
					return NSLocalizedString(@"ContactUs", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (NSString*)subtitleForDownloadPermission {
	LMImageManagerPermissionStatus artistImagesStatus = [self.imageManager downloadPermissionStatus];
	
	BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
	
	NSString *approvedString = NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
	
	NSString *takingUpString = [NSString stringWithFormat:NSLocalizedString(@"TakingUpXMB", nil), (CGFloat)[self.imageManager sizeOfAllCaches]/1000000];
	
	return [NSString stringWithString:[NSMutableString stringWithFormat:@"%@ - %@", takingUpString, approvedString]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ScrollingTextDescription", nil);
				case 1: {
					NSString *themeTitleKey = [NSString stringWithFormat:@"%@_Title", [[LMThemeEngine sharedThemeEngine] keyForTheme:LMThemeEngine.currentTheme]];
					return NSLocalizedString(themeTitleKey, nil);
				}
				case 2:
					return NSLocalizedString(@"NowPlayingKeepScreenOnSubtitle", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					return NSLocalizedString(@"OptimiseLoadTimeSubtitle", nil);
				}
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0: {
					return [self subtitleForDownloadPermission];
				}
				case 1: {
					LMImageManagerPermissionStatus explicitPermissionStatus = [self.imageManager explicitPermissionStatus];
					switch(explicitPermissionStatus){
						case LMImageManagerPermissionStatusDenied:
							return NSLocalizedString(@"YouDeniedThis", nil);
						case LMImageManagerPermissionStatusAuthorized:
							return NSLocalizedString(@"YouAuthorizedThis", nil);
						case LMImageManagerPermissionStatusNotDetermined:
							return NSLocalizedString(@"YouHaventDeterminedThis", nil);
					}
					return @"fuck";
				}
//				case 2:
//					return NSLocalizedString(@"HighQualityImagesDescription", nil);
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"TutorialSettingsSubtitle", nil);
				case 1:
					return NSLocalizedString(@"LeaveAReviewDescription", nil);
				case 2:
					return NSLocalizedString(@"CreditsMore", nil);
				case 3:
					return nil;
				case 4:
					return NSLocalizedString([LMSettings userHasOptedOutOfTracking] ? @"OptedOut" : @"OptedIn" , nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return nil;
}

- (void)cacheSizeChangedTo:(uint64_t)newCacheSize forCategory:(LMImageManagerCategory)category {
	[self.sectionTableView reloadData];
}

- (void)cacheAlert {
	LMImageManagerPermissionStatus previousPermissionStatus = [self.imageManager downloadPermissionStatus];
	
	[self.imageManager displayDownloadingAuthorizationAlertWithCompletionHandler:^(BOOL authorized) {
												if(previousPermissionStatus != LMImageManagerPermissionStatusDenied){
													if(!authorized){
														MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
														
														hud.mode = MBProgressHUDModeCustomView;
														UIImage *image = [[UIImage imageNamed:@"icon_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
														hud.customView = [[UIImageView alloc] initWithImage:image];
														hud.square = YES;
														hud.label.text = NSLocalizedString(@"ImagesDeleted", nil);
														hud.userInteractionEnabled = NO;
														
														[hud hideAnimated:YES afterDelay:3.f];
													}
												}
												
												if(previousPermissionStatus == LMImageManagerPermissionStatusDenied) {
													if(authorized){
														[self.imageManager clearAllCaches];
														
														MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
														
														hud.mode = MBProgressHUDModeCustomView;
														UIImage *image = [[UIImage imageNamed:@"icon_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
														hud.customView = [[UIImageView alloc] initWithImage:image];
														hud.square = YES;
														hud.label.text = NSLocalizedString(@"WillBeginDownloading", nil);
														hud.userInteractionEnabled = NO;
														
														[hud hideAnimated:YES afterDelay:3.f];
														
														[self.imageManager downloadIfNeededForAllCategories];
													}
												}
												
												[self.sectionTableView reloadData];
												
												self.indexPathOfCurrentlyOpenAlertView = nil;
											}];
}

- (void)explicitAlert {
	[self.imageManager displayDataAndStorageExplicitPermissionAlertWithCompletionHandler:^(BOOL authorized) {
														[self.sectionTableView reloadData];
														
														self.indexPathOfCurrentlyOpenAlertView = nil;
													}];
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0: {
					NSLog(@"secret taps");
					self.debugTapCount++;
					if(self.debugTapCount > 5){
						NSLog(@"Hey boi");
						LMDebugViewController *debugViewController = [LMDebugViewController new];
						debugViewController.title = @"Debug";
						[self.coreViewController.navigationController showViewController:debugViewController sender:self];
					}
					if(self.debugTapCount == 1){
						NSLog(@"Timer registered");
						[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
							self.debugTapCount = 0;
							NSLog(@"Timer reset");
						} repeats:NO];
					}
					
					UISwitch *rowSwitch = [self accessoryViewForIndexPath:indexPath forSectionTableView:sectionTableView];
					[rowSwitch setOn:!rowSwitch.on animated:YES];
					NSLog(@"%@ Now on %d", rowSwitch, rowSwitch.on);
					
					UITableViewCell *cell = [self.sectionTableView cellForRowAtIndexPath:indexPath];
					NSLog(@"Cell %@", cell);
					UISwitch *cellSwitch = nil;
					for(UIView *subview in cell.contentView.subviews){
						NSLog(@"Subview %@", subview);
						for(UIView *deepSubview in subview.subviews){
							NSLog(@"> %@", deepSubview);
							if([deepSubview class] == [UISwitch class]){
								cellSwitch = (UISwitch*)deepSubview;
								break;
							}
						}
					}
					if(cellSwitch){
						[cellSwitch setOn:!cellSwitch.on animated:YES];
						
						[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
							NSString *announcement = [NSString stringWithFormat:@"Switch %@", (cellSwitch.on ? @"on" : @"off")];
							UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, // announce
															announcement);  // actual text
						} repeats:NO];
					}
					break;
				}
				case 1: {
					LMThemePickerViewController *themePicker = [LMThemePickerViewController new];
//					themePicker.navigationItem = [[UINavigationItem alloc]initWithTitle:@"test"];
					[self.navigationController pushViewController:themePicker animated:YES];
										
					[LMAnswers logCustomEventWithName:@"Viewed Themes" customAttributes:nil];
					break;
				}
				case 2: {
					NSLog(@"Demo secret taps");
					self.demoTapCount++;
					if(self.demoTapCount > 5){
						NSLog(@"Demo hey boi");
						LMDemoViewController *demoViewController = [LMDemoViewController new];
						demoViewController.title = @"Super Secret Settings";
						[self.coreViewController.navigationController showViewController:demoViewController sender:self];
					}
					if(self.demoTapCount == 1){
						NSLog(@"Demo timer registered");
						[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
							self.demoTapCount = 0;
							NSLog(@"Demo timer reset");
						} repeats:NO];
					}
				}
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					NSLog(@"Optimise load time");
					break;
				}
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0: {
					[self cacheAlert];
					break;
				}
				case 1: {
					[self explicitAlert];
					break;
				}
			}
			
			self.indexPathOfCurrentlyOpenAlertView = indexPath;
			break;
		case 3:
			switch(indexPath.row){
				case 0: {
					LMTutorialViewController *tutorialViewController = [LMTutorialViewController new];
					[self.navigationController showViewController:tutorialViewController sender:self];
					
					[LMAnswers logCustomEventWithName:@"Viewed Tutorial" customAttributes:nil];
					break;
				}
				case 1: {
					NSLog(@"Nice!");
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/lignite-music-player/id1041697715"] options:@{} completionHandler:^(BOOL success) {
						NSLog(@"Success %d", success);
					}];
					break;
				}
				case 2:{
					LMCreditsViewController *creditsViewController = [LMCreditsViewController new];
					[self.navigationController showViewController:creditsViewController sender:self];
					
					[LMAnswers logCustomEventWithName:@"Viewed Credits" customAttributes:nil];
					break;
				}
				case 3: {
					LMContactViewController *contactViewController = [LMContactViewController new];
					[self.navigationController showViewController:contactViewController sender:self];
                    
					
					[LMAnswers logCustomEventWithName:@"Viewed Contact Us Screen" customAttributes:nil];
					break;
				}
				case 4: {
					LMAlertViewController *alertViewController = [LMAlertViewController new];
					alertViewController.titleText = NSLocalizedString(@"UsageData", nil);
					alertViewController.bodyText = NSLocalizedString(@"UsageDataDescription", nil);
					alertViewController.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
					alertViewController.alertOptionTitles = @[NSLocalizedString(@"OptionOptOut", nil), NSLocalizedString(@"OptionOptIn", nil)];
					alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
						BOOL optedOut = (optionSelected == 0);
						
						NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
						
						if(optedOut && ![userDefaults objectForKey:LMSettingsKeyOptOutOfTracking]){ //User's opted out and never selected to opt out before
							[LMAnswers logCustomEventWithName:@"Opted-Out of Tracking" customAttributes:nil];
						}
						//User was previously opted out then opted back in
						else if([userDefaults objectForKey:LMSettingsKeyOptOutOfTracking] && [userDefaults boolForKey:LMSettingsKeyOptOutOfTracking] && !optedOut){
							[LMAnswers logCustomEventWithName:@"Opted Back Into Tracking" customAttributes:nil];
						}
						
						[userDefaults setBool:optedOut forKey:LMSettingsKeyOptOutOfTracking];
						[userDefaults synchronize];
						
						[self.sectionTableView reloadData];
						
						self.indexPathOfCurrentlyOpenAlertView = nil;
					};
					[self.coreViewController.navigationController presentViewController:alertViewController
																			   animated:YES
																			 completion:nil];
					
					self.indexPathOfCurrentlyOpenAlertView = indexPath;
					break;
				}
			}
			break;
	}
}

- (NSString*)accessibilityLabelForIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section){
		case 0: {
			switch(indexPath.row){
				case 0: {
					return NSLocalizedString(@"VoiceOverLabel_ScrollingTextSetting", nil);
				}
				case 1: {
					NSString *currentThemeTitleKey = [NSString stringWithFormat:@"%@_Title", NSLocalizedString([[LMThemeEngine sharedThemeEngine] keyForTheme:[LMThemeEngine currentTheme]], nil)];
					NSString *currentThemeString = NSLocalizedString(currentThemeTitleKey, nil);
					return [NSString stringWithFormat:NSLocalizedString(@"VoiceOverLabel_ThemeSetting", nil), currentThemeString];
				}
				case 2: {
					return NSLocalizedString(@"VoiceOverLabel_NowPlayingAlwaysOnSetting", nil);
				}
			}
		}
#warning Todo: add accessibility for this setting section
		case 1: {
			switch(indexPath.row){
				case 0: {
					LMImageManagerPermissionStatus artistImagesStatus = [self.imageManager downloadPermissionStatus];
					
					BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
					
					NSString *approvedString = NSLocalizedString(approved ? @"VoiceOverLabel_ImageDownloading_On" : @"VoiceOverLabel_ImageDownloading_Off", nil);
					
					NSString *fullLabelString = [NSString stringWithFormat:NSLocalizedString(@"VoiceOverLabel_ImageDownloading", nil), approvedString, ((CGFloat)[self.imageManager sizeOfAllCaches]/1000000)];
					
					return fullLabelString;
				}
				case 1: {
					NSString *authorizationStatusKey = nil;
					
					LMImageManagerPermissionStatus explicitPermissionStatus = [self.imageManager explicitPermissionStatus];
					switch(explicitPermissionStatus){
						case LMImageManagerPermissionStatusNotDetermined:
						case LMImageManagerPermissionStatusDenied: {
							authorizationStatusKey = @"VoiceOverLabel_CellularAndLowStorage_Off";
							break;
						}
						case LMImageManagerPermissionStatusAuthorized: {
							authorizationStatusKey = @"VoiceOverLabel_CellularAndLowStorage_On";
							break;
						}
					}
					
					NSString *localizedAuthorizationLabel = [NSString stringWithFormat:NSLocalizedString(@"VoiceOverLabel_CellularAndLowStorage", nil), NSLocalizedString(authorizationStatusKey, nil)];
					
					
					return localizedAuthorizationLabel;
				}
			}
		}
		case 2: {
			switch(indexPath.row){
				case 0: {
					return NSLocalizedString(@"VoiceOverLabel_Tutorial", nil);
				}
				case 1: {
					return NSLocalizedString(@"VoiceOverLabel_LeaveAReview", nil);
				}
				case 2: {
					return NSLocalizedString(@"VoiceOverLabel_Credits", nil);
				}
				case 3: {
					return NSLocalizedString(@"VoiceOverLabel_ContactUs", nil);
				}
			}
		}
	}
	
	return nil;
}

- (NSString*)accessibilityHintForIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section){
		case 0: {
			switch(indexPath.row){
				case 0: {
					return nil;
				}
				case 1: {
					return NSLocalizedString(@"VoiceOverHint_DoubleTapToOpenThemeSelector", nil);
				}
				case 2: {
					return nil;
				}
			}
		}
			#warning Todo: add accessibility for this setting section
		case 1: {
			return NSLocalizedString(@"VoiceOverHint_DoubleTapToChangeThisSetting", nil);
		}
		case 2: {
			switch(indexPath.row){
				case 0: {
					return NSLocalizedString(@"VoiceOverHint_DoubleTapToOpenTheTutorialPage", nil);
				}
				case 1: {
					return NSLocalizedString(@"VoiceOverHint_DoubleTapToOpenTheAppStore", nil);
				}
				case 2: {
					return NSLocalizedString(@"VoiceOverHint_DoubleTapToOpenTheCreditsPage", nil);
				}
				case 3: {
					return NSLocalizedString(@"VoiceOverHint_DoubleTapToOpenTheContactPage", nil);
				}
			}
		}
	}
	
	return nil;
}

- (void)didChangeScrollingTextSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyScrollingText];
	[userDefaults synchronize];
	
	[LMAnswers logCustomEventWithName:@"Scrolling Text" customAttributes:@{
																		   @"Disabled": @(!switchView.on)
																		   }];
}

- (void)didChangeScreenTimeoutOnNowPlayingSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyDisableScreenTimeoutOnNowPlaying];
	[userDefaults synchronize];
	
	[LMAnswers logCustomEventWithName:@"Disabled Now Playing Screen Timeout" customAttributes:@{
																								@"Disabled": @(switchView.on)
																								}];
}

- (void)didChangeQuickLoadSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyQuickLoad];
	[userDefaults synchronize];
	
	[LMAnswers logCustomEventWithName:@"Quick Load Setting" customAttributes:@{
																								@"Enabled": @(switchView.on)
																								}];
}

- (id)accessoryViewForIndexPath:(NSIndexPath *)indexPath forSectionTableView:(LMSectionTableView *)sectionTableView {
	UISwitch *switchView = [UISwitch new];
	
	NSString *settingsKey = nil;
	BOOL enabled = YES;
	
	switch(indexPath.section){
		case 0:
			if(indexPath.row == 0){
				[switchView addTarget:self action:@selector(didChangeScrollingTextSwitchView:) forControlEvents:UIControlEventValueChanged];
				
				enabled = YES; //Default
				settingsKey = LMSettingsKeyScrollingText;
			}
			else if(indexPath.row == 2){
				[switchView addTarget:self action:@selector(didChangeScreenTimeoutOnNowPlayingSwitchView:) forControlEvents:UIControlEventValueChanged];
				
				enabled = NO; //Default
				settingsKey = LMSettingsKeyDisableScreenTimeoutOnNowPlaying;
			}
			break;
		case 1:
			if(indexPath.row == 0){
				[switchView addTarget:self action:@selector(didChangeQuickLoadSwitchView:) forControlEvents:UIControlEventValueChanged];
				
				enabled = NO; //Default
				settingsKey = LMSettingsKeyQuickLoad;
			}
			break;
	}
	
	if(settingsKey){
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		if([userDefaults objectForKey:settingsKey]){
			enabled = [userDefaults boolForKey:settingsKey];
		}
		
		switchView.on = enabled;
		
		return switchView;
	}
	
	return nil;
}

- (BOOL)prefersStatusBarHidden {
	BOOL shouldShowStatusBar = [LMSettings shouldShowStatusBar];
		
	return !shouldShowStatusBar || self.layoutManager.isLandscape;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	[self.layoutManager adjustRootViewSubviewsForLandscapeNavigationBar:self.view];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	if(![LMLayoutManager isiPhoneX]){
		return;
	}
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Nothing, right now.
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
			[self notchPositionChanged:LMLayoutManager.notchPosition];
		} repeats:NO];
	}];
}

- (void)themeChanged:(LMTheme)theme {
	[self.sectionTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.imageManager = [LMImageManager sharedImageManager];
	[self.imageManager addDelegate:self];
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
	if(!self.layoutManager.traitCollection){
		self.layoutManager.traitCollection = self.traitCollection;
		self.layoutManager.size = self.view.frame.size;
	}
	
	self.sectionTableView = [LMSectionTableView newAutoLayoutView];
	self.sectionTableView.contentsDelegate = self;
	self.sectionTableView.totalNumberOfSections = 4;
	self.sectionTableView.title = NSLocalizedString(@"AppSettings", nil);
	self.sectionTableView.restorationIdentifier = @"LMAppSettingsSectionTableView";
	[self.view addSubview:self.sectionTableView];
	
	NSArray *sectionTableViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewPortraitConstraints:sectionTableViewPortraitConstraints];
	
	NSArray *sectionTableViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewLandscapeConstraints:sectionTableViewLandscapeConstraints];
	
	[self.sectionTableView setup];
	
	if([LMLayoutManager isiPhoneX]){
		[self notchPositionChanged:LMLayoutManager.notchPosition];
	}
	
#ifdef DEBUG
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
//		LMDemoViewController *demoViewController = [LMDemoViewController new];
//		demoViewController.title = @"Super Secret Settings";
//		[self.coreViewController.navigationController showViewController:demoViewController sender:self];
		
//		LMDebugViewController *debugViewController = [LMDebugViewController new];
//		[self.navigationController showViewController:debugViewController sender:self];
	} repeats:NO];
#endif
	
//	LMContactViewController *creditsViewController = [LMContactViewController new];
//	[self.coreViewController.navigationController showViewController:creditsViewController sender:self];
}

- (void)dealloc {
	[self.imageManager removeDelegate:self];
		
	[LMLayoutManager removeAllConstraintsRelatedToView:self.sectionTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
