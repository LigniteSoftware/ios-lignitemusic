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

@interface LMImagePickerView()<RSKImageCropViewControllerDelegate>

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

// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller {
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
}

// The original image has been cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect {
	
	self.imageView.image = croppedImage;
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
	NSLog(@"Pop no rotation");
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect rotationAngle:(CGFloat)rotationAngle {
	
	self.imageView.image = croppedImage;
	[self.viewController dismissViewControllerAnimated:YES completion:nil];
	
	NSLog(@"Pop rotation");
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller willCropImage:(UIImage *)originalImage {
	// Use when `applyMaskToCroppedImage` set to YES.
//	[SVProgressHUD show];
	NSLog(@"Progress");
}

- (void)tappedImageSelector {
	NSLog(@"Tapped the image selector %@", self.window.rootViewController);

	UIImage *image = [UIImage imageNamed:@"purchase_header.png"];
	RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:image cropMode:RSKImageCropModeSquare];
	imageCropVC.delegate = self;
	self.viewController = imageCropVC;
	[(LMCoreNavigationController*)self.window.rootViewController presentViewController:imageCropVC animated:YES completion:nil];
//
//	[self.window.rootViewController.navigationController push]
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
		
		CGFloat whiteFillPadding = 5.0f;
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
		addImageLabel.textColor = [LMColour controlBarGrayColour];
		addImageLabel.textAlignment = NSTextAlignmentCenter;
		addImageLabel.numberOfLines = 2;
		[descriptionContentView addSubview:addImageLabel];
		
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[addImageLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[addImageLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:plusIconImageView withOffset:6.0f];
		
		
		self.imageView = [UIImageView newAutoLayoutView];
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:self.imageView];
		
		[self.imageView autoPinEdgesToSuperviewEdges];
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
