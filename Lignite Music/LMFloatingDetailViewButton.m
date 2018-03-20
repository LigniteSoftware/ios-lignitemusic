//
//  LMFloatingDetailViewButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/11/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMFloatingDetailViewButton.h"
#import "LMColour.h"

@interface LMFloatingDetailViewButton()

/**
 The view which displays this button's icon.
 */
@property UIImageView *iconView;

@end

@implementation LMFloatingDetailViewButton

+ (LMIcon)iconForType:(LMFloatingDetailViewControlButtonType)type {
	switch(type){
		case LMFloatingDetailViewControlButtonTypeClose:
			return LMIconXCross;
		case LMFloatingDetailViewControlButtonTypeShuffle:
			return LMIconShuffle;
		case LMFloatingDetailViewControlButtonTypeBack:
			return LMIconiOSBack;
	}
}

- (void)tapped {
	[self.delegate floatingDetailViewButtonTapped:self];
}

- (LMIcon)icon {
	return [LMFloatingDetailViewButton iconForType:self.type];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.alpha = ((self.type == LMFloatingDetailViewControlButtonTypeBack) ? 0.0 : (7.5/10.0));
		
		BOOL invertIcon = (self.icon != LMIconShuffle);
		
		self.layer.masksToBounds = YES;
		self.layer.cornerRadius = 8.0f;
		
		self.userInteractionEnabled = YES;
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped)];
		[self addGestureRecognizer:tapGesture];
		
		self.backgroundColor = [LMColour controlBarGreyColour];
		
		self.iconView = [UIImageView newAutoLayoutView];
		self.iconView.image = [LMAppIcon imageForIcon:self.icon inverted:invertIcon];
		self.iconView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:self.iconView];
		
		[self.iconView autoCentreInSuperview];
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(4.5/10.0)];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(8.0/10.0)];
	}
	
	[super layoutSubviews];
}

@end
