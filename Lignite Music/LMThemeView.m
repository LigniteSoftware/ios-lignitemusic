//
//  LMThemeView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/13/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMCollectionInfoView.h"
#import "LMThemeView.h"

@interface LMThemeView()<LMCollectionInfoViewDelegate, LMThemeEngineDelegate>

/**
 The image view for displaying the theme's preview screenshot.
 */
@property UIImageView *imageView;

/**
 The border for the image view.
 */
@property UIView *imageBorderView;

/**
 The background view of the image, so we can centre it between the top of the view and the top of the info view.
 */
@property UIView *imageViewBackgroundView;

/**
 The layout constraint for the image view.
 */
@property NSLayoutConstraint *imageViewLayoutConstraint;

/**
 The constraint for the image view's border width.
 */
@property NSLayoutConstraint *imageBorderWidthConstraint;

/**
 The constraint for the image view's border height.
 */
@property NSLayoutConstraint *imageBorderHeightConstraint;

/**
 The info view for the name and creator of the theme.
 */
@property LMCollectionInfoView *infoView;

///**
// The background view for the "selected" indicator.
// */
//@property UIView *selectedLabelBackgroundView;

@end

@implementation LMThemeView

@synthesize themeKey = _themeKey;

- (NSString*)themeKey {
	return [[LMThemeEngine sharedThemeEngine] keyForTheme:self.theme];
}

- (void)tapped {
	if(self.theme == [LMThemeEngine currentTheme]){
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
		[animation setDuration:0.05];
		[animation setRepeatCount:4];
		[animation setAutoreverses:YES];
		[animation setFromValue:[NSValue valueWithCGPoint:
								 CGPointMake([self.imageView center].x - 3.0f, [self.imageView center].y)]];
		[animation setToValue:[NSValue valueWithCGPoint:
							   CGPointMake([self.imageView center].x + 3.0f, [self.imageView center].y)]];
		[[self.imageView layer] addAnimation:animation forKey:@"position"];
	}
	else if([self.delegate respondsToSelector:@selector(themeView:selectedTheme:)]){
		[self.delegate themeView:self selectedTheme:self.theme];
	}
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	NSString *key = [NSString stringWithFormat:@"%@_Title", self.themeKey];
	return NSLocalizedString(key, nil);
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	NSString *key = [NSString stringWithFormat:@"%@_Creator", self.themeKey];
	return NSLocalizedString(key, nil);
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centreImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)themeChanged:(LMTheme)theme {
	[self layoutIfNeeded];
	
	[self.imageViewLayoutConstraint autoRemove];
	[self.imageBorderWidthConstraint autoRemove];
	[self.imageBorderHeightConstraint autoRemove];
	
	BOOL isSelected = (self.theme == theme);
	
	self.imageViewLayoutConstraint = [self.imageView autoMatchDimension:ALDimensionHeight
															toDimension:ALDimensionHeight
																 ofView:self.imageViewBackgroundView
														 withMultiplier:isSelected ? (8.5/10.0) : (7.0/10.0)];
	
	self.imageBorderHeightConstraint = [self.imageBorderView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imageView withMultiplier:isSelected ? (10.7/10.0) : (10.4/10.0)];
	
	self.imageBorderWidthConstraint = [self.imageBorderView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.imageView withMultiplier:isSelected ? (9.7/10.0) : ((9.3/10.0) * 0.8)];
	
	[UIView animateWithDuration:0.2 animations:^{
		[self layoutIfNeeded];
		[self.imageViewBackgroundView layoutIfNeeded];
	}];
}

- (UIImage*)roundedImage:(UIImage*)image {
	UIImage *roundedImage = image;
	
	CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
	
	UIGraphicsBeginImageContextWithOptions(frame.size, false, 1);
	
	[[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:36.0f] addClip];
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
		
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		
		BOOL isSelected = (self.theme == LMThemeEngine.currentTheme);
		
		
		self.infoView = [LMCollectionInfoView newAutoLayoutView];
		self.infoView.delegate = self;
		self.infoView.largeMode = NO;
		[self addSubview:self.infoView];
		
		[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.infoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(2.0/10.0)];
		
		
		self.imageViewBackgroundView = [UIView newAutoLayoutView];
		self.imageViewBackgroundView.backgroundColor = [LMColour clearColor];
		self.imageViewBackgroundView.clipsToBounds = NO;
		[self addSubview:self.imageViewBackgroundView];
		
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.imageViewBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.infoView];
		
		
		self.imageBorderView = [UIView newAutoLayoutView];
		self.imageBorderView.backgroundColor = [LMThemeEngine mainColourForTheme:self.theme];
		self.imageBorderView.clipsToBounds = NO;
		[self.imageViewBackgroundView addSubview:self.imageBorderView];
		
		
		self.imageView = [UIImageView newAutoLayoutView];
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.imageView.clipsToBounds = YES;
		[self.imageViewBackgroundView addSubview:self.imageView];
		
		UIImage *image = [self roundedImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", self.themeKey]]];
		[self.imageView setImage:image];
		
		CGFloat widthMultiplier = image.size.width / image.size.height;
		
		[self.imageView autoCenterInSuperview];
		[self.imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.imageViewBackgroundView withMultiplier:widthMultiplier];
		self.imageViewLayoutConstraint = [self.imageView autoMatchDimension:ALDimensionHeight
																toDimension:ALDimensionHeight
																	 ofView:self.imageViewBackgroundView
															 withMultiplier:isSelected ? (8.5/10.0) : (7.0/10.0)];

		[self.infoView reloadData];
		
		self.imageBorderView.layer.shadowRadius = isSelected ? 7 : 5;
		self.imageBorderView.layer.shadowOffset = CGSizeMake(0, self.imageBorderView.layer.shadowRadius/2);
		self.imageBorderView.layer.shadowOpacity = isSelected ? 0.5f : 0.15f;
		self.imageBorderView.layer.cornerRadius = 6.0f;
		
		[self.imageBorderView autoCenterInSuperview];
		
		self.imageBorderHeightConstraint = [self.imageBorderView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imageView withMultiplier:isSelected ? (10.7/10.0) : (10.4/10.0)];
		
		self.imageBorderWidthConstraint = [self.imageBorderView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.imageView withMultiplier:isSelected ? (9.7/10.0) : ((9.3/10.0) * 0.8)];
		
		
		self.userInteractionEnabled = YES;
		
		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped)];
		[self addGestureRecognizer:tapGestureRecognizer];
	}
}

- (void)removeFromSuperview {
	[super removeFromSuperview];
	
	[[LMThemeEngine sharedThemeEngine] removeDelegate:self];
}

@end
