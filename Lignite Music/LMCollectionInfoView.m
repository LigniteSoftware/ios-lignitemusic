//
//  LMCollectionInfoView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCollectionInfoView.h"
#import "LMLabel.h"

@interface LMCollectionInfoView()

@property UIView *topView;
@property LMLabel *titleLabel;

@property UIView *bottomView;

@property LMLabel *leftTextLabel;

@property UIView *middleDividerView;
@property LMLabel *middleDividerLabel;
@property UIImageView *middleDividerImageView;

@property LMLabel *rightTextLabel;

@property BOOL didInitialSetup;

@end

@implementation LMCollectionInfoView

- (instancetype)init {
	self = [super init];
	if(self) {
		self.topView = [UIView newAutoLayoutView];
//		self.topView.backgroundColor = [UIColor redColor];
		[self addSubview:self.topView];
		
		self.titleLabel = [LMLabel newAutoLayoutView];
		self.titleLabel.text = @"Title";
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		self.titleLabel.textAlignment = NSTextAlignmentCenter;
		[self.topView addSubview:self.titleLabel];
		
		self.bottomView = [UIView newAutoLayoutView];
//		self.bottomView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.bottomView];
		
		self.leftTextLabel = [LMLabel newAutoLayoutView];
		self.leftTextLabel.text = @"Left text";
		self.leftTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		[self.bottomView addSubview:self.leftTextLabel];
		
		self.middleDividerView = [UIView newAutoLayoutView];
		[self.bottomView addSubview:self.middleDividerView];
		
		self.middleDividerLabel = [LMLabel newAutoLayoutView];
		self.middleDividerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		self.middleDividerLabel.textAlignment = NSTextAlignmentCenter;
		self.middleDividerLabel.text = @"|";
		[self.middleDividerView addSubview:self.middleDividerLabel];
		
		self.middleDividerImageView = [UIImageView newAutoLayoutView];
//		self.middleDividerImageView.backgroundColor = [UIColor greenColor];
		self.middleDividerImageView.image = [UIImage imageNamed:@"icon_bug.png"];
		self.middleDividerImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.middleDividerView addSubview:self.middleDividerImageView];
		
		self.rightTextLabel = [LMLabel newAutoLayoutView];
		self.rightTextLabel.text = @"Right text";
		self.rightTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		[self.bottomView addSubview:self.rightTextLabel];
	}
	else{
		NSLog(@"Windows error creating LMCollectionInfoView");
	}
	return self;
}

- (void)reloadData {
	NSString *title = [self.delegate titleForInfoView:self];
	NSString *leftText = [self.delegate leftTextForInfoView:self];
	NSString *rightText = [self.delegate rightTextForInfoView:self];
	UIImage *middleImage = [self.delegate centerImageForInfoView:self];
	
	self.titleLabel.text = title ? title : @"";
	self.leftTextLabel.text = leftText ? leftText : @"";
	self.rightTextLabel.text = rightText ? rightText : @"";
	self.middleDividerImageView.image = middleImage;
	
	if(!self.didInitialSetup){
		[self.topView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.topView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.topView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.topView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.7];
		
		[self.bottomView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.bottomView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.bottomView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.bottomView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topView];
		
		[self.titleLabel autoCenterInSuperview];
		[self.titleLabel autoPinEdgesToSuperviewEdges];
		 
		[self.middleDividerLabel autoCenterInSuperview];
		[self.middleDividerLabel autoPinEdgesToSuperviewEdges];
		
		[self.middleDividerImageView autoCenterInSuperview];
		[self.middleDividerImageView autoPinEdgesToSuperviewEdges];
	}
	
	[self.bottomView.constraints autoRemoveConstraints];
	
	BOOL hasRightText = (rightText != nil);
	BOOL hasMiddleImage = (middleImage != nil);
	
	if(hasRightText){
		self.middleDividerView.hidden = NO;
		
		self.leftTextLabel.textAlignment = NSTextAlignmentRight;
		self.rightTextLabel.textAlignment = NSTextAlignmentLeft;
		self.middleDividerLabel.hidden = hasMiddleImage;
		self.middleDividerImageView.hidden = !hasMiddleImage;
		
		[self.middleDividerView autoCenterInSuperview];
		[self.middleDividerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.bottomView withMultiplier:hasMiddleImage ? 2.0 : 0.5]; //The multiplier is to ensure some spacing for the label
		[self.middleDividerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomView];
		
		[self.leftTextLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.leftTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.leftTextLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.leftTextLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.middleDividerView];
		
		[self.rightTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.rightTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.rightTextLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.rightTextLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.middleDividerView];
	}
	else{
		self.middleDividerView.hidden = YES;
		
		self.leftTextLabel.textAlignment = NSTextAlignmentCenter;
		
		[self.leftTextLabel autoCenterInSuperview];
		[self.leftTextLabel autoPinEdgesToSuperviewEdges];
	}
}

@end
