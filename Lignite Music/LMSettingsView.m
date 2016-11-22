//
//  LMSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSettingsView.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"
#import "LMImageManager.h"
#import "LMAlertView.h"
#import "LMColour.h"

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
			return NSLocalizedString(@"About", nil);
	}
	return @"Unknown section";
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return 2;
		case 1:
			return 3;
		case 2:
			return 1;
	}
	return 0;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Colour", nil);
				case 1:
					return NSLocalizedString(@"StatusBar", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"ArtistImages", nil);
				case 1:
					return NSLocalizedString(@"AlbumCoverArts", nil);
				case 2:
					return NSLocalizedString(@"ImageCacheSize", nil);
			}
			break;
		case 2:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"Credits", nil);
			}
			break;
	}
	return @"Unknown entry";
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					return NSLocalizedString(@"TapToChooseColour", nil);
				case 1:
					return NSLocalizedString(@"StatusBarDescription", nil);
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					LMImageManagerPermissionStatus artistImagesStatus = [imageManager permissionStatusForCategory:LMImageManagerCategoryArtistImages];
					BOOL approved = (artistImagesStatus == LMImageManagerPermissionStatusAuthorized);
					return NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
				}
				case 1: {
					LMImageManagerPermissionStatus albumArtworkStatus = [imageManager permissionStatusForCategory:LMImageManagerCategoryAlbumImages];
					BOOL approved = (albumArtworkStatus == LMImageManagerPermissionStatusAuthorized);
					return NSLocalizedString(approved ? @"LMImageManagerPermissionStatusAuthorized" : @"LMImageManagerPermissionStatusDenied", nil);
				}
				case 2:
					return [NSString stringWithFormat:NSLocalizedString(@"ImageCacheClickToManage", nil), (float)[imageManager totalSpaceAllocated]/1000000];
			}
			break;
		case 2:
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

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	
	switch(indexPath.section){
		case 0:
			switch(indexPath.row){
				case 0:
					NSLog(@"Pick theme");
					break;
				case 1:
					NSLog(@"Status bar");
					break;
			}
			break;
		case 1:
			switch(indexPath.row){
				case 0: {
					LMAlertView *alertView = [LMAlertView newAutoLayoutView];
					alertView.title = NSLocalizedString(@"ArtistImages", nil);
					alertView.body = [NSString stringWithFormat:NSLocalizedString(@"SettingImagesAlertDescription", nil), NSLocalizedString(@"OfYourArtists", nil)];
					alertView.alertOptionTitles = @[NSLocalizedString(@"ClearCacheAndDisable", nil), NSLocalizedString(@"KeepEnabled", nil)];
					alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
					[alertView launchOnView:self withCompletionHandler:^(NSUInteger optionSelected) {
						NSLog(@"Selected %d", (int)optionSelected);
						if(optionSelected == 0){
							[imageManager clearCacheForCategory:LMImageManagerCategoryArtistImages];
						}
					}];
					
					NSLog(@"Artist alert");
					break;
				}
				case 1: {
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
				case 0:
					NSLog(@"Credits");
					break;
			}
			break;
	}
}

- (void)layoutSubviews {
	if(!self.hasPreparedSubviews){
		self.hasPreparedSubviews = YES;
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 3;
		self.sectionTableView.title = NSLocalizedString(@"AppSettings", nil);
		[self addSubview:self.sectionTableView];
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
	}
}

@end
