//
//  LMTutorialHeaderView.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/20/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTutorialHeaderView.h"
#import "LMThemeEngine.h"

@interface LMTutorialHeaderView()

/**
 The background view which is in place to centre everything.
 */
@property UIView *centreBackgroundView;

/**
 The title label which is located at the top of the view.
 */
@property UILabel *titleLabel;

/**
 The button's background view which goes under the title.
 */
@property UIView *buttonBackgroundView;

/**
 The label which goes on top of the button background view.
 */
@property UILabel *buttonLabel;

/**
 The subtitle label which goes under the button.
 */
@property UILabel *subtitleLabel;

@end

@implementation LMTutorialHeaderView

- (void)tappedBackgroundButtonView {
	if([self.delegate respondsToSelector:@selector(tutorialHeaderViewButtonTapped)]){
		[self.delegate tutorialHeaderViewButtonTapped];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.userInteractionEnabled = YES;
	
		
		NSLog(@"Self is %p", self);
		
		self.centreBackgroundView = [UIView newAutoLayoutView];
//		self.centreBackgroundView.backgroundColor = [UIColor greenColor];
		[self addSubview:self.centreBackgroundView];
		
		[self.centreBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.centreBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.centreBackgroundView autoCentreInSuperview];

		
		
		self.titleLabel = [UILabel newAutoLayoutView];
		self.titleLabel.text = NSLocalizedString(@"TutorialViewTitle", nil);
		self.titleLabel.textColor = [UIColor blackColor];
//		self.titleLabel.backgroundColor = [UIColor orangeColor];
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:LMLayoutManager.isExtraSmall ? 23.0f : 26.0f];
		self.titleLabel.textAlignment = NSTextAlignmentLeft;
		self.titleLabel.numberOfLines = 0;
		[self.centreBackgroundView addSubview:self.titleLabel];
		
		[self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTop];
		[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		
		
		
		self.buttonBackgroundView = [UIView newAutoLayoutView];
		self.buttonBackgroundView.backgroundColor = [LMColour mainColour];
		[self.centreBackgroundView addSubview:self.buttonBackgroundView];
		
		UITapGestureRecognizer *buttonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedBackgroundButtonView)];
		[self.buttonBackgroundView addGestureRecognizer:buttonTapGestureRecognizer];
		

		[self.buttonBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
		[self.buttonBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:14];
		[self.buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(3.0/10.0)];
		
		NSArray *buttonBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.titleLabel];
		}];
		[LMLayoutManager addNewPortraitConstraints:buttonBackgroundViewPortraitConstraints];
		
		NSArray *buttonBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBackgroundView autoMatchDimension:ALDimensionWidth
											  toDimension:ALDimensionWidth
												   ofView:self.titleLabel
										   withMultiplier:(1.0/2.0)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:buttonBackgroundViewLandscapeConstraints];
		
		NSArray *buttonBackgroundViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBackgroundView autoMatchDimension:ALDimensionWidth
											  toDimension:ALDimensionWidth
												   ofView:self.titleLabel
										   withMultiplier:(1.0/2.0)];
		}];
		[LMLayoutManager addNewiPadConstraints:buttonBackgroundViewiPadConstraints];
		
		
		self.buttonLabel = [UILabel newAutoLayoutView];
		self.buttonLabel.text = NSLocalizedString(@"TutorialViewButtonText", nil);
		self.buttonLabel.textColor = [UIColor whiteColor];
//		self.buttonLabel.backgroundColor = [UIColor brownColor];
		self.buttonLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:LMLayoutManager.isExtraSmall ? 20.0f : 22.0f];
		self.buttonLabel.textAlignment = NSTextAlignmentCenter;
		self.buttonLabel.numberOfLines = 1;
		[self.buttonBackgroundView addSubview:self.buttonLabel];
		
		[self.buttonLabel autoCentreInSuperview];
		
		
		self.subtitleLabel = [UILabel newAutoLayoutView];
		self.subtitleLabel.text = NSLocalizedString(@"TutorialViewSubtitle", nil);
		self.subtitleLabel.textColor = [UIColor blackColor];
//		self.subtitleLabel.backgroundColor = [UIColor yellowColor];
		self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:LMLayoutManager.isExtraSmall ? 14.0f : 16.0f];
		self.subtitleLabel.textAlignment = NSTextAlignmentLeft;
		self.subtitleLabel.numberOfLines = 0;
		[self.centreBackgroundView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonBackgroundView withOffset:14];
	}
}



- (void)removeFromSuperview {
	NSLog(@"Removing %p", self);
	
	[LMLayoutManager removeAllConstraintsRelatedToView:self.buttonBackgroundView];
	
	[super removeFromSuperview];
}

@end
