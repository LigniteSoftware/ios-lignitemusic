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

@end

@implementation LMTrackDurationView

- (void)touchIn {
	NSLog(@"Touch in");
}

- (void)changed {
	NSLog(@"Changed");
}

- (void)touchOut {
	NSLog(@"Touch out");
}

- (void)setup {
	self.seekSlider = [[LMSlider alloc]init];
	self.seekSlider.translatesAutoresizingMaskIntoConstraints = NO;
//	self.seekSlider.backgroundColor = [UIColor blueColor];
	self.seekSlider.tintColor = [LMColour ligniteRedColour];
	[self addSubview:self.seekSlider];
	
	[self.seekSlider addTarget:self action:@selector(touchIn) forControlEvents:UIControlEventTouchDown];
	[self.seekSlider addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
	[self.seekSlider addTarget:self action:@selector(touchOut) forControlEvents:UIControlEventTouchUpInside];
	
	[self.seekSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.seekSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.seekSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[self.seekSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(2.0/3.0)];
	
	self.songCountLabel = [[LMLabel alloc]init];
	self.songCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
//	self.songCountLabel.backgroundColor = [UIColor orangeColor];
	self.songCountLabel.textAlignment = NSTextAlignmentLeft;
	self.songCountLabel.textColor = [UIColor blackColor];
	self.songCountLabel.text = @"Count";
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.seekSlider];
	[self.songCountLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.songCountLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.seekSlider withMultiplier:0.5];
	
	self.songDurationLabel = [[LMLabel alloc]init];
	self.songDurationLabel.translatesAutoresizingMaskIntoConstraints = NO;
//	self.songDurationLabel.backgroundColor = [UIColor redColor];
	self.songDurationLabel.textAlignment = NSTextAlignmentRight;
	self.songDurationLabel.textColor = [UIColor blackColor];
	self.songDurationLabel.text = @"Duration";
	self.songDurationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self addSubview:self.songDurationLabel];
	
	[self.songDurationLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.songCountLabel];
	[self.songDurationLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.songCountLabel];
	[self.songDurationLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.songCountLabel];
	[self.songDurationLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.songCountLabel];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
