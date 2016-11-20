//
//  LMImageManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PureLayout/PureLayout.h>
#import "LMImageManager.h"
#import "LMColour.h"
#import "LMAlertView.h"

@interface LMImageManager()

@end

@implementation LMImageManager

- (instancetype)init {
	self = [super init];
	if(self){
		NSLog(@"Initititit");
	}
	return self;
}

+ (LMImageManager*)sharedImageManager {
	static LMImageManager *sharedImageManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedImageManager = [self new];
	});
	return sharedImageManager;
}

/**
 Gets the key associated for an image permission. Should be used for NSUserDefaults and SDWebImage disk cache namespace.

 @param category The permission to get the key for.
 @return The category's key.
 */
+ (NSString*)keyForPermission:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return @"LMImageManagerPermissionAlbumImages";
		case LMImageManagerCategoryArtistImages:
			return @"LMImageManagerPermissionAlbumImages";
	}
}

- (LMImageManagerPermissionStatus)permissionStatusForCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *categoryKey = [LMImageManager keyForPermission:category];
	
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	if([userDefaults objectForKey:categoryKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:categoryKey];
	}
	
	return permissionStatus;
}

- (void)setPermissionStatus:(LMImageManagerPermissionStatus)status forCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *permissionStatusKey = [LMImageManager keyForPermission:category];
	
	[userDefaults setInteger:(NSInteger)category forKey:permissionStatusKey];
	[userDefaults synchronize];
}

- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler {
	
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	alertView.title = NSLocalizedString(@"AlbumImagesTitle", nil);
	alertView.body = [NSString stringWithFormat:NSLocalizedString(@"ImagesDownloadWarningDescription", nil), NSLocalizedString(@"OfYourAlbums", nil),  NSLocalizedString(@"YouAreLowOnStorage", nil), 21, 7, NSLocalizedString(@"DownloadAnyway", nil), NSLocalizedString(@"DontDownload", nil)];;
	alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
	alertView.alertOptionTitles = @[NSLocalizedString(@"DontDownload", nil), NSLocalizedString(@"DownloadAnyway", nil)];
	[alertView launchOnView:view withCompletionHandler:^(NSUInteger optionSelected) {
		completionHandler((LMImageManagerPermissionStatus)optionSelected);
	}];
}

@end
