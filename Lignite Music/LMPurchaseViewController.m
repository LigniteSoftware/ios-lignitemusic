//
//  LMPurchaseViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPurchaseViewController.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMButtonBar.h"
#import "LMPurchaseManager.h"

@interface LMPurchaseViewController () <LMButtonBarDelegate, LMPurchaseManagerDelegate>

/**
 The background (tiled) image view.
 */
@property UIImageView *backgroundImageView;

/**
 The header image view.
 */
@property UIImageView *headerImageView;

/**
 The title label.
 */
@property UILabel *titleLabel;

/**
 The description label which first tries to sell the user.
 */
@property UILabel *descriptionLabel;

/**
 Kickstarter backer label which lets them know how to login if they're a Kickstarter backer.
 */
@property UILabel *kickstarterBackerLabel;

/**
 The button bar for taking ownership of the app (buy/login).
 */
@property LMButtonBar *ownershipButtonBar;

/**
 The purchase manager.
 */
@property LMPurchaseManager *purchaseManager;

/**
 The pending view controller when waiting for the purchase to begin.
 */
@property UIAlertController *pendingViewController;

@end

@implementation LMPurchaseViewController

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)appOwnershipStatusChanged:(LMPurchaseManagerAppOwnershipStatus)newOwnershipStatus {
	NSLog(@"Got new app ownership on the purchase view, too.");
}

- (void)transactionStateChangedTo:(SKPaymentTransactionState)transactionState forProductWithIdentifier:(LMPurchaseManagerProductIdentifier *)productIdentifier {
	if(self.pendingViewController){
		[self dismissViewControllerAnimated:YES completion:nil];
		self.pendingViewController = nil;
	}
}

