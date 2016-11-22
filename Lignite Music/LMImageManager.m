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
@import SDWebImage;

/**
 The estimated average size of an image from LastFM in bytes.

 @return The estimated average.
 */
#define AVERAGE_IMAGE_SIZE_IN_BYTES 215000

/**
 The image manager's disk cache namespaces for storing images.

 @return The name of a disk namespace.
 */
#define LMImageManagerCacheNamespaceArtist @"LMImageManagerCacheArtist"
#define LMImageManagerCacheNamespaceAlbum @"LMImageManagerCacheAlbum"

/**
 Our LastFM API key. God forbid this ever get cutoff.

 @return The API key.
 */
#define LMLastFMAPIKey @"8f53580e3745f1b99e3446ff5f82b7df"

/**
 The amount of items per page that LastFM should return in its API results.

 @return The number of items per page.
 */
#define LMLastFMItemsPerPageLimit 15

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

/**
 The artist image cache of the image manager.
 */
@property SDImageCache *artistImageCache;

/**
 The album art image cache of the image manager.
 */
@property SDImageCache *albumImageCache;

/**
 The operation queue.
 */
@property NSOperationQueue *operationQueue;

@end

@implementation LMImageManager

/**
 *
 * GENERAL CODE
 *
 */

- (instancetype)init {
	self = [super init];
	if(self){
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.albumsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums];
		self.artistsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists];
		
		self.albumImageCache = [[SDImageCache alloc] initWithNamespace:LMImageManagerCacheNamespaceAlbum];
		self.artistImageCache = [[SDImageCache alloc] initWithNamespace:LMImageManagerCacheNamespaceArtist];
		
		self.operationQueue = [NSOperationQueue new];
		
		LMMusicTrack *randomItem = [[self.artistsCollection objectAtIndex:5] representativeItem];
		[self imageNeedsDownloadingForMusicTrack:randomItem
											 forCategory:LMImageManagerCategoryArtistImages
											  completion:^(BOOL needsDownloading) {
												  NSLog(@"%@: Needs downloading: %d", [self imageCacheKeyForMusicTrack:randomItem
																													   forCategory:LMImageManagerCategoryArtistImages], needsDownloading);
												  
												  if(needsDownloading){
													  [self downloadImageForMusicTrack:randomItem forCategory:LMImageManagerCategoryArtistImages];
												  }
											  }];
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
 *
 * END GENERAL CODE AND BEGIN IMAGE DOWNLOADING CODE
 *
 */

- (SDImageCache*)imageCacheForCategory:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return self.albumImageCache;
		case LMImageManagerCategoryArtistImages:
			return self.artistImageCache;
	}
}

- (NSUInteger)sizeOfCacheForCategory:(LMImageManagerCategory)category {
	SDImageCache *imageCache = [self imageCacheForCategory:category];
	
	return [imageCache getSize];
}

- (NSUInteger)sizeOfAllCaches {
	return [self sizeOfCacheForCategory:LMImageManagerCategoryAlbumImages] + [self sizeOfCacheForCategory:LMImageManagerCategoryArtistImages];
}

- (void)clearCacheForCategory:(LMImageManagerCategory)category {
	SDImageCache *imageCache = [self imageCacheForCategory:category];
	[imageCache clearDisk];
	[imageCache cleanDisk];
}

- (NSString*)imageCacheKeyForMusicTrack:(LMMusicTrack*)representativeItem forCategory:(LMImageManagerCategory)category {
	LMMusicTrackPersistentID persistentID;
	NSString *categoryName = @"";
	
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			persistentID = representativeItem.albumPersistentID;
			categoryName = @"albumArtImages";
			break;
		case LMImageManagerCategoryArtistImages:
			persistentID = representativeItem.artistPersistentID;
			categoryName = @"artistImages";
			break;
	}
	
	NSString *namespaceKey = [NSString stringWithFormat:@"%@_id%lld", categoryName, persistentID];
	
	return namespaceKey;
}

- (void)imageNeedsDownloadingForMusicTrack:(LMMusicTrack*)representativeItem forCategory:(LMImageManagerCategory)category completion:(void(^)(BOOL needsDownloading))completionHandler {
	
	NSBlockOperation *albumArtOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSLog(@"Album art operation %@", albumArtOperation);
		if(albumArtOperation.isCancelled){
			return;
		}
		UIImage *image = nil;
		switch(category){
			case LMImageManagerCategoryAlbumImages:
				image = [representativeItem albumArt];
				break;
			case LMImageManagerCategoryArtistImages:
				image = [representativeItem artistImage];
				break;
		}
		completionHandler(image == nil);
	}];
	
	[self.operationQueue addOperation:albumArtOperation];
}

