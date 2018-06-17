//
//  LMAlertViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/6/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <BEMCheckBox/BEMCheckBox.h>
#import <PureLayout/PureLayout.h>
#import "LMAlertViewController.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMColour.h"
#import "LMExtras.h"

@interface LMAlertViewController ()<LMLayoutChangeDelegate, BEMCheckBoxDelegate>

/**
 The array of buttons in order from bottom to top.
 */
@property NSMutableArray<UIButton*>* buttonsArray;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The checkbox for user confirmation, if checkboxText is defined.
 */
@property BEMCheckBox *confirmationCheckbox;

/**
 The text view of the main contents of the alert.
 */
@property UITextView *bodyTextView;

/**
 Feedback generator for haptic feedback.
 */
@property id feedbackGenerator;

@end

@implementation LMAlertViewController

- (void)didTapCheckBox:(BEMCheckBox*)checkBox {
	NSLog(@"Checked %d", checkBox.on);
	
	UIColor *alertColour = checkBox.on ? [self.alertOptionColours lastObject] : [UIColor lightGrayColor];
	UIButton *button = [self.buttonsArray lastObject];
	
	[button setTitle:NSLocalizedString(checkBox.on ? [self.alertOptionTitles lastObject] : @"PleaseAcceptTheCheckbox", nil) forState:UIControlStateNormal];
	
	[UIView animateWithDuration:0.4 animations:^{
		button.backgroundColor = alertColour;
	}];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		if(UIAccessibilityIsVoiceOverRunning()){
			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(checkBox.on ?@"VoiceOverLabel_CheckboxChecked" : @"VoiceOverLabel_CheckboxUnchecked", nil));
		}
	} repeats:NO];

	[self hapticFeedbackSetup];
	[self hapticFeedbackSelectionChanged];
	[self hapticFeedbackFinalize];
}

- (void)tappedConfirmationLabel {
	[self.confirmationCheckbox setOn:!self.confirmationCheckbox.on animated:YES];
	[self didTapCheckBox:self.confirmationCheckbox];
}

- (void)tappedMoreInfoLabel {
	NSLog(@"More info");
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.checkboxMoreInformationLink] options:@{} completionHandler:nil];
}

- (void)buttonTapped:(id)button {
	UIButton *buttonTapped = (UIButton*)button;
	for(int i = 0; i < self.buttonsArray.count; i++){
		UIButton *aButton = [self.buttonsArray objectAtIndex:i];
		if([aButton isEqual:buttonTapped]){
			BOOL isLastButton = (i == (self.buttonsArray.count - 1));
								 
			if(self.checkboxText && !self.confirmationCheckbox.on && isLastButton){
				CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
				[animation setDuration:0.35];
				[animation setRepeatCount:2];
				[animation setAutoreverses:YES];
				[animation setFromValue:@(1.0)];
				[animation setToValue:@(1.8)];
				[[self.confirmationCheckbox layer] addAnimation:animation forKey:@"transform.scale"];
				
				return;
			}
			
			self.completionHandler(i, self.confirmationCheckbox ? (self.confirmationCheckbox.on && isLastButton) : NO);
			[self dismissViewControllerAnimated:YES completion:nil];
			break;
		}
	}
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.bodyTextView setContentOffset:CGPointZero];
		
		if(@available(iOS 11.0, *)){
			[self setNeedsUpdateOfHomeIndicatorAutoHidden];
		}
	}];
}

- (void)hapticFeedbackSetup {
	if(@available(iOS 10, *)){
		UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
		[feedbackGenerator prepare];
		
		self.feedbackGenerator = feedbackGenerator;
	}
}

- (void)hapticFeedbackSelectionChanged {
	if(@available(iOS 10, *)){
		if(self.feedbackGenerator){
			UISelectionFeedbackGenerator *feedbackGenerator = self.feedbackGenerator;
			[feedbackGenerator selectionChanged];
			[feedbackGenerator prepare];
		}
	}
}

- (void)hapticFeedbackFinalize {
	if(@available(iOS 10, *)){
		self.feedbackGenerator = nil;
	}
}