- (void)tappedButtonBarButtonAtIndex:(NSUInteger)index forButtonBar:(LMButtonBar *)buttonBar {
	NSLog(@"Tapped %d!", (int)index);
	switch(index){
		case 0: { //Backer login
			break;
		}
		case 1: {
			[self.purchaseManager makePurchaseWithProductIdentifier:LMPurchaseManagerProductIdentifierLifetimeMusic];
			
			self.pendingViewController = [UIAlertController alertControllerWithTitle:nil
																			 message:[NSString stringWithFormat:@"%@\n\n\n", NSLocalizedString(@"HoldOn", nil)]
																	  preferredStyle:UIAlertControllerStyleAlert];
			UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
			indicator.color = [UIColor blackColor];
			indicator.translatesAutoresizingMaskIntoConstraints = NO;
			[self.pendingViewController.view addSubview:indicator];
			NSDictionary * views = @{ @"pending": self.pendingViewController.view,
									  @"indicator": indicator };
			
			NSArray *constraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[indicator]-(20)-|" options:0 metrics:nil views:views];
			NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[indicator]|" options:0 metrics:nil views:views];
			NSArray *constraints = [constraintsVertical arrayByAddingObjectsFromArray:constraintsHorizontal];
			[self.pendingViewController.view addConstraints:constraints];
			
			[indicator setUserInteractionEnabled:NO];
			[indicator startAnimating];
			
			[self presentViewController:self.pendingViewController animated:YES completion:nil];
			break;
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.purchaseManager = [LMPurchaseManager sharedPurchaseManager];
	[self.purchaseManager addDelegate:self];
	
	self.backgroundImageView = [UIImageView newAutoLayoutView];
	self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
	self.backgroundImageView.image = [UIImage imageNamed:@"lignite_background_portrait.png"];
	[self.view addSubview:self.backgroundImageView];
	
	NSInteger parallaxEffectDistance = 15;
	
	[self.backgroundImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:-parallaxEffectDistance];
	[self.backgroundImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:-parallaxEffectDistance];
	[self.backgroundImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-parallaxEffectDistance];
	[self.backgroundImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:(WINDOW_FRAME.size.height/8.0)-parallaxEffectDistance];
	
	//http://stackoverflow.com/questions/18972994/ios-7-parallax-effect-in-my-view-controller
	
	// Set vertical effect
	UIInterpolatingMotionEffect *verticalMotionEffect =
	[[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	verticalMotionEffect.minimumRelativeValue = @(-parallaxEffectDistance);
	verticalMotionEffect.maximumRelativeValue = @(parallaxEffectDistance);
	
	// Set horizontal effect
	UIInterpolatingMotionEffect *horizontalMotionEffect =
	[[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
	horizontalMotionEffect.minimumRelativeValue = @(-parallaxEffectDistance);
	horizontalMotionEffect.maximumRelativeValue = @(parallaxEffectDistance);
	
	// Create group to combine both
	UIMotionEffectGroup *group = [UIMotionEffectGroup new];
	group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
	
	// Add both effects to your view
	[self.backgroundImageView addMotionEffect:group];
	
	
	self.headerImageView = [UIImageView newAutoLayoutView];
	self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.headerImageView.image = [UIImage imageNamed:@"purchase_header.png"];
	[self.view addSubview:self.headerImageView];
	
	[self.headerImageView autoPinEdgeToSuperviewMargin:ALEdgeTop];
	[self.headerImageView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.headerImageView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.headerImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(3.75/10.0)];
	
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.text = NSLocalizedString(@"TrialTimeIsUpTitle", nil);
	self.titleLabel.textAlignment = NSTextAlignmentJustified;
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:(WINDOW_FRAME.size.width*0.0483)];
	self.titleLabel.numberOfLines = 0;
	[self.view addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerImageView withOffset:20];
	[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.text = NSLocalizedString(@"TrialTimeIsUpDescription", nil);
	self.descriptionLabel.textAlignment = NSTextAlignmentJustified;
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width*0.0437)];
	self.descriptionLabel.numberOfLines = 0;
	[self.view addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
	[self.descriptionLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.descriptionLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	
	NSMutableArray *advantagesLabelArray = [NSMutableArray new];
	
	NSArray *advantagesArray = @[
								 @"AppAdvantage0", @"AppAdvantage1", @"AppAdvantage2"
								 ];
	
	for(NSString *appAdvantage in advantagesArray){
		NSString *appAdvantageString = NSLocalizedString(appAdvantage, nil);
		
		CGFloat stringHeight = [appAdvantageString sizeWithAttributes:@{
												  NSFontAttributeName: self.descriptionLabel.font
												  }].height;
		
		BOOL firstView = ([appAdvantage isEqualToString:[advantagesArray firstObject]]);
		UIView *previousView = firstView ? self.descriptionLabel : [advantagesLabelArray lastObject];
		
		UIImageView *checkmarkView = [UIImageView newAutoLayoutView];
		checkmarkView.contentMode = UIViewContentModeScaleAspectFit;
		checkmarkView.image = [LMAppIcon imageForIcon:LMIconGreenCheckmark];
		[self.view addSubview:checkmarkView];
		
		[checkmarkView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[checkmarkView autoSetDimension:ALDimensionHeight toSize:stringHeight];
		[checkmarkView autoSetDimension:ALDimensionWidth toSize:stringHeight];
		[checkmarkView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:10];
	
		
		UILabel *advantageLabel = [UILabel newAutoLayoutView];
		advantageLabel.text = appAdvantageString;
		advantageLabel.textAlignment = NSTextAlignmentLeft;
		advantageLabel.font = self.descriptionLabel.font;
		advantageLabel.numberOfLines = 0;
		[self.view addSubview:advantageLabel];
		
		[advantageLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:checkmarkView];
		[advantageLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:checkmarkView withOffset:10];
		[advantageLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		
		[advantagesLabelArray addObject:advantageLabel];
	}
	
	
	self.kickstarterBackerLabel = [UILabel newAutoLayoutView];
	self.kickstarterBackerLabel.text = NSLocalizedString(@"IfYoureAKickstarterBacker", nil);
	self.kickstarterBackerLabel.textAlignment = NSTextAlignmentJustified;
	self.kickstarterBackerLabel.font = self.descriptionLabel.font;
	self.kickstarterBackerLabel.numberOfLines = 0;
	[self.view addSubview:self.kickstarterBackerLabel];
	
	[self.kickstarterBackerLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.kickstarterBackerLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.kickstarterBackerLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[advantagesLabelArray lastObject] withOffset:20];


	self.ownershipButtonBar = [LMButtonBar newAutoLayoutView];
	self.ownershipButtonBar.amountOfButtons = 2;
	self.ownershipButtonBar.buttonIconsArray = @[ @(LMIconKickstarter), @(LMIconBuy) ];
	self.ownershipButtonBar.buttonScaleFactorsArray = @[ @(1.0), @(1.0) ];
	self.ownershipButtonBar.delegate = self;
	self.ownershipButtonBar.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.ownershipButtonBar];
	
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.ownershipButtonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/8.0)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
