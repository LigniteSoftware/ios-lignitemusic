//
//  LMLandscapeNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 4/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLandscapeNavigationBar.h"
#import "LMAppIcon.h"

@interface LMLandscapeNavigationBar()

/**
 The back button image view.
 */
@property UIImageView *backButtonImageView;

/**
 The logo image view.
 */
@property UIImageView *logoImageView;

/**
 The image view for the warning button.
 */
@property UIImageView *warningImageView;

/**
 The image view for the create button.
 */
@property UIImageView *createImageView;

/**
 The image view for the edit button.
 */
@property UIImageView *editImageView;

/**
 If the mode is LMLandscapeNavigationBarModePlaylistView, and the user taps the edit button, this will switch to YES and the create button will become the cancel button. Once the create button is then tapped, this will be set to NO and the button configuration will be restored.
 */
@property BOOL isEditing;

@end

@implementation LMLandscapeNavigationBar

@synthesize mode = _mode;
@synthesize showWarningButton = _showWarningButton;

- (BOOL)showWarningButton {
	return _showWarningButton;
}

- (void)setShowWarningButton:(BOOL)showWarningButton {
	_showWarningButton = showWarningButton;

	[self setMode:self.mode];
}

- (LMLandscapeNavigationBarMode)mode {
	return _mode;
}

- (void)setMode:(LMLandscapeNavigationBarMode)mode {
	_mode = mode;
	
	if(!self.didLayoutConstraints){
		return;
	}
	
	[self.backButtonImageView removeConstraints:self.backButtonImageView.constraints];
	[self.logoImageView removeConstraints:self.logoImageView.constraints];
	[self removeConstraints:self.constraints];
	
	[self layoutIfNeeded];
	
	self.warningImageView.hidden = !self.showWarningButton;
	
	self.createImageView.hidden = self.mode != LMLandscapeNavigationBarModePlaylistView;
	self.editImageView.hidden = self.createImageView.hidden;
	
	switch(mode){
		case LMLandscapeNavigationBarModeOnlyLogo: {
			self.backButtonImageView.hidden = YES;
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			
			
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.warningImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
			break;
		}
		case LMLandscapeNavigationBarModeWithBackButton: {
			self.backButtonImageView.hidden = NO;
			
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.backButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:0.75];
			
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			
			
			[self.warningImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.backButtonImageView];
			[self.warningImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.logoImageView];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			
			[self.warningImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.warningImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:2];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
			
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			break;
		}
		case LMLandscapeNavigationBarModePlaylistView: {
			self.isEditing = NO;
			self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
			
			[self.createImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:18];
			[self.createImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.createImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(3.0/6.0)];
			[self.createImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.createImageView];
			
			[self.editImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.createImageView withOffset:24];
			[self.editImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.createImageView];
			[self.editImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.createImageView];
			[self.editImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.createImageView];
			
			[self.warningImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.logoImageView];
			[self.warningImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.logoImageView];
			[self.warningImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.logoImageView];
			[self.warningImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.logoImageView];
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:2];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
			break;
		}
	}
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)tappedButton:(UIGestureRecognizer*)gestureRecognizer {
	if(gestureRecognizer.view == self.backButtonImageView){
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonBack];
	}
	else if(gestureRecognizer.view == self.logoImageView){
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonLogo];
	}
	else if(gestureRecognizer.view == self.createImageView){
		if(self.isEditing){
			self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
			self.editImageView.hidden = NO;
			self.isEditing = NO;
			
			[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonEdit]; //To inverse editing mode
		}
		else{
			[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonCreate];
		}
	}
	else if(gestureRecognizer.view == self.editImageView){
		self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconXCross]];
		self.editImageView.hidden = YES;
		self.isEditing = YES;
		
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonEdit];
	}
	else{
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonWarning];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.backgroundColor = [UIColor whiteColor];
		
		
		[self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
		[self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
		
		
		self.backgroundColor = [UIColor whiteColor];
		self.userInteractionEnabled = YES;
		
		self.backButtonImageView = [UIImageView new];
		self.backButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backButtonImageView.image = [LMAppIcon imageForIcon:LMIconiOSBack];
		self.backButtonImageView.clipsToBounds = YES;
		self.backButtonImageView.userInteractionEnabled = YES;
		[self addSubview:self.backButtonImageView];
		
		UITapGestureRecognizer *backButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.backButtonImageView addGestureRecognizer:backButtonTapGestureRecognizer];
		
		
		self.logoImageView = [UIImageView new];
		self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.logoImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		self.logoImageView.clipsToBounds = YES;
		self.logoImageView.userInteractionEnabled = YES;
		[self addSubview:self.logoImageView];
		
		UITapGestureRecognizer *logoImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.logoImageView addGestureRecognizer:logoImageViewTapGestureRecognizer];
		
		
		self.warningImageView = [UIImageView new];
		self.warningImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.warningImageView.image = [LMAppIcon imageForIcon:LMIconWarning];
		self.warningImageView.clipsToBounds = YES;
		self.warningImageView.userInteractionEnabled = YES;
		[self addSubview:self.warningImageView];
		
		UITapGestureRecognizer *warningImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.warningImageView addGestureRecognizer:warningImageViewTapGestureRecognizer];
		
		
		self.createImageView = [UIImageView new];
		self.createImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
		self.createImageView.clipsToBounds = YES;
		self.createImageView.userInteractionEnabled = YES;
		[self addSubview:self.createImageView];
		
		UITapGestureRecognizer *createImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.createImageView addGestureRecognizer:createImageViewTapGestureRecognizer];
		
		
		self.editImageView = [UIImageView new];
		self.editImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.editImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconEdit]];
		self.editImageView.clipsToBounds = YES;
		self.editImageView.userInteractionEnabled = YES;
		[self addSubview:self.editImageView];
		
		UITapGestureRecognizer *editImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.editImageView addGestureRecognizer:editImageViewTapGestureRecognizer];
		
		
		[self setMode:self.mode];
	}
}

@end
