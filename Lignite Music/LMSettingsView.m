//
//  LMSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "LMSettingsView.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"
#import "LMImageManager.h"
#import "LMAlertView.h"
#import "LMColour.h"
#import "LMSettings.h"
#import "LMPebbleManager.h"

@interface LMSettingsView()<LMSectionTableViewDelegate>

@property LMSectionTableView *sectionTableView;

@property BOOL hasPreparedSubviews;

@end

@implementation LMSettingsView

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return [LMAppIcon imageForIcon:LMIconLookAndFeel];
		case 1:
			return [LMAppIcon imageForIcon:LMIconCloudDownload];
		case 2:
			return [LMAppIcon imageForIcon:LMIconPebbles];
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
			return NSLocalizedString(@"Pebble", nil);
		case 3:
			return NSLocalizedString(@"About", nil);
	}
	return @"Unknown section";
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return 1;
		case 1:
			return 2;
		case 2:
			return 2;
		case 3:
			return 1;
	}
	return 0;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
//				case 0:
//					return NSLocalizedString(@"Colour", nil);
				case 0:
					return NSLocalizedString(@"StatusBar", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ArtistImagesTitle", nil);
				case 1:
					return NSLocalizedString(@"AlbumImagesTitle", nil);
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"InstallPebbleApp", nil);
				case 1:
					return NSLocalizedString(@"PebbleSettings", nil);
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Credits", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (NSString*)subtitleForCategory:(LMImageManagerCategory)category {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	LMImageManagerPermissionStatus artistImagesStatus = [imageManager permissionStatusForCategory:category];
	
	BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
	
	NSString *approvedString = NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
	
	NSString *takingUpString = [NSString stringWithFormat:NSLocalizedString(@"TakingUpXMB", nil), (float)[imageManager sizeOfCacheForCategory:category]/1000000];
	
	return [NSString stringWithString:[NSMutableString stringWithFormat:@"%@ - %@", takingUpString, approvedString]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
//				case 0:
//					return NSLocalizedString(@"TapToChooseColour", nil);
				case 0:
					return NSLocalizedString(@"StatusBarDescription", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					return [self subtitleForCategory:LMImageManagerCategoryArtistImages];
				}
				case 1: {
					return [self subtitleForCategory:LMImageManagerCategoryAlbumImages];
				}
				case 2:
					return [NSString stringWithFormat:NSLocalizedString(@"ImageCacheClickToManage", nil), (float)[imageManager sizeOfAllCaches]/1000000];
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0: {
					return nil;
				}
				case 1: {
					return nil;
				}
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"CreditsMore", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt];
}

- (void)cacheAlertForCategory:(LMImageManagerCategory)category {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	LMImageManagerPermissionStatus currentStatus = [imageManager permissionStatusForCategory:category];
	
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	NSString *titleKey = @"";
	NSString *bodyKey = @"";
	NSString *youCanKey = @"";
	NSString *enableButtonKey = @"";
	NSString *disableButtonKey = @"";
	NSString *currentStatusText = @"";
	switch(category) {
		case LMImageManagerCategoryAlbumImages:
			titleKey = @"AlbumImagesTitle";
			bodyKey = @"OfYourAlbums";
			break;
		case LMImageManagerCategoryArtistImages:
			titleKey = @"ArtistImagesTitle";
			bodyKey = @"OfYourArtists";
			break;
	}
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
			currentStatusText = [NSString stringWithFormat:NSLocalizedString(@"UsingXOfYourStorage", nil), (float)[imageManager sizeOfCacheForCategory:category]/1000000];
			break;
	}
	alertView.title = NSLocalizedString(titleKey, nil);
	
	alertView.body = [NSString stringWithFormat:NSLocalizedString(@"SettingImagesAlertDescription", nil), NSLocalizedString(bodyKey, nil), currentStatusText, NSLocalizedString(youCanKey, nil)];
	
	alertView.alertOptionTitles = @[NSLocalizedString(disableButtonKey, nil), NSLocalizedString(enableButtonKey, nil)];
	alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
	
	[alertView launchOnView:self withCompletionHandler:^(NSUInteger optionSelected) {
		NSLog(@"Selected %d", (int)optionSelected);
		
		if(optionSelected == 0){
			[imageManager clearCacheForCategory:category];
			
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
			
			hud.mode = MBProgressHUDModeCustomView;
			UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			hud.customView = [[UIImageView alloc] initWithImage:image];
			hud.square = YES;
			hud.label.text = NSLocalizedString(@"ImagesDeleted", nil);
			
			[hud hideAnimated:YES afterDelay:3.f];
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
		
		[imageManager setPermissionStatus:permissionStatus forCategory:category];
		
		[self.sectionTableView reloadData];
	}];
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
//				case 0:
//					NSLog(@"Pick theme");
//					break;
				case 0:
					NSLog(@"Status bar");
					break;
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					[self cacheAlertForCategory:LMImageManagerCategoryArtistImages];
					NSLog(@"Artist alert");
					break;
				}
				case 1: {
					[self cacheAlertForCategory:LMImageManagerCategoryAlbumImages];
					NSLog(@"Album alert");
					break;
				}
				case 2:
					NSLog(@"Image cache size alert");
					break;
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0: {
					NSURL *pebbleURL = [NSURL URLWithString:@"pebble://appstore/579c3ee922f599cf7e0001ea"];
					NSURL *pebbleWebURL = [NSURL URLWithString:@"http://apps.getpebble.com/en_US/application/579c3ee922f599cf7e0001ea"];
					BOOL canOpenPebbleURL = [[UIApplication sharedApplication] canOpenURL:pebbleURL];
					[[UIApplication sharedApplication] openURL:canOpenPebbleURL ? pebbleURL : pebbleWebURL];
					break;
				}
				case 1:{
					NSLog(@"Pebble settings");
					LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
					[pebbleManager showSettings];
					break;
				}
			}
			break;
		case 3:
			switch(indexPath.row){
				case 0:
					NSLog(@"Credits");
					break;
			}
			break;
	}
}

- (void)didChangeStatusBarSwitchView:(UISwitch*)switchView {	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:switchView.on forKey:LMSettingsKeyStatusBar];
	[userDefaults synchronize];
	
	[self.coreViewController setNeedsStatusBarAppearanceUpdate];
	[self.settingsViewController setNeedsStatusBarAppearanceUpdate];
}

- (id)accessoryViewForIndexPath:(NSIndexPath *)indexPath forSectionTableView:(LMSectionTableView *)sectionTableView {
	if(indexPath.section == 0){
		UISwitch *switchView = [UISwitch newAutoLayoutView];
		
		[switchView addTarget:self action:@selector(didChangeStatusBarSwitchView:) forControlEvents:UIControlEventValueChanged];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		BOOL enabled = YES;
		
		if([userDefaults objectForKey:LMSettingsKeyStatusBar]){
			enabled = [userDefaults integerForKey:LMSettingsKeyStatusBar];
		}
		
		switchView.on = enabled;
		
		return switchView;
	}
	UIImageView *imageView = [UIImageView newAutoLayoutView];
	imageView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
	return imageView;
}

- (void)layoutSubviews {
	if(!self.hasPreparedSubviews){
		self.hasPreparedSubviews = YES;
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 4;
		self.sectionTableView.title = NSLocalizedString(@"AppSettings", nil);
		[self addSubview:self.sectionTableView];
		
		NSLog(@"section %@", self.sectionTableView);

		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
	}
}

@end
