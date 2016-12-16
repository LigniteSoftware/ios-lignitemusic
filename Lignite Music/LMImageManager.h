//
//  LMImageManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPMediaItem+LigniteImages.h"

@class LMImageManager;

/**
 LMImageManagerCategory is the category of images, such as artist images.
 */
typedef enum {
	LMImageManagerCategoryArtistImages = 0, //Images of artists
	LMImageManagerCategoryAlbumImages //Images of album art which are missing
} LMImageManagerCategory;

/**
 LMImageManagerPermissionStatus is the status for any image downloading permission that the user has control over.
 */
typedef enum {
	LMImageManagerPermissionStatusNotDetermined = 0, //The permission has not yet been determined by the user.
	LMImageManagerPermissionStatusDenied, //The user rejected our request to download images for the associated permission.
	LMImageManagerPermissionStatusAuthorized //The user has authorized our request to download images for the associated permission.
} LMImageManagerPermissionStatus;

/**
 LMImageManagerConditionLevel is the condition level of image downloading, from optimal to never download.
 */
typedef enum {
	LMImageManagerConditionLevelOptimal = 0, //Images are optimal for downloading and the app should begin the download process as soon as possible.
	LMImageManagerConditionLevelSuboptimal, //The conditions for downloading are suboptimal (ie. phone is low on storage) and the user should be prompted before continuing to download.
	LMImageManagerConditionLevelNever //There are conditions for downloading which either make it impossible (ie. no Internet connection) or the user has denied our request for downloading images. Images should never download under these conditions.
} LMImageManagerConditionLevel;

/**
 LMImageManagerSpecialDownloadPermission are special permissions which the user needs to explicitly grant for us to download images
 */
typedef enum {
	LMImageManagerSpecialDownloadPermissionLowStorage = 0,
	LMImageManagerSpecialDownloadPermissionCellularData
} LMImageManagerSpecialDownloadPermission;

@protocol LMImageManagerDelegate <NSObject>
@optional

/**
 The cache size of a certain category changed.

 @param newCacheSize The new cache size in bytes.
 @param category The category which had the change of cache size.
 */
- (void)cacheSizeChangedTo:(uint64_t)newCacheSize forCategory:(LMImageManagerCategory)category;

/**
 The image cache changed for a certain category.
 
 @param category The category which had the change of images.
 */
- (void)imageCacheChangedForCategory:(LMImageManagerCategory)category;

@end

@interface LMImageManager : NSObject



/**
 The system's shared image manager.

 @return The shared image manager.
 */
+ (LMImageManager*)sharedImageManager;

/**
 Adds a delegate to the image manager's list of delegates.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMImageManagerDelegate>)delegate;

/**
 Removes a delegate from the image manager's list of delegates.

 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMImageManagerDelegate>)delegate;


/**
 Call this when the option for high quality images changes so that the image manager can restart the whole process.
 */
- (void)highQualityImagesOptionDidChange;

/**
 Gets the total space allocated in a certain disk cache.

 @param category The category of the cache to check.
 @return The size of the cache in bytes.
 */
- (NSUInteger)sizeOfCacheForCategory:(LMImageManagerCategory)category;

/**
 Gets the total amount of space currently allocated in the disk caches.

 @return The total amount of space in bytes.
 */
- (NSUInteger)sizeOfAllCaches;

/**
 Clear the cache for a category of images.

 @param category The category to clear the cache of.
 */
- (void)clearCacheForCategory:(LMImageManagerCategory)category;



/**
 Get an image which has been downloaded for a certain category from the music track provided. nil if the image is not in storage.

 @param musicTrack The music track to use details for.
 @param category The category to search in.
 @return The image.
 */
- (UIImage*)imageForMusicTrack:(LMMusicTrack*)musicTrack withCategory:(LMImageManagerCategory)category;

/**
 Quick patch for media item code speed leak because I am running low on time. Does the same as above function but with a media item.

 @param mediaItem The media item to get the image for.
 @param category The category of image.
 @return The image.
 */
- (UIImage*)imageForMediaItem:(MPMediaItem*)mediaItem withCategory:(LMImageManagerCategory)category;

/**
 Begins the search and download process for a category of images.

 @param category The category of images to begin the process for.
 */
- (void)beginDownloadingImagesForCategory:(LMImageManagerCategory)category;

/**
 Checks whether or not the user has authorized downloading, handles the according authorization and will begin downloading images if necessary.

 @param category The category to begin downloading for.
 */
- (void)downloadIfNeededForCategory:(LMImageManagerCategory)category;

/**
 Gets the current condition level of downloading a category of images.

 @param category The category of images to check.
 @return The current download condition level.
 */
- (LMImageManagerConditionLevel)conditionLevelForDownloadingForCategory:(LMImageManagerCategory)category;

/**
 Gets the permission status for a certain category.

 @param category The category to check.
 @return The status of that permission.
 */
- (LMImageManagerPermissionStatus)permissionStatusForCategory:(LMImageManagerCategory)category;

/**
 Sets the permission status for the associated category.

 @param status The new status of the permission to set.
 @param category The permission to set the status to.
 */
- (void)setPermissionStatus:(LMImageManagerPermissionStatus)status forCategory:(LMImageManagerCategory)category;

/**
 Gets the permission status for a certain special download permission.
 
 @param specialDownloadPermission The special download permission to check.
 @return The permission status of that special download permission.
 */
- (LMImageManagerPermissionStatus)permissionStatusForSpecialDownloadPermission:(LMImageManagerSpecialDownloadPermission)specialDownloadPermission;

/**
 Sets the permission status for the associated special download permission.

 @param permissionStatus The new status of the permission to set.
 @param specialDownloadPermission The special download permission to set the status to.
 */
- (void)setPermissionStatus:(LMImageManagerPermissionStatus)permissionStatus forSpecialDownloadPermission:(LMImageManagerSpecialDownloadPermission)specialDownloadPermission;

/**
 Launch the permission request dialog on a UIView for a certain category. All saving of the permission status and dismissing of the created view is automatically handled.

 @param view The view to launch the permission request on.
 @param category The category of permission to launch the request for.
 @param completionHandler The completion handler for when the user makes their decision.
 */
- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler;



/**
 The view of which to place alerts on top of.
 */
@property UIView *viewToDisplayAlertsOn;

@end
