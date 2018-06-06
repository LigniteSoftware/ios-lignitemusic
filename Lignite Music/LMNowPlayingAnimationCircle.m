//
//  LMNowPlayingAnimationCircle.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-05.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <CircleProgressBar/CircleProgressBar-umbrella.h>

#import "LMNowPlayingAnimationCircle.h"
#import "LMThemeEngine.h"
#import "LMAppIcon.h"
#import "LMColour.h"

@interface LMNowPlayingAnimationCircle()

/**
 The icon.
 */
@property UIImageView *iconView;

/**
 The circle progress bar for showing the loading animation.
 */
@property CircleProgressBar *circleProgressBar;

@end

@implementation LMNowPlayingAnimationCircle

@synthesize direction = _direction;
@synthesize progress = _progress;

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour blackColour];
		
		
		self.circleProgressBar = [CircleProgressBar newAutoLayoutView];
		[self addSubview:self.circleProgressBar];
		
		[self.circleProgressBar autoCentreInSuperview];
		[self.circleProgressBar autoSetDimension:ALDimensionHeight toSize:70.0f];
		[self.circleProgressBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.circleProgressBar];
		
		[self.circleProgressBar setProgress:0.5 animated:YES];
		
		BOOL clockwise = (self.direction == LMNowPlayingAnimationCircleDirectionClockwise);
		
		self.circleProgressBar.backgroundColor = [UIColor clearColor];
		self.circleProgressBar.hintHidden = YES;
		self.circleProgressBar.progressBarWidth = 5.0f;
		self.circleProgressBar.progressBarTrackColor = clockwise ? [LMColour clearColour] : [LMColour mainColour];
		self.circleProgressBar.progressBarProgressColor = clockwise ? [LMColour mainColour] : [LMColour clearColour];
		self.circleProgressBar.startAngle = -90.0f;
		
		
		self.iconView = [UIImageView new];
		self.iconView.image = [LMAppIcon imageForIcon:self.icon];
		[self.circleProgressBar addSubview:self.iconView];
		
		CGFloat iconMultiplier = (1.5/4.0f);
		
		[self.iconView autoCentreInSuperview];
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.circleProgressBar withMultiplier:iconMultiplier];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.circleProgressBar withMultiplier:iconMultiplier];
	}

	self.layer.masksToBounds = YES;
	self.layer.cornerRadius = self.squareMode ? 0.0f : (self.frame.size.height / 2.0);
}

- (void)setDirection:(LMNowPlayingAnimationCircleDirection)direction {
	_direction = direction;
	
	BOOL clockwise = (direction == LMNowPlayingAnimationCircleDirectionClockwise);
	
	self.circleProgressBar.progressBarTrackColor = clockwise ? [LMColour clearColour] : [LMColour mainColour];
	self.circleProgressBar.progressBarProgressColor = clockwise ? [LMColour mainColour] : [LMColour clearColour];
}

- (LMNowPlayingAnimationCircleDirection)direction {
	return _direction;
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
	[self.circleProgressBar setProgress:progress animated:animated duration:0.3f];
}

- (void)setProgress:(CGFloat)progress {
	[self setProgress:progress animated:NO];
}

- (CGFloat)progress {
	return self.circleProgressBar.progress;
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.icon = LMIconBug;
	}
	return self;
}

@end
