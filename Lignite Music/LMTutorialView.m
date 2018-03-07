//
//  LMTutorialView.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/20/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMTutorialView.h"
#import "LMColour.h"

@interface LMTutorialView()

/**
 The image view for displaying the theme's preview screenshot.
 */
@property UIImageView *imageView;

/**
 The shadow view for the image.
 */
@property UIView *imageShadowView;

/**
 The background view of the image, so we can centre it between the top of the view and the top of the info view.
 */
@property UIView *imageViewBackgroundView;

/**
 The light grey cover for shading out the background image for the play button.
 */
@property UIView *lightGreyImageCoverView;

/**
 The image view for the play icon.
 */
@property UIImageView *playImageView;

/**
 The label for the title of this video.
 */
@property UILabel *titleLabel;

@end

@implementation LMTutorialView

- (NSString*)youTubeVideoURLString {
	NSString *language = NSLocalizedString(@"LMLocalizationKey", nil);
	
	if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyQueueManagement]){
		if([language isEqualToString:@"de"]){
			return @"ma-KHcOQ-fE";
		}
		else{
			return @"SAdiG2s9x1o";
		}
	}
	else if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyNormalPlaylists]){
		if([language isEqualToString:@"de"]){
			return @"FMd6IoqPFAM";
		}
		else{
			return @"mYRoc8JNggo";
		}
	}
	else if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyFavourites]){
		if([language isEqualToString:@"de"]){
			return @"_vxctxHw27w";
		}
		else{
			return @"guDr39D-VDY";
		}
	}
	return @"ySs3aCj2u2g";
}

- (UIImage*)coverImage {
	NSString *imageKey = @"lignite_background_portrait";
	if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyQueueManagement]){
		imageKey = @"queue_preview";
	}
	else if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyNormalPlaylists]){
		imageKey = @"playlist_preview";
	}
	else if([self.tutorialKey isEqualToString:LMTutorialViewTutorialKeyFavourites]){
		imageKey = @"favourites_preview";
	}
	return [UIImage imageNamed:imageKey];
}

- (void)tapped {	
	if([self.delegate respondsToSelector:@selector(tutorialViewSelected:withYouTubeVideoURLString:)]){
		[self.delegate tutorialViewSelected:self withYouTubeVideoURLString:self.youTubeVideoURLString];
	}
}

- (UIImage*)roundedImage:(UIImage*)image {
	UIImage *roundedImage = image;
	
	CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
	
	UIGraphicsBeginImageContextWithOptions(frame.size, false, 1);
	
	[[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:8.0f] addClip];
	[image drawInRect:frame];
	
	roundedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return roundedImage;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour clearColour];
		self.clipsToBounds = NO;
		
		
		NSString *titleKey = [NSString stringWithFormat:@"%@_Title", self.tutorialKey];
		
		self.titleLabel = [UILabel newAutoLayoutView];
		self.titleLabel.text = NSLocalizedString(titleKey, nil);
		self.titleLabel.textColor = [UIColor blackColor];
//		self.titleLabel.backgroundColor = [UIColor orangeColor];
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:LMLayoutManager.isiPad ? 20.0f : 16.0f];
		self.titleLabel.textAlignment = NSTextAlignmentCenter;
		self.titleLabel.numberOfLines = 0;
		[self addSubview:self.titleLabel];
		
		[self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.5/10.0)];
		
		
		
		self.imageViewBackgroundView = [UIView newAutoLayoutView];
		self.imageViewBackgroundView.backgroundColor = [LMColour clearColor];
		self.imageViewBackgroundView.clipsToBounds = NO;
		[self addSubview:self.imageViewBackgroundView];
		
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.imageViewBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel];
		
		
		
		self.imageView = [UIImageView newAutoLayoutView];
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.imageView.clipsToBounds = YES;
		self.imageView.layer.masksToBounds = YES;
		self.imageView.layer.cornerRadius = 8.0f;
		self.imageView.image = [self coverImage];
		
		[self.imageViewBackgroundView addSubview:self.imageView];
		
		CGFloat widthMultiplier = self.coverImage.size.width / self.coverImage.size.height;
		
		[self.imageView autoCentreInSuperview];
		[self.imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.imageViewBackgroundView withMultiplier:widthMultiplier];
		[self.imageView autoMatchDimension:ALDimensionHeight
							   toDimension:ALDimensionHeight
									ofView:self.imageViewBackgroundView
							withMultiplier:(10.0/10.0)];
		
		
		
		self.imageShadowView = [UIView newAutoLayoutView];
		self.imageShadowView.backgroundColor = [UIColor whiteColor];
		[self.imageViewBackgroundView addSubview:self.imageShadowView];
		
		[self.imageShadowView autoCentreInSuperview];
		[self.imageShadowView autoMatchDimension:ALDimensionWidth
									 toDimension:ALDimensionWidth
										  ofView:self.imageView
								  withMultiplier:(9.5/10.0)];
		[self.imageShadowView autoMatchDimension:ALDimensionHeight
									 toDimension:ALDimensionHeight
										  ofView:self.imageView
								  withMultiplier:(9.5/10.0)];
		
		
		
		self.lightGreyImageCoverView = [UIView newAutoLayoutView];
		self.lightGreyImageCoverView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(4.0/10.0)];
		self.lightGreyImageCoverView.layer.masksToBounds = YES;
		self.lightGreyImageCoverView.layer.cornerRadius = 8.0;
		[self.imageView addSubview:self.lightGreyImageCoverView];
		
		[self.lightGreyImageCoverView autoPinEdgesToSuperviewEdges];
		
		
		self.playImageView = [UIImageView newAutoLayoutView];
		self.playImageView.image = [UIImage imageNamed:@"icon_play"];
		self.playImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.lightGreyImageCoverView addSubview:self.playImageView];
		
		[self.playImageView autoCentreInSuperview];
		[self.playImageView autoSetDimension:ALDimensionHeight toSize:30.0f];
		[self.playImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.playImageView];
		
		
		
		[self.imageViewBackgroundView insertSubview:self.imageView aboveSubview:self.imageShadowView];
		
		
		
		self.userInteractionEnabled = YES;
		
		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped)];
		[self addGestureRecognizer:tapGestureRecognizer];
	}
	
	self.imageShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.imageShadowView.layer.shadowRadius = self.frame.size.width/15;
	self.imageShadowView.layer.shadowOffset = CGSizeMake(0, self.imageShadowView.layer.shadowRadius/2);
	self.imageShadowView.layer.shadowOpacity = 0.50f;
}

- (void)removeFromSuperview {
	[super removeFromSuperview];	
}

@end

