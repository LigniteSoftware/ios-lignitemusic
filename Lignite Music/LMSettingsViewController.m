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
#import "LMContactViewController.h"
#import "LMCreditsViewController.h"
#import "LMDebugViewController.h"
#import "LMSectionTableView.h"
#import "LMPebbleManager.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMImageManager.h"
#import "LMThemeEngine.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "LMAlertView.h"
#import "LMSettings.h"
#import "LMAnswers.h"
#import "LMAppIcon.h"
#import "LMColour.h"

#define LMIndexPathOfCurrentlyOpenAlertViewKey @"LMIndexPathOfCurrentlyOpenAlertViewKey"

@interface LMSettingsViewController ()<LMSectionTableViewDelegate, LMImageManagerDelegate, UIViewControllerRestoration, LMThemeEngineDelegate>

@property LMSectionTableView *sectionTableView;

@property int debugTapCount;

@property LMImageManager *imageManager;

@property UIAlertController *pendingViewController;

@property NSIndexPath *indexPathOfCurrentlyOpenAlertView;

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

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {	
	switch(section){
		case 0:
			return [LMAppIcon imageForIcon:LMIconLookAndFeel];
		case 1:
			return [LMAppIcon imageForIcon:LMIconCloudDownload];
		case 2:
			return [LMAppIcon imageForIcon:LMIconFunctionality];
		case 3:
			return [LMAppIcon imageForIcon:LMIconAbout];
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return NSLocalizedString(@"LookAndFeel", nil);
		case 1:
			return NSLocalizedString(@"ImageDownloads", nil);
		case 2:
			return NSLocalizedString(@"Other", nil);
		case 3:
			return NSLocalizedString(@"About", nil);
	}
	return @"Unknown section";
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {	
	switch(section){
		case 0:
			return 2;
		case 1:
			return 2;
		case 2:
			return 1;
		case 3:
			return 2;
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
					[self.coreViewController prepareForOpenSettings];
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
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ImagesDownloadWarningTitle", nil);
				case 1:
					return NSLocalizedString(@"ExplicitImageDownloadingTitle", nil);
//				case 2:
//					return NSLocalizedString(@"HighQualityImagesTitle", nil);
			}//
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Pebble", nil);
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Credits", nil);
				case 1:
					return NSLocalizedString(@"ContactUs", nil);
				case 2:
					return NSLocalizedString(@"UsageData", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (NSString*)subtitleForDownloadPermission {
	LMImageManagerPermissionStatus artistImagesStatus = [self.imageManager downloadPermissionStatus];
	
	BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
	
	NSString *approvedString = NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
	
	NSString *takingUpString = [NSString stringWithFormat:NSLocalizedString(@"TakingUpXMB", nil), (float)[self.imageManager sizeOfAllCaches]/1000000];
	
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
			}
			break;
		case 1:
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
		case 2:
			switch(indexPath.row){
				case 0: {
					return nil;
				}
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"CreditsMore", nil);
				case 1:
					return nil;
				case 2:
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
	LMImageManagerPermissionStatus currentStatus = [self.imageManager downloadPermissionStatus];
	
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	NSString *titleKey = @"ImagesDownloadWarningTitle";
	NSString *youCanKey = @"";
	NSString *enableButtonKey = @"";
	NSString *disableButtonKey = @"";
	NSString *currentStatusText = @"";
	switch(currentStatus){
		case LMImageManagerPermissionStatusNotDetermined:
		case LMImageManagerPermissionStatusDenied:
			youCanKey = @"YouCanTurnOnTo";
			enableButtonKey = @"Enable";
			disableButtonKey = @"KeepDisabled";
			currentStatusText = NSLocalizedString(@"YouCurrentlyHaveThisFeatureOff", nil);
			break;
		case LMImageManagerPermissionStatusAuthorized:
			youCanKey = @"YouCanTurnOffTo";
			enableButtonKey = @"KeepEnabled";
			disableButtonKey = @"ClearCacheAndDisable";
			currentStatusText = [NSString stringWithFormat:NSLocalizedString(@"UsingXOfYourStorage", nil), (float)[self.imageManager sizeOfAllCaches]/1000000];
			break;
	}
	alertView.title = NSLocalizedString(titleKey, nil);
	
	alertView.body = [NSString stringWithFormat:NSLocalizedString(@"SettingImagesAlertDescription", nil), currentStatusText, NSLocalizedString(youCanKey, nil)];
	
	alertView.alertOptionTitles = @[NSLocalizedString(disableButtonKey, nil), NSLocalizedString(enableButtonKey, nil)];
	alertView.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
	
	[alertView launchOnView:self.coreViewController.navigationController.view withCompletionHandler:^(NSUInteger optionSelected) {
		//Reset the special permission statuses because the user's stance maybe different now and we'll have to recheck
		[self.imageManager setExplicitPermissionStatus:LMImageManagerPermissionStatusNotDetermined];
		
		LMImageManagerPermissionStatus previousPermissionStatus = [self.imageManager downloadPermissionStatus];
		
		//In the rare case that for some reason something was left behind in the cache, we want to make sure the disable button always clears it even if it's already disabled, just to make sure the user is happy.
		if(optionSelected == 0){
			[self.imageManager clearAllCaches];
		}
		
		if(previousPermissionStatus != LMImageManagerPermissionStatusDenied){
			if(optionSelected == 0){
				MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
				
				hud.mode = MBProgressHUDModeCustomView;
				UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				hud.customView = [[UIImageView alloc] initWithImage:image];
				hud.square = YES;
				hud.label.text = NSLocalizedString(@"ImagesDeleted", nil);
				hud.userInteractionEnabled = NO;
				
				[hud hideAnimated:YES afterDelay:3.f];
			}
		}
		
		if(previousPermissionStatus == LMImageManagerPermissionStatusDenied) {
			if(optionSelected == 1){
				[self.imageManager clearAllCaches];
				
				MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
				
				hud.mode = MBProgressHUDModeCustomView;
				UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				hud.customView = [[UIImageView alloc] initWithImage:image];
				hud.square = YES;
				hud.label.text = NSLocalizedString(@"WillBeginDownloading", nil);
				hud.userInteractionEnabled = NO;
				
				[hud hideAnimated:YES afterDelay:3.f];
				
				[self.imageManager downloadIfNeededForAllCategories];
			}
		}
		
		LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
		switch(optionSelected){
			case 0:
				permissionStatus = LMImageManagerPermissionStatusDenied;
				break;
			case 1:
				permissionStatus = LMImageManagerPermissionStatusAuthorized;
				break;
		}
		
		[self.imageManager setDownloadPermissionStatus:permissionStatus];
		
		[self.sectionTableView reloadData];
		
		self.indexPathOfCurrentlyOpenAlertView = nil;
	}];
}

- (void)explicitAlert {
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	alertView.title = NSLocalizedString(@"ExplicitImageDownloadingTitle", nil);
	
	alertView.body = NSLocalizedString(@"ExplicitImageDownloadingBody", nil);
	
	alertView.alertOptionTitles = @[NSLocalizedString(@"Deny", nil), NSLocalizedString(@"Allow", nil)];
	alertView.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
	
	[alertView launchOnView:self.coreViewController.navigationController.view withCompletionHandler:^(NSUInteger optionSelected) {
		//Reset the special permission statuses because the user's stance maybe different now and we'll have to recheck
		[self.imageManager setExplicitPermissionStatus:LMImageManagerPermissionStatusNotDetermined];
	
		if(optionSelected == 0){
			//no
		}
		else{
			//yes
		}
		
		LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
		switch(optionSelected){
			case 0:
				permissionStatus = LMImageManagerPermissionStatusDenied;
				break;
			case 1:
				permissionStatus = LMImageManagerPermissionStatusAuthorized;
				break;
		}
		
		[self.imageManager setExplicitPermissionStatus:permissionStatus];
		
		[self.sectionTableView reloadData];
		
		self.indexPathOfCurrentlyOpenAlertView = nil;
	}];
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					NSLog(@"secret taps");
					self.debugTapCount++;
					if(self.debugTapCount > 5){
						NSLog(@"Hey boi");
						LMDebugViewController *debugViewController = [LMDebugViewController new];
						[self.coreViewController.navigationController showViewController:debugViewController sender:self];
					}
					if(self.debugTapCount == 1){
						NSLog(@"Timer registered");
						[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
							self.debugTapCount = 0;
							NSLog(@"Timer reset");
						} repeats:NO];
					}
					break;
				case 1: {
					LMThemePickerViewController *themePicker = [LMThemePickerViewController new];
//					themePicker.navigationItem = [[UINavigationItem alloc]initWithTitle:@"test"];
					[self.navigationController pushViewController:themePicker animated:YES];
										
					[LMAnswers logCustomEventWithName:@"Viewed Themes" customAttributes:nil];
					break;
				}
			}
			break;
		case 1:
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
		case 2:
			switch(indexPath.row){
//				case 0: {
//					NSURL *pebbleURL = [NSURL URLWithString:@"pebble://appstore/579c3ee922f599cf7e0001ea"];
//					NSURL *pebbleWebURL = [NSURL URLWithString:@"http://apps.getpebble.com/en_US/application/579c3ee922f599cf7e0001ea"];
//					BOOL canOpenPebbleURL = [[UIApplication sharedApplication] canOpenURL:pebbleURL];
//					[[UIApplication sharedApplication] openURL:canOpenPebbleURL ? pebbleURL : pebbleWebURL];
//
//					[LMAnswers logCustomEventWithName:@"Opened Pebble App Install Link" customAttributes:nil];
//					break;
//				}
				case 0: {
					LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
					[pebbleManager showSettings];
					break;
				}
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:{
					LMCreditsViewController *creditsViewController = [LMCreditsViewController new];
					[self.navigationController showViewController:creditsViewController sender:self];
					
					[LMAnswers logCustomEventWithName:@"Viewed Credits" customAttributes:nil];
					break;
				}
				case 1: {
					LMContactViewController *contactViewController = [LMContactViewController new];
					[self.navigationController showViewController:contactViewController sender:self];
                    
					
					[LMAnswers logCustomEventWithName:@"Viewed Contact Us Screen" customAttributes:nil];
					break;
				}
				case 2: {
					LMAlertView *alertView = [LMAlertView newAutoLayoutView];
					
					alertView.title = NSLocalizedString(@"UsageData", nil);
					alertView.body = NSLocalizedString(@"UsageDataDescription", nil);
					alertView.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
					alertView.alertOptionTitles = @[NSLocalizedString(@"OptionOptOut", nil), NSLocalizedString(@"OptionOptIn", nil)];
					
					[alertView launchOnView:self.coreViewController.navigationController.view withCompletionHandler:^(NSUInteger optionSelected) {
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
					}];
					
				self.indexPathOfCurrentlyOpenAlertView = indexPath;
				}
			}
			break;
	}
}

