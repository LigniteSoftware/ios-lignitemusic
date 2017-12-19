//
//  LMSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "MBProgressHUD.h"
#import "LMPebbleSettingsView.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"
#import "LMImageManager.h"
#import "LMAlertView.h"
#import "LMColour.h"
#import "LMSettings.h"
#import "LMPebbleManager.h"
#import "LMSettingsSwitch.h"
#import "LMLayoutManager.h"

@interface LMPebbleSettingsView()<LMSectionTableViewDelegate, LMLayoutChangeDelegate>

@property LMSectionTableView *sectionTableView;

@property BOOL hasPreparedSubviews;

@property NSDictionary *settingsMapping;
@property NSDictionary *defaultsMapping;

@property LMLayoutManager *layoutManager;

@end

@implementation LMPebbleSettingsView

- (void)tappedCloseButtonForSectionTableView:(LMSectionTableView *)sectionTableView {
	[(UINavigationController*)self.window.rootViewController popViewControllerAnimated:YES];
}

- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return [LMAppIcon imageForIcon:LMIconPebbles];
		case 1:
			return [LMAppIcon imageForIcon:LMIconLookAndFeel];
		case 2:
			return [LMAppIcon imageForIcon:LMIconFunctionality];
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return NSLocalizedString(@"Pebble", nil);
		case 1:
			return NSLocalizedString(@"LookAndFeel", nil);
		case 2:
			return NSLocalizedString(@"Functionality", nil);
	}
	return @"Unknown section";
}

- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return [LMPebbleManager pebbleServiceHasBeenEnabledByUser] ? 2 : 1;
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
				case 0:
					return NSLocalizedString(@"EnablePebbleTitle", nil);
				case 1:
					return NSLocalizedString(@"InstallPebbleApp", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ArtistLabel", nil);
				case 1:
					return NSLocalizedString(@"DisplayTime", nil);
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"BatterySaver", nil);
				case 1:
					return NSLocalizedString(@"PebbleStyleControls", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (NSString*)subtitleForCategory:(LMImageManagerCategory)category {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	LMImageManagerPermissionStatus artistImagesStatus = [imageManager downloadPermissionStatus];
	
	BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
	
	NSString *approvedString = NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
	
	NSString *takingUpString = [NSString stringWithFormat:NSLocalizedString(@"TakingUpXMB", nil), (float)[imageManager sizeOfCacheForCategory:category]/1000000];
	
	return [NSString stringWithString:[NSMutableString stringWithFormat:@"%@ - %@", takingUpString, approvedString]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {	
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					return nil;
				case 1:
					return nil;
			}
		case 1:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ArtistLabelDescription", nil);
				case 1:
					return NSLocalizedString(@"DisplayTimeDescription", nil);
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"BatterySaverDescription", nil);
				case 1:
					return NSLocalizedString(@"PebbleStyleControlsDescription", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return nil;
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					NSLog(@"setup");
					break;
				case 1:
					NSLog(@"install");
					NSURL *pebbleURL = [NSURL URLWithString:@"pebble://appstore/579c3ee922f599cf7e0001ea"];
					NSURL *pebbleWebURL = [NSURL URLWithString:@"http://apps.getpebble.com/en_US/application/579c3ee922f599cf7e0001ea"];
					BOOL canOpenPebbleURL = [[UIApplication sharedApplication] canOpenURL:pebbleURL];
					[[UIApplication sharedApplication] openURL:canOpenPebbleURL ? pebbleURL : pebbleWebURL];
					break;
			}
			break;
		case 1:
			NSLog(@"Do nothing 1");
			break;
		case 2:
			NSLog(@"Do nothing 2");
			break;
	}
}