- (BOOL)prefersHomeIndicatorAutoHidden {
	return [LMLayoutManager isLandscape];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if(self.checkboxText){
		NSAssert(self.checkboxMoreInformationText && self.checkboxMoreInformationLink, @"If checkboxText is defined for an alert view controller, the more information text and link must be provided as well. This allows the user to redirect to an external page to learn why they are accepting a checkbox. Being extra-explicit in these cases is crucial.");
	}
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	CGFloat properDimension = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height);
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.buttonsArray = [NSMutableArray new];
	
	UIView *paddingView = [UIView newAutoLayoutView];
	//	paddingView.backgroundColor = [UIColor orangeColor];
	[self.view addSubview:paddingView];
	
	[paddingView autoCentreInSuperview];
	[paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(9.0/10.0)];
	[paddingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(9.0/10.0)];
	
	
	UILabel *titleLabel = [UILabel newAutoLayoutView];
	//	titleLabel.backgroundColor = [UIColor yellowColor];
	titleLabel.numberOfLines = 0;
	titleLabel.textAlignment = NSTextAlignmentLeft;
	titleLabel.text = self.titleText;
	CGFloat titleSize = 0.050 * properDimension;
	if(titleSize > 30){
		titleSize = 30;
	}
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:titleSize];
	[paddingView addSubview:titleLabel];
	
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	
	self.bodyTextView = [UITextView newAutoLayoutView];
	//	self.bodyTextView.backgroundColor = [UIColor cyanColor];
	self.bodyTextView.textAlignment = NSTextAlignmentLeft;
	self.bodyTextView.text = self.bodyText;
