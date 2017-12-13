//
//  LMTrackDurationView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTrackDurationView.h"
#import "LMColour.h"

@interface LMTrackDurationView()

@property NSTimeInterval lastEditedInterval;

@end

@implementation LMTrackDurationView

- (void)setAsShouldUpdate {
	self.shouldUpdateValue = YES;
}

- (void)touchIn {
	self.shouldUpdateValue = NO;
}

- (void)changed {	
	if(self.delegate){
		[self.delegate seekSliderValueChanged:self.seekSlider.value isFinal:NO];
	}
	
	self.lastEditedInterval = [[NSDate date] timeIntervalSince1970];
}

- (void)touchFinished {
	[self setAsShouldUpdate];
	
	if(self.delegate){
		[self.delegate seekSliderValueChanged:self.seekSlider.value isFinal:YES];
	}
}

- (BOOL)didJustFinishEditing {
	if([[NSDate date] timeIntervalSince1970]-self.lastEditedInterval < 0.1){
		return YES;
	}
	return NO;
}

- (void)setup {
	self.shouldUpdateValue = YES;
	
	self.seekSlider = [[LMSlider alloc]init];
	self.seekSlider.translatesAutoresizingMaskIntoConstraints = NO;
	self.seekSlider.continuous = YES;
//	self.seekSlider.backgroundColor = [UIColor blueColor];
	self.seekSlider.tintColor = [LMColour mainColour];
	[self addSubview:self.seekSlider];
	
	[self.seekSlider addTarget:self action:@selector(touchIn) forControlEvents:UIControlEventTouchDown];
	[self.seekSlider addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
	[self.seekSlider addTarget:self action:@selector(touchFinished) forControlEvents:UIControlEventTouchUpOutside];
	[self.seekSlider addTarget:self action:@selector(touchFinished) forControlEvents:UIControlEventTouchUpInside];
	[self.seekSlider addTarget:self action:@selector(touchFinished) forControlEvents:UIControlEventTouchCancel];
	
	[self.seekSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.seekSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.seekSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[self.seekSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(2.0/3.0)];
	
	self.songCountLabel = [[LMLabel alloc]init];
	self.songCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
//	self.songCountLabel.backgroundColor = [UIColor orangeColor];
	self.songCountLabel.textAlignment = NSTextAlignmentLeft;
	self.songCountLabel.textColor = [UIColor blackColor];
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:self.shouldInsetInfo ? 15 : 0];
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.seekSlider];
	[self.songCountLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.songCountLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.seekSlider withMultiplier:0.5];
	
	self.songDurationLabel = [[LMLabel alloc]init];
	self.songDurationLabel.translatesAutoresizingMaskIntoConstraints = NO;
//	self.songDurationLabel.backgroundColor = [UIColor redColor];
	self.songDurationLabel.textAlignment = NSTextAlignmentRight;
	self.songDurationLabel.textColor = [UIColor blackColor];
	self.songDurationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self addSubview:self.songDurationLabel];
	
	[self.songDurationLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.songCountLabel];
	[self.songDurationLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.songCountLabel];
	[self.songDurationLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.songCountLabel];
	[self.songDurationLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.songCountLabel withOffset:self.shouldInsetInfo ? -30 : 0];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