- (void)didChangeScrollingTextSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyScrollingText];
	[userDefaults synchronize];
}

- (id)accessoryViewForIndexPath:(NSIndexPath *)indexPath forSectionTableView:(LMSectionTableView *)sectionTableView {
//	if(indexPath.section == 0 || (indexPath.section == 1 && indexPath.row == 2)){
	if((indexPath.section == 0 && indexPath.row == 0)){
		UISwitch *switchView = [UISwitch newAutoLayoutView];
		
		NSString *settingsKey = @"";
		BOOL enabled = YES;
		
		switch(indexPath.section){
			case 0:
				if(indexPath.row == 0){
					[switchView addTarget:self action:@selector(didChangeScrollingTextSwitchView:) forControlEvents:UIControlEventValueChanged];
					
					settingsKey = LMSettingsKeyScrollingText;
				}
				break;
//			case 1:
//				[switchView addTarget:self action:@selector(didChangeHighestResolutionSwitchView:) forControlEvents:UIControlEventValueChanged];
//				
//				settingsKey = LMSettingsKeyHighQualityImages;
//				enabled = NO;
//				break;
				
		}
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		if([userDefaults objectForKey:settingsKey]){
			enabled = [userDefaults integerForKey:settingsKey];
		}
		
		switchView.on = enabled;
		
		return switchView;
	}
	
	UIImageView *imageView = [UIImageView newAutoLayoutView];
	imageView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
	return imageView;
}

- (BOOL)prefersStatusBarHidden {
	BOOL shouldShowStatusBar = [LMSettings shouldShowStatusBar];
		
	return !shouldShowStatusBar || [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

//- (void)loadView {
//	self.view = [UIView new];
//	self.view.backgroundColor = [UIColor whiteColor];
//}

- (void)themeChanged:(LMTheme)theme {
	[self.sectionTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.imageManager = [LMImageManager sharedImageManager];
	[self.imageManager addDelegate:self];
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
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
