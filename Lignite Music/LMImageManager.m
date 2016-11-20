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
#import "LMReachability.h"

#define AVERAGE_IMAGE_SIZE_IN_BYTES 200000

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

// http://stackoverflow.com/questions/5712527/how-to-detect-total-available-free-disk-space-on-the-iphone-ipad-device
+ (uint64_t)diskBytesFree {
	uint64_t totalSpace = 0;
	uint64_t totalFreeSpace = 0;
	NSError *error = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
	if (dictionary) {
		NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
		NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
		totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
		totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
	}
	else {
		NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
	}
	
	return totalFreeSpace;
}

- (NSString*)permissionRequestDescriptionStringForCategory:(LMImageManagerCategory)category {
	BOOL storageSpaceLow = YES;
	BOOL isOnCellularData = NO;
	
	NSMutableString *problemsString = [NSMutableString stringWithString:@""];
	
	uint64_t freeSpace = [LMImageManager diskBytesFree];
	uint64_t spaceRequired = 107*AVERAGE_IMAGE_SIZE_IN_BYTES;
	
	float freeSpacePercentageUsedIfDownloaded = (float)spaceRequired/(float)freeSpace;
	
	if(freeSpacePercentageUsedIfDownloaded >= 0.50){ //If the space required to download all of the images is at least half the free space
		storageSpaceLow = YES;
	}
	
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	if (status == ReachableViaWWAN){
		isOnCellularData = YES;
	}
	
	if(storageSpaceLow){
		problemsString = [NSMutableString stringWithString:NSLocalizedString(@"YouAreLowOnStorage", nil)];
	}
	if(isOnCellularData){
		if(storageSpaceLow){
			[problemsString appendString:NSLocalizedString(@"SpaceAndSpace", nil)];
		}
		[problemsString appendString:NSLocalizedString(@"YouAreOnData", nil)];
	}
	
	//The string which describes which types of images are being downloaded
	NSString *ofYourTypeString = @"";
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			ofYourTypeString = @"OfYourAlbums";
			break;
		case LMImageManagerCategoryArtistImages:
			ofYourTypeString = @"OfYourArtists";
			break;
	}
	
	NSString *descriptionString = [NSString stringWithFormat:NSLocalizedString(@"ImagesDownloadWarningDescription", nil), ofYourTypeString,  problemsString, 21, 7, NSLocalizedString(@"DownloadAnyway", nil), NSLocalizedString(@"DontDownload", nil)];
	
	return descriptionString;
}

- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler {
	
	NSString *titleString = @"";
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			titleString = @"AlbumImagesTitle";
			break;
		case LMImageManagerCategoryArtistImages:
			titleString = @"ArtistImagesTitle";
			break;
	}
	
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	
	alertView.title = NSLocalizedString(titleString, nil);
	alertView.body = [self permissionRequestDescriptionStringForCategory:category];
	alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
	alertView.alertOptionTitles = @[NSLocalizedString(@"DontDownload", nil), NSLocalizedString(@"DownloadAnyway", nil)];
	
	[alertView launchOnView:view withCompletionHandler:^(NSUInteger optionSelected) {
		completionHandler((LMImageManagerPermissionStatus)optionSelected);
	}];
}

@end