//	self.bodyTextView.text = [NSString stringWithFormat:@"%@ %@ %@", self.bodyText, self.bodyText, self.bodyText];
	CGFloat descriptionSize = 0.025 * properDimension;
	if(descriptionSize > 19){
		descriptionSize = 19;
	}
	self.bodyTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:descriptionSize];
	self.bodyTextView.editable = NO;
	self.bodyTextView.textColor = [LMColour blackColour];
	[paddingView addSubview:self.bodyTextView];
	
	[self.bodyTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:10];
	[self.bodyTextView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.bodyTextView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	
	for(int i = 0; i < self.alertOptionTitles.count; i++){
		BOOL isFirstButton = (i == 0);
		BOOL isLastButton = (i == (self.alertOptionTitles.count-1));
		
		NSString *alertTitle = [self.alertOptionTitles objectAtIndex:i];
		NSString *alertAccessibilityLabel = self.alertOptionAcceessibilityLabels ? [self.alertOptionAcceessibilityLabels objectAtIndex:i] : nil;
		NSString *alertAccessibilityHint = self.alertOptionAcceessibilityHints ? [self.alertOptionAcceessibilityHints objectAtIndex:i] : nil;
		UIColor *alertColour = (self.checkboxText && isLastButton) ? [UIColor lightGrayColor] : [self.alertOptionColours objectAtIndex:i];
		
		UIButton *optionButton = [UIButton newAutoLayoutView];
		optionButton.accessibilityLabel = alertAccessibilityLabel;
		optionButton.accessibilityHint = alertAccessibilityHint;
		optionButton.backgroundColor = alertColour;
		optionButton.layer.cornerRadius = 8.0f;
		optionButton.layer.masksToBounds = YES;
		optionButton.clipsToBounds = YES;
		[optionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[optionButton setTitle:(self.checkboxText && isLastButton) ? NSLocalizedString(@"PleaseAcceptTheCheckbox", nil) : alertTitle forState:UIControlStateNormal];
		[optionButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0f]];
		[paddingView addSubview:optionButton];
		
		NSArray *optionButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			if(isFirstButton){
				[optionButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.checkboxText ? 10.0f : 0.0f];
			}
			else{
				[optionButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:[self.buttonsArray lastObject] withOffset:-10.0f];
			}
			[optionButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/10.0)];
		}];
		[LMLayoutManager addNewPortraitConstraints:optionButtonPortraitConstraints];
		
		CGFloat landscapePadding = 15.0f;
		
		NSArray *optionButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			CGFloat paddingMultiplier = landscapePadding/properDimension;
			CGFloat sizeMultiplier = (1.0/(CGFloat)self.alertOptionColours.count) - paddingMultiplier;
			
			[optionButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/8.0)];
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.checkboxText ? 10.0f : 0.0f];
			[optionButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:paddingView withMultiplier:(self.alertOptionTitles.count > 1) ? sizeMultiplier : 1.0].constant = (self.alertOptionTitles.count > 1) ? (-landscapePadding*(i == self.alertOptionTitles.count-1)) : 0;
			if(isFirstButton){
				[optionButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			}
			else{
				[optionButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:[self.buttonsArray lastObject]].constant = landscapePadding*2;
			}
		}];
		[LMLayoutManager addNewLandscapeConstraints:optionButtonLandscapeConstraints];
		
		[self.buttonsArray addObject:optionButton];
	}
	
	UILabel *confirmationTextLabel = nil;
	UIView *confirmationContainer = nil;
	if(self.checkboxText){
		confirmationContainer = [UIView newAutoLayoutView];
//		confirmationContainer.backgroundColor = [UIColor blueColor];
		confirmationContainer.isAccessibilityElement = YES;
		confirmationContainer.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"VoiceOverLabel_AlertViewControllerCheckboxText", nil), self.checkboxText];
		confirmationContainer.accessibilityHint = NSLocalizedString(@"VoiceOverHint_CheckTheCheckbox", nil);
		[paddingView addSubview:confirmationContainer];
		
		[confirmationContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[confirmationContainer autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[confirmationContainer autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:[self.buttonsArray lastObject] withOffset:-20.0f];
		
		
		confirmationTextLabel = [UILabel newAutoLayoutView];
		confirmationTextLabel.userInteractionEnabled = YES;
		confirmationTextLabel.textColor = [LMColour blackColour];
		confirmationTextLabel.text = self.checkboxText;
		confirmationTextLabel.font = self.bodyTextView.font;
		confirmationTextLabel.numberOfLines = 0;
//		confirmationTextLabel.backgroundColor = [UIColor blueColor];
		[confirmationContainer addSubview:confirmationTextLabel];
		
		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:40.0f];
//		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[confirmationTextLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:[self.buttonsArray lastObject] withOffset:-20.0f];
//		[confirmationTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		UITapGestureRecognizer *confirmationLabelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedConfirmationLabel)];
		[confirmationTextLabel addGestureRecognizer:confirmationLabelTapGesture];
		
		
		self.confirmationCheckbox = [BEMCheckBox newAutoLayoutView];
		self.confirmationCheckbox.delegate = self;
		self.confirmationCheckbox.boxType = BEMBoxTypeSquare;
		self.confirmationCheckbox.tintColor = [LMColour controlBarGreyColour];
		self.confirmationCheckbox.onFillColor = [LMColour mainColour];
		self.confirmationCheckbox.onCheckColor = [UIColor whiteColor];
		self.confirmationCheckbox.onTintColor = [LMColour mainColour];
		self.confirmationCheckbox.onAnimationType = BEMAnimationTypeFill;
		self.confirmationCheckbox.offAnimationType = BEMAnimationTypeFill;
		[confirmationContainer addSubview:self.confirmationCheckbox];

		[self.confirmationCheckbox autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.confirmationCheckbox autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:confirmationTextLabel];
		[self.confirmationCheckbox autoSetDimension:ALDimensionHeight toSize:25.0f];
		[self.confirmationCheckbox autoSetDimension:ALDimensionWidth toSize:25.0f];
		
		
		UILabel *moreInfoTextLabel = [UILabel newAutoLayoutView];
		moreInfoTextLabel.userInteractionEnabled = YES;
		moreInfoTextLabel.textColor = [UIColor colorWithRed:0.02 green:0.27 blue:0.68 alpha:1.0];
		moreInfoTextLabel.textAlignment = NSTextAlignmentCenter;
		moreInfoTextLabel.text = self.checkboxMoreInformationText;
		moreInfoTextLabel.accessibilityHint = NSLocalizedString(@"VoiceOverHint_TapForMoreInformation", nil);
		moreInfoTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
		moreInfoTextLabel.numberOfLines = 1;
		//		confirmationTextLabel.backgroundColor = [UIColor blueColor];
		[self.view addSubview:moreInfoTextLabel];
		
		[moreInfoTextLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[moreInfoTextLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[moreInfoTextLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[self.buttonsArray firstObject]];
		[moreInfoTextLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
		
		UITapGestureRecognizer *moreInfoTextLabelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMoreInfoLabel)];
		[moreInfoTextLabel addGestureRecognizer:moreInfoTextLabelTapGesture];
	}
	
	
	[self.bodyTextView autoPinEdge:ALEdgeBottom
						toEdge:ALEdgeTop
						ofView:self.checkboxText ? confirmationTextLabel : [self.buttonsArray lastObject]
					withOffset:-20.0f];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
