//
//  LMSourceSelector.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSourceSelectorView.h"
#import "LMButton.h"
#import "LMCircleView.h"
#import "LMLabel.h"

@interface LMSourceSelectorView()<LMButtonDelegate>

@property UIVisualEffectView *blurredBackgroundView;

@property UIView *contentBackgroundView;
@property UILabel *chooseYourViewLabel;

@property LMCircleView *sourceSelectorButtonBackgroundView;
@property LMButton *sourceSelectorButton;

@property UIView *currentSourceLabelBackgroundView, *detailInfoLabelBackgroundView;
@property LMLabel *currentSourceLabel, *detailInfoLabel;

@end

@implementation LMSourceSelectorView

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Hey there buddy boi");
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	self.blurredBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	self.blurredBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.blurredBackgroundView];
	
	[self.blurredBackgroundView autoCenterInSuperview];
	[self.blurredBackgroundView autoPinEdgesToSuperviewEdges];
	
	self.contentBackgroundView = [UIView newAutoLayoutView];
	self.contentBackgroundView.backgroundColor = [UIColor whiteColor];
	self.contentBackgroundView.layer.masksToBounds = YES;
	self.contentBackgroundView.layer.cornerRadius = 10.0;
	[self addSubview:self.contentBackgroundView];
	
	[self.contentBackgroundView autoCenterInSuperview];
	[self.contentBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.9];
	[self.contentBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.85];
	
	self.chooseYourViewLabel = [UILabel newAutoLayoutView];
	//self.chooseYourViewLabel.backgroundColor = [UIColor yellowColor];
	self.chooseYourViewLabel.textAlignment = NSTextAlignmentCenter;
	self.chooseYourViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
	self.chooseYourViewLabel.textColor = [UIColor blackColor];
	self.chooseYourViewLabel.text = @"Please choose your view";
	[self.contentBackgroundView addSubview:self.chooseYourViewLabel];
	
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.chooseYourViewLabel autoSetDimension:ALDimensionHeight toSize:40];
	
	self.sourceSelectorButtonBackgroundView = [LMCircleView newAutoLayoutView];
	self.sourceSelectorButtonBackgroundView.backgroundColor = [UIColor whiteColor];
	[self addSubview:self.sourceSelectorButtonBackgroundView];
	
	//Center of the background view goes on the bottom of the content view
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.sourceSelectorButtonBackgroundView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.contentBackgroundView
													 attribute:NSLayoutAttributeBottom
													multiplier:1.0
													  constant:-5]];
	[self.sourceSelectorButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	float sizeMultiplier = (1.0/10.0)/1.25;
	[self.sourceSelectorButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:sizeMultiplier];
	[self.sourceSelectorButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self withMultiplier:sizeMultiplier];
	
	self.sourceSelectorButton = [LMButton newAutoLayoutView];
	self.sourceSelectorButton.userInteractionEnabled = YES;
	self.sourceSelectorButton.delegate = self;
	[self.sourceSelectorButtonBackgroundView addSubview:self.sourceSelectorButton];
	
	[self.sourceSelectorButton autoCenterInSuperview];
	[self.sourceSelectorButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sourceSelectorButtonBackgroundView withMultiplier:0.85];
	[self.sourceSelectorButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sourceSelectorButtonBackgroundView withMultiplier:0.85];
	
	[self.sourceSelectorButton setupWithImageMultiplier:0.5];
	[self.sourceSelectorButton setImage:[UIImage imageNamed:@"play_white.png"]];
	
	self.currentSourceLabelBackgroundView = [UIView newAutoLayoutView];
	[self.contentBackgroundView addSubview:self.currentSourceLabelBackgroundView];
	
	[self.currentSourceLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.currentSourceLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.currentSourceLabelBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.sourceSelectorButtonBackgroundView];
	[self.currentSourceLabelBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.sourceSelectorButtonBackgroundView];
	
	self.detailInfoLabelBackgroundView = [UIView newAutoLayoutView];
	[self.contentBackgroundView addSubview:self.detailInfoLabelBackgroundView];
	
	[self.detailInfoLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.detailInfoLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.detailInfoLabelBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sourceSelectorButtonBackgroundView];
	[self.detailInfoLabelBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.sourceSelectorButtonBackgroundView];
	
	self.currentSourceLabel = [LMLabel newAutoLayoutView];
	self.currentSourceLabel.text = @"Albums";
	self.currentSourceLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0f];
	[self.currentSourceLabelBackgroundView addSubview:self.currentSourceLabel];
	
	float widthMultiplier = 0.8;
	float heightMultiplier = 0.7;
	
	[self.currentSourceLabel autoCenterInSuperview];
	[self.currentSourceLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.currentSourceLabelBackgroundView withMultiplier:widthMultiplier];
	[self.currentSourceLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceLabelBackgroundView withMultiplier:heightMultiplier];
	
	self.detailInfoLabel = [LMLabel newAutoLayoutView];
	self.detailInfoLabel.textAlignment = NSTextAlignmentRight;
	self.detailInfoLabel.text = @"69 Albums";
	self.detailInfoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self.detailInfoLabelBackgroundView addSubview:self.detailInfoLabel];
	
	[self.detailInfoLabel autoCenterInSuperview];
	[self.detailInfoLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.detailInfoLabelBackgroundView withMultiplier:widthMultiplier];
	[self.detailInfoLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.detailInfoLabelBackgroundView withMultiplier:heightMultiplier];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
