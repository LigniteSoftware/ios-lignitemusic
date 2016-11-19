//
//  LMImageManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMImageManager;

@protocol LMImageManagerDelegate <NSObject>



@end

@interface LMImageManager : NSObject

/**
 LMImageManagerCategory is the category of images, such as artist images.
 */
typedef enum {
	LMImageManagerCategoryArtistImages = 0,
	LMImageManagerCategoryAlbumImages
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
 The system's shared image manager.

 @return The shared image manager.
 */
+ (LMImageManager*)sharedImageManager;

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
