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
#import "LMBackerLoginViewController.h"
#import "LMAnswers.h"
#import "LMScrollView.h"

@interface LMPurchaseViewController () <LMButtonBarDelegate, LMPurchaseManagerDelegate, SKProductsRequestDelegate>

/**
 The root scroll view.
 */
@property LMScrollView *rootScrollView;

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
	
	switch(newOwnershipStatus){
		case LMPurchaseManagerAppOwnershipStatusInTrial:
		case LMPurchaseManagerAppOwnershipStatusTrialExpired:
			break;
		case LMPurchaseManagerAppOwnershipStatusPurchased:
		case LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker:
			NSLog(@"Was presented %d", self.wasPresented);
			if(self.wasPresented){
				NSLog(@"Dismissing");
				[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
			}
			else{
				NSLog(@"Popping");
				[(UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController popViewControllerAnimated:YES];
			}
			break;
	}
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
		case 0: {
			UIAlertController *alert = [UIAlertController
										alertControllerWithTitle:NSLocalizedString(@"OhBoy", nil)
										message:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"NoPurchasesYet", nil)]
										preferredStyle:UIAlertControllerStyleAlert];
			
			UIAlertAction *yesButton = [UIAlertAction
										actionWithTitle:NSLocalizedString(@"Okay", nil)
										style:UIAlertActionStyleDefault
										handler:nil];
			
			[alert addAction:yesButton];
			
			NSArray *viewArray = [[[[[[[[[[[[alert view] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews]; //lol
			//		UILabel *alertTitle = viewArray[0];
			UILabel *alertMessage = viewArray[1];
			alertMessage.textAlignment = NSTextAlignmentLeft;
			
			[self presentViewController:alert animated:YES completion:nil];
			
//			[self.purchaseManager makePurchaseWithProductIdentifier:LMPurchaseManagerProductIdentifierLifetimeMusic];
//			
//			self.pendingViewController = [UIAlertController alertControllerWithTitle:nil
//																			 message:[NSString stringWithFormat:@"%@\n\n\n", NSLocalizedString(@"HoldOn", nil)]
//																	  preferredStyle:UIAlertControllerStyleAlert];
//			UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//			indicator.color = [UIColor blackColor];
//			indicator.translatesAutoresizingMaskIntoConstraints = NO;
//			[self.pendingViewController.view addSubview:indicator];
//			NSDictionary * views = @{ @"pending": self.pendingViewController.view,
//									  @"indicator": indicator };
//			
//			NSArray *constraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[indicator]-(20)-|" options:0 metrics:nil views:views];
//			NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[indicator]|" options:0 metrics:nil views:views];
//			NSArray *constraints = [constraintsVertical arrayByAddingObjectsFromArray:constraintsHorizontal];
//			[self.pendingViewController.view addConstraints:constraints];
//			
//			[indicator setUserInteractionEnabled:NO];
//			[indicator startAnimating];
//			
//			[self presentViewController:self.pendingViewController animated:YES completion:nil];
			break;
		}
		case 1: { //Backer login
			LMBackerLoginViewController *backerLoginController = [LMBackerLoginViewController new];
			
			[self presentViewController:backerLoginController animated:YES completion:nil];
			break;
		}
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
	for(SKProduct *product in response.products){
//		[LMAnswers logAddToCartWithPrice:product.price
//								currency:product.priceLocale.currencyCode
//								itemName:@"Lifetime Music"
//								itemType:@"Essential"
//								  itemId:LMPurchaseManagerProductIdentifierLifetimeMusic
//						customAttributes:@{}];
	}
	
	if(response.products.count == 0){
		NSLog(@"[LMPurchaseManager]: No valid products available.");
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:LMPurchaseManagerProductIdentifierLifetimeMusic]];
	productsRequest.delegate = self;
	
	[productsRequest start];
	
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
	
	
	self.ownershipButtonBar = [LMButtonBar newAutoLayoutView];
	self.ownershipButtonBar.amountOfButtons = 2;
	self.ownershipButtonBar.buttonIconsArray = @[ @(LMIconBuy), @(LMIconKickstarter) ];
	self.ownershipButtonBar.buttonScaleFactorsArray = @[ @(0.85), @(1.0) ];
	self.ownershipButtonBar.delegate = self;
	self.ownershipButtonBar.backgroundColor = [UIColor whiteColor];
	self.ownershipButtonBar.layer.shadowColor = [UIColor blackColor].CGColor;
	self.ownershipButtonBar.layer.shadowRadius = WINDOW_FRAME.size.width/45;
	self.ownershipButtonBar.layer.shadowOpacity = 0.40f;
	[self.view addSubview:self.ownershipButtonBar];
	
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.ownershipButtonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.ownershipButtonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/8.0)];
	
	
	self.rootScrollView = [LMScrollView newAutoLayoutView];
//	self.rootScrollView.backgroundColor = [UIColor greenColor];
	self.rootScrollView.adaptForWidth = NO;
	[self.view addSubview:self.rootScrollView];
	
	[self.rootScrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootScrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.rootScrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.rootScrollView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.ownershipButtonBar];
	
	
	
	self.headerImageView = [UIImageView newAutoLayoutView];
	self.headerImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.headerImageView.image = [UIImage imageNamed:@"purchase_header.png"];
	[self.rootScrollView addSubview:self.headerImageView];
	
	[self.headerImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:15];
	[self.headerImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:15];
	[self.headerImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-15];
	[self.headerImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(3.75/10.0)];
	
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.text = NSLocalizedString(@"TrialTimeIsUpTitle", nil);
	self.titleLabel.textAlignment = NSTextAlignmentJustified;
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:(WINDOW_FRAME.size.width*0.0483)];
	self.titleLabel.numberOfLines = 0;
	[self.rootScrollView addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerImageView withOffset:20];
	[self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:15];
	[self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-15];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.text = NSLocalizedString(@"TrialTimeIsUpDescription", nil);
	self.descriptionLabel.textAlignment = NSTextAlignmentJustified;
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width*0.0437)];
	self.descriptionLabel.numberOfLines = 0;
	[self.view addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
	[self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:15];
	[self.descriptionLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-15];
	
	
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
		[self.rootScrollView addSubview:checkmarkView];
		
		[checkmarkView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:15];
		[checkmarkView autoSetDimension:ALDimensionHeight toSize:stringHeight];
		[checkmarkView autoSetDimension:ALDimensionWidth toSize:stringHeight];
		[checkmarkView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:firstView ? 20 : 10];
	
		
		UILabel *advantageLabel = [UILabel newAutoLayoutView];
		advantageLabel.text = appAdvantageString;
		advantageLabel.textAlignment = NSTextAlignmentLeft;
		advantageLabel.font = self.descriptionLabel.font;
		advantageLabel.numberOfLines = 0;
		[self.rootScrollView addSubview:advantageLabel];
		
		[advantageLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:checkmarkView];
		[advantageLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:checkmarkView withOffset:10];
		[advantageLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-15];
		[advantageLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		
		[advantagesLabelArray addObject:advantageLabel];
	}
	
	
	self.kickstarterBackerLabel = [UILabel newAutoLayoutView];
	self.kickstarterBackerLabel.text = NSLocalizedString(@"IfYoureAKickstarterBacker", nil);
	self.kickstarterBackerLabel.textAlignment = NSTextAlignmentJustified;
	self.kickstarterBackerLabel.font = self.descriptionLabel.font;
	self.kickstarterBackerLabel.numberOfLines = 0;
	[self.rootScrollView addSubview:self.kickstarterBackerLabel];
	
	[self.kickstarterBackerLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:15];
	[self.kickstarterBackerLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-15];
	[self.kickstarterBackerLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[advantagesLabelArray lastObject] withOffset:20];
	
	
//	[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//		LMBackerLoginViewController *backerLoginController = [LMBackerLoginViewController new];
//		
//		[self dismissViewControllerAnimated:YES completion:^{
//			[self presentViewController:backerLoginController animated:YES completion:nil];
//		}];
//	}];
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
