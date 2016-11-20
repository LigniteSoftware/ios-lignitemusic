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
#import "LMMusicPlayer.h"

#define AVERAGE_IMAGE_SIZE_IN_BYTES 215000

@interface LMImageManager()

/**
 The system music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The collection of albums.
 */
@property NSArray<LMMusicTrackCollection*> *albumsCollection;

/**
 The collection of artists.
 */
@property NSArray<LMMusicTrackCollection*> *artistsCollection;

@end

@implementation LMImageManager

- (instancetype)init {
	self = [super init];
	if(self){
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.albumsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums];
		self.artistsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists];
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

- (LMImageManagerConditionLevel)conditionLevelForDownloadingForCategory:(LMImageManagerCategory)category {
	LMImageManagerConditionLevel conditionLevel = LMImageManagerConditionLevelOptimal;
	
	return conditionLevel;
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

- (NSUInteger)itemCountForCategory:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return self.albumsCollection.count;
		case LMImageManagerCategoryArtistImages:
			return self.artistsCollection.count;
	}
}

- (uint64_t)spaceRequiredForCategory:(LMImageManagerCategory)category {
	return [self itemCountForCategory:category]*AVERAGE_IMAGE_SIZE_IN_BYTES;
}

- (float)freeSpacePercentageUsedIfDownloadedCategory:(LMImageManagerCategory)category {
	uint64_t freeSpace = [LMImageManager diskBytesFree];
	uint64_t spaceRequired = [self spaceRequiredForCategory:category];
	
	return ((float)spaceRequired)/((float)freeSpace);
}

- (BOOL)storageSpaceLowForCategory:(LMImageManagerCategory)category {
	return [self freeSpacePercentageUsedIfDownloadedCategory:category] >= 0.50;
}

- (BOOL)isOnCellularData {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status == ReachableViaWWAN;
}

- (BOOL)hasInternetConnection {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	if (status != NotReachable){
		return YES;
	}
	
	return NO;
}

- (NSString*)permissionRequestDescriptionStringForCategory:(LMImageManagerCategory)category {
	BOOL storageSpaceLow = [self storageSpaceLowForCategory:category];
	BOOL isOnCellularData = YES;
	
	NSMutableString *problemsString = [NSMutableString stringWithString:@""];
	
	
	
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
	
	NSString *descriptionString = [NSString stringWithFormat:NSLocalizedString(@"ImagesDownloadWarningDescription", nil),
								   NSLocalizedString(ofYourTypeString, nil),
								   problemsString,
								   (float)[self spaceRequiredForCategory:category]/1000000.0,
								   storageSpaceLow ? [NSString stringWithFormat:NSLocalizedString(@"AboutXOfYourStorage", nil), ([self freeSpacePercentageUsedIfDownloadedCategory:category])*100.0] : @"",
								   NSLocalizedString(@"DownloadAnyway", nil),
								   NSLocalizedString(@"DontDownload", nil)];
	
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