- (void)changeSwitch:(id)theSwitch {
	LMSettingsSwitch *changedSwitch = (LMSettingsSwitch*)theSwitch;
	
	if([changedSwitch.switchID isEqualToString:LMPebbleManagerKeyUserEnabled]){
		if(changedSwitch.on){
			LMAlertView *alertView = [LMAlertView newAutoLayoutView];
			
			alertView.title = NSLocalizedString(@"EnablePebbleTitle", nil);
			alertView.body = NSLocalizedString(@"EnablePebbleDescription", nil);
			alertView.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
			alertView.alertOptionTitles = @[NSLocalizedString(@"PebbleDisable", nil), NSLocalizedString(@"PebbleEnable", nil)];
			
			[alertView launchOnView:self.coreViewController.navigationController.view
			  withCompletionHandler:^(NSUInteger optionSelected) {
				  BOOL enabledPebble = (optionSelected == 1);
				  
				  changedSwitch.on = enabledPebble;
				
				  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

				  [userDefaults setBool:enabledPebble forKey:LMPebbleManagerKeyUserEnabled];
				  
				  self.sectionTableView.totalNumberOfSections = enabledPebble ? 3 : 1;
				
				  [self.sectionTableView reloadData];
				  
				  [[LMPebbleManager sharedPebbleManager] runPebbleServiceIfEnabled];
			}];
		}
		else{
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			[userDefaults setBool:NO forKey:LMPebbleManagerKeyUserEnabled];
			
			self.sectionTableView.totalNumberOfSections = 1;
			
			[self.sectionTableView reloadData];
		}
	}
	else{
		self.messageQueue = [[LMPebbleManager sharedPebbleManager] messageQueue];
		
		if(self.messageQueue){
			NSNumber *key = [self.settingsMapping objectForKey:changedSwitch.switchID];
			[self.messageQueue enqueue:@{key:[NSNumber numberWithBool:changedSwitch.on]}];
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setBool:changedSwitch.on forKey:changedSwitch.switchID];
			[defaults synchronize];
		}
	}
}

- (id)accessoryViewForIndexPath:(NSIndexPath *)indexPath forSectionTableView:(LMSectionTableView *)sectionTableView {
	LMSettingsSwitch *switchView = [LMSettingsSwitch newAutoLayoutView];

	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					switchView.switchID = LMPebbleManagerKeyUserEnabled;
					break;
				case 1:
					switchView = nil;
					break;
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0:
					switchView.switchID = @"pebble_artist_label";
					break;
				case 1:
					switchView.switchID = @"pebble_show_time";
					break;
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					switchView.switchID = @"pebble_battery_saver";
					break;
				case 1:
					switchView.switchID = @"pebble_style_controls";
					break;
			}
			break;
	}
	
	if(switchView){
		[switchView addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

		if([defaults objectForKey:switchView.switchID]){
			switchView.on = [defaults boolForKey:switchView.switchID];
		}
		else{
			switchView.on = [[self.defaultsMapping objectForKey:switchView.switchID] isEqualToValue:@(1)];
		}
		
		return switchView;
	}
	else{
		UIImageView *imageView = [UIImageView newAutoLayoutView];
		imageView.image = [LMAppIcon imageForIcon:LMIconForwardArrow];
		return imageView;
	}
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	[NSTimer scheduledTimerWithTimeInterval:0.50 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.layoutManager adjustRootViewSubviewsForLandscapeNavigationBar:self withAdditionalOffset:-64.0f];
	}];
}

- (void)layoutSubviews {
	if(!self.hasPreparedSubviews){
		self.hasPreparedSubviews = YES;
		
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = [LMPebbleManager pebbleServiceHasBeenEnabledByUser] ? 3 : 1;
		self.sectionTableView.title = NSLocalizedString(@"PebbleSettings", nil);
		[self addSubview:self.sectionTableView];
		
		NSLog(@"section %@", self.sectionTableView);
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
		
		if([LMLayoutManager isiPhoneX]){
			[self notchPositionChanged:LMLayoutManager.notchPosition];
		}
	}
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.settingsMapping = [[NSDictionary alloc]initWithObjectsAndKeys:@(100), @"pebble_battery_saver", @(101), @"pebble_artist_label", @(102), @"pebble_style_controls", @(103), @"pebble_show_time", nil];
		self.defaultsMapping = [[NSDictionary alloc]initWithObjectsAndKeys:@(0), @"pebble_battery_saver", @(1), @"pebble_artist_label", @(1), @"pebble_style_controls", @(0), @"pebble_show_time", nil];
		
		self.messageQueue = [[LMPebbleManager sharedPebbleManager] messageQueue];
	}
	return self;
}

@end
