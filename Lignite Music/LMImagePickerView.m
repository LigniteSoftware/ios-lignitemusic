//
//  LMImagePickerView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <RSKImageCropper/RSKImageCropper.h>
#import "LMImagePickerView.h"
#import "LMCoreNavigationController.h"
#import "LMColour.h"
#import "LMAppIcon.h"

@interface LMImagePickerView()<RSKImageCropViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

/**
 The background view to the image, which simply has the gray outline if no image is present and contains the contents of the box within itself.
 */
@property UIView *imageBackgroundView;

/**
 The actual image view which the image is placed on.
 */
@property UIImageView *imageView;

@property RSKImageCropViewController *viewController;

@end

@implementation LMImagePickerView

/* Begin crop-related functions */

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller {
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect {
	
	[self setNewImage:croppedImage];
	
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect rotationAngle:(CGFloat)rotationAngle {
	
	[self setNewImage:croppedImage];
	
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller willCropImage:(UIImage *)originalImage {
	NSLog(@"Progress");
}

/* End crop-related functions */

/* Begin image picker functions */

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
	[self setNewImage:[info objectForKey:@"UIImagePickerControllerEditedImage"]];
	
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id <UIImagePickerControllerDelegate,  UINavigationControllerDelegate>)delegate withSourceType:(UIImagePickerControllerSourceType)sourceType {
	
	if (([UIImagePickerController isSourceTypeAvailable:
		  UIImagePickerControllerSourceTypePhotoLibrary] == NO)
		|| (delegate == nil)
		|| (controller == nil))
		return NO;
	
	UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
	mediaUI.sourceType = sourceType;
	
	// Displays saved pictures and movies, if both are available, from the
	// Camera Roll album.
	mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum];
	
	// Hides the controls for moving & scaling pictures, or for
	// trimming movies. To instead show the controls, use YES.
	mediaUI.allowsEditing = YES;
	
	mediaUI.delegate = delegate;
	
	[controller presentViewController:mediaUI animated:YES completion:nil];
	return YES;
}

/* End image picker functions */

/* Begin other image-picker related functions */

- (void)setNewImage:(UIImage *)image {
	UIImage *previousImage = self.image;
	
	self.image = image;
	self.imageView.image = image;
	
	if(self.delegate){
		if(image == nil){
			[self.delegate imagePickerView:self deletedImage:previousImage];
		}
		else{
			[self.delegate imagePickerView:self didFinishPickingImage:self.image];
		}
	}
}

- (void)tappedImageSelector {
	NSLog(@"Tapped the image selector %@", self.window.rootViewController);

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SetupPlaylistPhoto", nil)
																   message:nil
															preferredStyle:UIAlertControllerStyleActionSheet];
	
	UIAlertAction* choosePhotoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ChoosePhoto", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		  NSLog(@"Choose photo");
		
		  [self startMediaBrowserFromViewController:self.window.rootViewController usingDelegate:self withSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
	  }];
	
	UIAlertAction* takePhotoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"TakePhoto", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		  NSLog(@"Take photo");
		
		[self startMediaBrowserFromViewController:self.window.rootViewController usingDelegate:self withSourceType:UIImagePickerControllerSourceTypeCamera];
	  }];
	
	UIAlertAction* editPhotoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"EditPhoto", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		NSLog(@"Edit photo");
		
		RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:self.image cropMode:RSKImageCropModeSquare];
		imageCropVC.delegate = self;
		self.viewController = imageCropVC;
		[(LMCoreNavigationController*)self.window.rootViewController presentViewController:imageCropVC animated:YES completion:nil];
	}];
	
	UIAlertAction* deletePhotoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DeletePhoto", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
		NSLog(@"Delete photo");
		
		UIImage *image = self.image;
		
		self.imageView.image = nil;
		self.image = nil;
		
		if(self.delegate){
			[self.delegate imagePickerView:self deletedImage:image];
		}
	}];
	
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
	
	[alert addAction:choosePhotoAction];
	[alert addAction:takePhotoAction];
	
	if(self.image){
		[alert addAction:editPhotoAction];
		[alert addAction:deletePhotoAction];
	}
	
	[alert addAction:cancelAction];
	
	[self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.userInteractionEnabled = YES;
		
		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedImageSelector)];
		[self addGestureRecognizer:tapGestureRecognizer];
		
		self.imageBackgroundView = [UIView newAutoLayoutView];
		self.imageBackgroundView.backgroundColor = [LMColour controlBarGrayColour];
		[self addSubview:self.imageBackgroundView];
		
		[self.imageBackgroundView autoPinEdgesToSuperviewEdges];
		
		UIView *whiteFillView = [UIView newAutoLayoutView];
		whiteFillView.backgroundColor = [UIColor whiteColor];
		[self.imageBackgroundView addSubview:whiteFillView];
		
		CGFloat whiteFillPadding = 4.0f;
		[whiteFillView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:whiteFillPadding];
		[whiteFillView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:whiteFillPadding];
		[whiteFillView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:whiteFillPadding];
		[whiteFillView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:whiteFillPadding];
		
		UIView *descriptionContentView = [UIView newAutoLayoutView];
		[whiteFillView addSubview:descriptionContentView];
		
		[descriptionContentView autoCenterInSuperview];
		[descriptionContentView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[descriptionContentView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		UIImageView *plusIconImageView = [UIImageView newAutoLayoutView];
		plusIconImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
		plusIconImageView.contentMode = UIViewContentModeScaleAspectFit;
		[descriptionContentView addSubview:plusIconImageView];
		
		[plusIconImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[plusIconImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[plusIconImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[plusIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:whiteFillView withMultiplier:(1.0/8.0)];
		
		UILabel *addImageLabel = [UILabel newAutoLayoutView];
		addImageLabel.text = NSLocalizedString(@"TapToAddAnImage", nil);
		addImageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f];
		addImageLabel.textColor = self.imageBackgroundView.backgroundColor;
		addImageLabel.textAlignment = NSTextAlignmentCenter;
		addImageLabel.numberOfLines = 2;
		[descriptionContentView addSubview:addImageLabel];
		
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[addImageLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:plusIconImageView withOffset:6.0f];
		
		
		self.imageView = [UIImageView newAutoLayoutView];
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.imageView.image = self.image;
		[self addSubview:self.imageView];
		
		[self.imageView autoPinEdgesToSuperviewEdges];
	}
}

/* End other image-picker related functions */

@end
