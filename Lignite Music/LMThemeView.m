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
 The background view of the image, so we can centre it between the top of the view and the top of the info view.
 */
@property UIView *imageViewBackgroundView;

/**
 The layout constraint for the image view.
 */
@property NSLayoutConstraint *imageViewLayoutConstraint;

/**
 The info view for the name and creator of the theme.
 */
@property LMCollectionInfoView *infoView;

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
	
	BOOL isSelected = (self.theme == theme);
	
	self.imageViewLayoutConstraint = [self.imageView autoMatchDimension:ALDimensionHeight
															toDimension:ALDimensionHeight
																 ofView:self.imageViewBackgroundView
														 withMultiplier:isSelected ? (10.0/10.0) : (9.0/10.0)];
	
	[UIView animateWithDuration:0.2 animations:^{
		self.imageView.layer.shadowOpacity = isSelected ? 0.4f : 0.25f;
		self.imageView.layer.shadowRadius = isSelected ? 7 : 5;
		
		[self layoutIfNeeded];
	}];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour clearColour];
		
		
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
		[self addSubview:self.imageViewBackgroundView];
		
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.imageViewBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.imageViewBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.infoView];
		
		
		self.imageView = [UIImageView newAutoLayoutView];
		self.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", self.themeKey]];
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.imageViewBackgroundView addSubview:self.imageView];
		
		self.imageView.layer.shadowRadius = isSelected ? 7 : 5;
		self.imageView.layer.shadowOffset = CGSizeMake(0, self.imageView.layer.shadowRadius/2);
		self.imageView.layer.shadowOpacity = isSelected ? 0.4f : 0.25f;
		
		[self.imageView autoCenterInSuperview];
		[self.imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.imageViewBackgroundView];
		self.imageViewLayoutConstraint = [self.imageView autoMatchDimension:ALDimensionHeight
																toDimension:ALDimensionHeight
																	 ofView:self.imageViewBackgroundView
															 withMultiplier:isSelected ? (10.0/10.0) : (9.0/10.0)];

		[self.infoView reloadData];
		
		
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
