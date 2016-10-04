//
//  LMSongDetailControlView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/3/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSongDetailControlView.h"
#import "LMButton.h"

@interface LMSongDetailControlView() <LMButtonDelegate>

@property UIView *shuffleBackgroundView, *favouriteBackgroundView, *repeatBackgroundView;
@property LMButton *shuffleButton, *favouriteButton, *repeatButton;

@property BOOL loadedConstraints;

@end

@implementation LMSongDetailControlView

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Sup dog");
	[UIView animateWithDuration:0.25 animations:^{
		[button setColour:[[button getColor:button] isEqual:[UIColor whiteColor]] ? [UIColor clearColor] : [UIColor whiteColor]];
	}];
	if(button == self.shuffleButton){
		
	}
	else if(button == self.favouriteButton){
		
	}
	else{
		
	}
}

- (void)updateConstraints {
	if(!self.loadedConstraints){
		self.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
		
		self.shuffleButton = [LMButton new];
		self.favouriteButton = [LMButton new];
		self.repeatButton = [LMButton new];
		
		self.shuffleBackgroundView = [UIView newAutoLayoutView];
		self.favouriteBackgroundView = [UIView newAutoLayoutView];
		self.repeatBackgroundView = [UIView newAutoLayoutView];
		
		NSArray *images = @[@"shuffle_black.png", @"favourite_heart.png", @"repeat_black.png"];
		NSArray *buttons = @[self.shuffleButton, self.favouriteButton, self.repeatButton];
		NSArray *backgrounds = @[self.shuffleBackgroundView, self.favouriteBackgroundView, self.repeatBackgroundView];
		
		for(uint8_t i = 0; i < images.count; i++){
			NSString *currentImage = [images objectAtIndex:i];
			LMButton *currentButton = [buttons objectAtIndex:i];
			UIView *currentBackground = [backgrounds objectAtIndex:i];
			UIView *previousBackground = (i == 0) ? self : [backgrounds objectAtIndex:i-1];
			
			currentBackground.backgroundColor = [UIColor clearColor];
			[self addSubview:currentBackground];
			
			[currentBackground autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0f/3.0f)];
			[currentBackground autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
			[currentBackground autoPinEdge:ALEdgeLeading toEdge:((i == 0) ? ALEdgeLeading : ALEdgeTrailing) ofView:previousBackground];
			[currentBackground autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
			
			currentButton.delegate = self;
			currentButton.translatesAutoresizingMaskIntoConstraints = NO;
			[currentBackground addSubview:currentButton];
			
			[currentButton autoCenterInSuperview];
			[currentButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.7];
			[currentButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self withMultiplier:0.7];
			[currentButton setupWithImageMultiplier:0.6];
			
			[currentButton setColour:[UIColor clearColor]];
			[currentButton setImage:[UIImage imageNamed:currentImage]];
		}
		
		self.loadedConstraints = YES;
	}
	
	[super updateConstraints];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
