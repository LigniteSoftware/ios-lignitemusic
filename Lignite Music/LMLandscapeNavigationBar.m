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
 The background view is the view which actually contains the navigation bar's contents. It is pinned to the trailing edge of self. The rest of self, from leading of self to leading of navigationBarBackgroundView is white.
 */
@property UIView *navigationBarBackgroundView;

/**
 The back button image view.
 */
@property UIImageView *backButtonImageView;

/**
 The logo image view.
 */
@property UIImageView *logoImageView;

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
	NSLog(@"%@", self.navigationBarBackgroundView.constraints);
	[self.navigationBarBackgroundView removeConstraints:self.navigationBarBackgroundView.constraints];
	
	[self.navigationBarBackgroundView autoSetDimension:ALDimensionWidth toSize:64.0f];
	
	[self.navigationBarBackgroundView layoutIfNeeded];
	
	self.createImageView.hidden = (self.mode != LMLandscapeNavigationBarModePlaylistView);
	self.editImageView.hidden = self.createImageView.hidden;
	
	self.createImageView.isAccessibilityElement = YES;
	self.createImageView.accessibilityLabel = @"create";
	self.createImageView.accessibilityHint = @"double tap to create";
	
	switch(mode){
		case LMLandscapeNavigationBarModeOnlyLogo: {
			self.backButtonImageView.hidden = YES;
			
			[self.logoImageView autoPinEdgesToSuperviewEdges];
			break;
		}
		case LMLandscapeNavigationBarModeWithBackButton: {
			self.backButtonImageView.hidden = NO;
			
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.backButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.navigationBarBackgroundView withMultiplier:0.75];
			
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			
			
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.navigationBarBackgroundView];
			
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			break;
		}
		case LMLandscapeNavigationBarModePlaylistView: {
			self.isEditing = NO;
			self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
			
			[self.createImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:18];
			[self.createImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.createImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.navigationBarBackgroundView withMultiplier:(3.0/6.0)];
			[self.createImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.createImageView];
			
			[self.editImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.createImageView withOffset:24];
			[self.editImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.createImageView];
			[self.editImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.createImageView];
			[self.editImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.createImageView];

			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:2];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.navigationBarBackgroundView];
			break;
		}
	}
	
	[UIView animateWithDuration:0.0 animations:^{
		[self.navigationBarBackgroundView layoutIfNeeded];
	}];
}

- (void)setEditing:(BOOL)editing {
	if(!editing){
		self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
		self.editImageView.hidden = NO;
		self.isEditing = NO;
	}
	else{
		self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconWhiteCheckmark]];
		self.editImageView.hidden = YES;
		self.isEditing = YES;
	}
	
	self.createImageView.isAccessibilityElement = YES;
	self.createImageView.accessibilityLabel = NSLocalizedString(self.isEditing ? @"VoiceOverLabel_FinishEditingPlaylists" : @"VoiceOverLabel_CreatePlaylist", nil);
	self.createImageView.accessibilityHint = NSLocalizedString(self.isEditing ? @"VoiceOverHint_FinishEditingPlaylists" : @"VoiceOverHint_CreatePlaylist", nil);
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
			[self setEditing:NO];
			
			[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonEdit]; //To inverse editing mode
		}
		else{
			[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonCreate];
		}
	}
	else if(gestureRecognizer.view == self.editImageView){
		[self setEditing:YES];
		
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonEdit];
	}
	else{
		NSAssert(false, @"Unknown landscape navigation bar view tapped");
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.backgroundColor = [UIColor whiteColor];
		
		
		self.navigationBarBackgroundView = [UIView newAutoLayoutView];
		self.navigationBarBackgroundView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.navigationBarBackgroundView];
		
		[self.navigationBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.navigationBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.navigationBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.navigationBarBackgroundView autoSetDimension:ALDimensionWidth toSize:64.0f];
		
		
		
//		[self.navigationBarBackgroundView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
//		[self.navigationBarBackgroundView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];


		self.userInteractionEnabled = YES;

		self.backButtonImageView = [UIImageView newAutoLayoutView];
		self.backButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backButtonImageView.image = [LMAppIcon imageForIcon:LMIconiOSBack inverted:YES];
		self.backButtonImageView.clipsToBounds = YES;
		self.backButtonImageView.userInteractionEnabled = YES;
		self.backButtonImageView.hidden = YES;
		self.backButtonImageView.isAccessibilityElement = YES;
		self.backButtonImageView.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_BackButton", nil);
		self.backButtonImageView.accessibilityHint = NSLocalizedString(@"VoiceOverHint_BackButton", nil);
		[self.navigationBarBackgroundView addSubview:self.backButtonImageView];

		UITapGestureRecognizer *backButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.backButtonImageView addGestureRecognizer:backButtonTapGestureRecognizer];


		self.logoImageView = [UIImageView newAutoLayoutView];
		self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.logoImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		self.logoImageView.clipsToBounds = YES;
		self.logoImageView.userInteractionEnabled = YES;
		self.logoImageView.isAccessibilityElement = YES;
		self.logoImageView.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_NowPlayingIconShortcut", nil);
		self.logoImageView.accessibilityHint = NSLocalizedString(@"VoiceOverHint_NowPlayingIconShortcut", nil);
		[self.navigationBarBackgroundView addSubview:self.logoImageView];

		UITapGestureRecognizer *logoImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.logoImageView addGestureRecognizer:logoImageViewTapGestureRecognizer];


		self.createImageView = [UIImageView newAutoLayoutView];
		self.createImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.createImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAdd]];
		self.createImageView.clipsToBounds = YES;
		self.createImageView.userInteractionEnabled = YES;
		[self.navigationBarBackgroundView addSubview:self.createImageView];

		UITapGestureRecognizer *createImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.createImageView addGestureRecognizer:createImageViewTapGestureRecognizer];


		self.editImageView = [UIImageView newAutoLayoutView];
		self.editImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.editImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconEdit]];
		self.editImageView.clipsToBounds = YES;
		self.editImageView.userInteractionEnabled = YES;
		self.editImageView.isAccessibilityElement = YES;
		self.editImageView.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_EditPlaylists", nil);
		self.editImageView.accessibilityHint = NSLocalizedString(@"VoiceOverHint_EditPlaylists", nil);
		[self.navigationBarBackgroundView addSubview:self.editImageView];

		UITapGestureRecognizer *editImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.editImageView addGestureRecognizer:editImageViewTapGestureRecognizer];


		[self setMode:self.mode];
	}
}

@end
