//
//  LMAccessibilityButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/16/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAccessibilityButton.h"

@interface LMAccessibilityButton()

/**
 The view for displaying the icon.
 */
@property UIImageView *iconView;

@end

@implementation LMAccessibilityButton

@synthesize icon = _icon;

- (void)setIcon:(UIImage *)icon {
	_icon = icon;
	
	if(self.iconView){
		self.iconView.image = icon;
	}
}

- (UIImage*)icon {
	return _icon;
}

- (void)tapped {
	if(self.delegate){
		[self.delegate accessibilityButtonTapped:self];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		self.userInteractionEnabled = YES;
		
		self.backgroundColor = [UIColor blackColor];
		
		
		self.iconView = [UIImageView newAutoLayoutView];
		self.iconView.image = self.icon;
		self.iconView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:self.iconView];
		
		[self.iconView autoCentreInSuperview];
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(5.0/10.0)];
		
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped)];
		[self addGestureRecognizer:tapGesture];
	}
	
	self.layer.masksToBounds = YES;
	self.layer.cornerRadius = 8.0f;
}

@end
