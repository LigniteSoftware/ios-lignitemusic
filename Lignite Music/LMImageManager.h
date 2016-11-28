//
//  LMImageManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMMusicTrack;
@class LMImageManager;

@protocol LMImageManagerDelegate <NSObject>



@end

@interface LMImageManager : NSObject

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
 The system's shared image manager.

 @return The shared image manager.
 */
+ (LMImageManager*)sharedImageManager;

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
 Begins the search and download process for a category of images.

 @param category The category of images to begin the process for.
 */
- (void)beginDownloadingImagesForCategory:(LMImageManagerCategory)category;

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
 Launch the permission request dialog on a UIView for a certain category. All saving of the permission status and dismissing of the created view is automatically handled.

 @param view The view to launch the permission request on.
 @param category The category of permission to launch the request for.
 @param completionHandler The completion handler for when the user makes their decision.
 */
- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler;

@end
