//
//  LMImagePickerView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

@class LMImagePickerView;

@protocol LMImagePickerViewDelegate
@required

/**
 The image picker has a new image picked, or the image that was already picked was edited.

 @param imagePickerView The image picker view that has the image that was changed.
 @param image The image.
 */
- (void)imagePickerView:(LMImagePickerView*)imagePickerView didFinishPickingImage:(UIImage*)image;

/**
 The image picker view deleted an image.

 @param imagePickerView The image picker view which deleted the image.
 @param image The image that was deleted.
 */
- (void)imagePickerView:(LMImagePickerView *)imagePickerView deletedImage:(UIImage*)image;

@end

@interface LMImagePickerView : LMView

/**
 The delegate for this image picker.
 */
@property id<LMImagePickerViewDelegate> delegate;

/**
 The image currently loaded in the image picker view.
 */
@property UIImage *image;

@end