- (void)downloadImageForMusicTrack:(LMMusicTrack*)randomTrack forCategory:(LMImageManagerCategory)category {
	NSError *error;
	
	//Prepare the contents of the search
	NSString *typeOfSearch = @"";
	NSString *imageNameSearchString = @"";
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			typeOfSearch = @"album";
			imageNameSearchString = randomTrack.albumTitle;
			break;
		case LMImageManagerCategoryArtistImages:
			typeOfSearch = @"artist";
			imageNameSearchString = randomTrack.artist;
			break;
	}
	
	NSLog(@"Download search beginning an %@ image, with contents %@", typeOfSearch, imageNameSearchString);
	
	NSString *matchesString = [NSString stringWithFormat:@"%@matches", typeOfSearch];
	
	imageNameSearchString = [imageNameSearchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	//Prepare the API url
	NSString *urlString = [NSString stringWithFormat:@"https://ws.audioscrobbler.com/2.0/?method=%@.search&%@=%@&limit=%d&api_key=%@&format=json",
						   typeOfSearch, //For the method
						   typeOfSearch, //For the variable name
						   imageNameSearchString, //The actual search query
						   LMLastFMItemsPerPageLimit, //The limit of items per page
						   LMLastFMAPIKey]; //Our API key
	
	//Get the data from the API URL
	NSURL *jsonURL = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:jsonURL];
	NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

	//Get the items of search results that were returned
	NSArray *items = [[[jsonResponse objectForKey:@"results"] objectForKey:matchesString] objectForKey:typeOfSearch];
	
	//Loop through each one
	for(int i = 0; i < items.count; i++){
		NSDictionary *item = [items objectAtIndex:i];
		
		NSLog(@"%d Image name %@", i, [item objectForKey:@"name"]);
		//Get the item's images (each have a different size)
		NSArray *itemImages = [item objectForKey:@"image"];
		
		//Loop through each of those
		for(int itemImageIndex = 0; itemImageIndex < [itemImages count]; itemImageIndex++){
			//Get that image object
			NSDictionary *itemImage = [itemImages objectAtIndex:itemImageIndex];
			
			NSString *itemImageURL = [itemImage objectForKey:@"#text"];
			NSString *itemImageSize = [itemImage objectForKey:@"size"];
			NSString *sizeRequired = @"extralarge";
			
			//Check if it's the size we need
			if([itemImageSize isEqualToString:sizeRequired] && ![itemImageURL isEqualToString:@""]){
				NSLog(@"Extra large image @ %@", itemImageURL);
				
				NSString *imageCacheKey = [self imageCacheKeyForMusicTrack:randomTrack forCategory:category];
				
				NSLog(@"Cache key %@", imageCacheKey);

				//Good to download!
				
				SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
				[downloader downloadImageWithURL:[NSURL URLWithString:itemImageURL]
										 options:0
										progress:^(NSInteger receivedSize, NSInteger expectedSize) {
											NSLog(@"%.02f%% complete", (float)receivedSize/(float)expectedSize * 100);
										}
									   completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
										   if(image && finished) {
											   NSLog(@"Done, now storing to %@.", imageCacheKey);
											   
											   [[self imageCacheForCategory:category] storeImage:image forKey:imageCacheKey];
										   }
									   }];
				return;
			}
		}
	}
}

- (UIImage*)imageForMusicTrack:(LMMusicTrack*)musicTrack withCategory:(LMImageManagerCategory)category {
	return [[self imageCacheForCategory:category] imageFromDiskCacheForKey:[self imageCacheKeyForMusicTrack:musicTrack forCategory:category]];
}


/**
 *
 * END IMAGE DOWNLOADING CODE AND BEGIN PERMISSION AND CONDITION LEVEL RELATED CODE
 *
 */

- (LMImageManagerConditionLevel)conditionLevelForDownloadingForCategory:(LMImageManagerCategory)category {
	if(![self hasInternetConnection]){
		return LMImageManagerConditionLevelNever;
	}
	
	LMImageManagerPermissionStatus permissionStatusForCategory = [self permissionStatusForCategory:category];
	switch(permissionStatusForCategory){
		case LMImageManagerPermissionStatusDenied:
			return LMImageManagerConditionLevelNever;
			
		case LMImageManagerPermissionStatusNotDetermined:
		case LMImageManagerPermissionStatusAuthorized:
			break;
	}
	
	if([self storageSpaceLowForCategory:category] || [self isOnCellularData]){
		return LMImageManagerConditionLevelSuboptimal;
	}
	
	//Conditions are optimal and the user has not explicitly denied us from downloading the images, so set it to authorized
	[self setPermissionStatus:LMImageManagerPermissionStatusAuthorized forCategory:category];
	
	return LMImageManagerConditionLevelOptimal;
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
	
	return status != NotReachable;
}

- (NSString*)permissionRequestDescriptionStringForCategory:(LMImageManagerCategory)category {
	BOOL storageSpaceLow = [self storageSpaceLowForCategory:category];
	BOOL isOnCellularData = [self isOnCellularData];
	
	//Tells the user why the images won't automatically download
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

/**
 *
 * END PERMISSION AND CONDITION LEVEL RELATED CODE
 *
 */

@end
