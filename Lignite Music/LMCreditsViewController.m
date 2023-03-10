//
//  LMCreditsViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCreditsViewController.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMScrollView.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMExtras.h"

#define LMCreditsScrollViewContentOffsetYKey @"LMCreditsScrollViewContentOffsetYKey"

@interface LMCreditsViewController ()<UIScrollViewDelegate, LMLayoutChangeDelegate, UIViewControllerRestoration>

/**
 Whether or not constraints have been setup yet.
 */
@property BOOL didSetupConstraints;

/**
 The root scroll view of the credits view.
 */
@property LMScrollView *scrollView;

/**
 The image view for Philipp and I's photo together :)
 */
@property UIImageView *philippAndEdwinView;

/**
 The constraint of the height for the philippAndEdwinView.
 */
@property NSLayoutConstraint *philippAndEdwinViewHeightConstraint;

/**
 The big "Thank you!" title label.
 */
@property UILabel *thankYouLabel;

/**
 The thanks for your support description label.
 */
@property UILabel *thanksForYourSupportLabel;

/**
 The signatures view which goes above the thank you label.
 */
@property UIImageView *signaturesView;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The content offset for the Y axis of the scroll view that was preserved for state restoration.
 */
@property CGFloat preservedContentOffsetY;

@end

@implementation LMCreditsViewController

- (instancetype)init {
	self = [super init];
	if(self) {
		self.restorationIdentifier = [[LMCreditsViewController class] description];
		self.restorationClass = [LMCreditsViewController class];
	}
	return self;
}

- (UINavigationItem*)navigationItem {
	UINavigationItem *navigationItem = [super navigationItem];
	
	navigationItem.title = NSLocalizedString(@"Credits", nil);
	
	return navigationItem;
}

+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	return [LMCreditsViewController new];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[coder encodeFloat:self.scrollView.contentOffset.y forKey:LMCreditsScrollViewContentOffsetYKey];
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	self.preservedContentOffsetY = [coder decodeFloatForKey:LMCreditsScrollViewContentOffsetYKey];
	
	self.scrollView.preservedContentOffset = CGPointMake(0, self.preservedContentOffsetY);
	
	NSLog(@"Good %@", NSStringFromCGPoint(self.scrollView.contentOffset));
	
	[super decodeRestorableStateWithCoder:coder];
}

- (BOOL)prefersStatusBarHidden {
	return NO || [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)creditLinks {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.LigniteMusic.com/licences/"] options:@{} completionHandler:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	[self.layoutManager adjustRootViewSubviewsForLandscapeNavigationBar:self.view];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscapeAnyPlatform = size.width > size.height;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		self.philippAndEdwinViewHeightConstraint.constant = willBeLandscapeAnyPlatform ? 0 : WINDOW_FRAME.size.width*0.88;
		self.scrollView.contentInset = UIEdgeInsetsMake([LMLayoutManager isiPad] && [LMLayoutManager isLandscapeiPad] ? 70 : 0, 0, 0, 0);
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			if([LMLayoutManager isiPhoneX]){
				[self notchPositionChanged:LMLayoutManager.notchPosition];
			}
			
			[self.scrollView reload];
			self.scrollView.delegate = self;
		} repeats:NO];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	BOOL isLandscape = [LMLayoutManager isLandscape];
	CGFloat mainDimension = isLandscape ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width;
	
	self.scrollView = [LMScrollView newAutoLayoutView];
	self.scrollView.backgroundColor = [UIColor whiteColor];
	self.scrollView.showsVerticalScrollIndicator = YES;
	self.scrollView.delegate = self;
	self.scrollView.restorationIdentifier = @"LMCreditsScrollView";
	self.scrollView.contentInset = UIEdgeInsetsMake([LMLayoutManager isiPad] && [LMLayoutManager isLandscapeiPad] ? 70 : 0, 0, 0, 0);
	[self.view addSubview:self.scrollView];
	
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	NSArray *scrollViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewPortraitConstraints:scrollViewPortraitConstraints];
	
	NSArray *scrollViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewLandscapeConstraints:scrollViewLandscapeConstraints];
	
	self.philippAndEdwinView = [UIImageView newAutoLayoutView];
	self.philippAndEdwinView.image = [UIImage imageNamed:@"onboarding_us"];
	self.philippAndEdwinView.contentMode = UIViewContentModeScaleToFill;
	self.philippAndEdwinView.backgroundColor = [UIColor purpleColor];
	[self.scrollView addSubview:self.philippAndEdwinView];
	
	[self.philippAndEdwinView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//	[self.philippAndEdwinView autoSetDimension:ALDimensionWidth toSize:mainDimension];
	[self.philippAndEdwinView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView];
	self.philippAndEdwinViewHeightConstraint = [self.philippAndEdwinView autoSetDimension:ALDimensionHeight toSize:0.88*mainDimension];

	if([LMLayoutManager isLandscape] || [LMLayoutManager isLandscapeiPad]){
		self.philippAndEdwinViewHeightConstraint.constant = 0;
	}
	
	
	//		self.signaturesView = [UIImageView newAutoLayoutView];
	//		self.signaturesView.image = [UIImage imageNamed:@"signatures"];
	//		self.signaturesView.contentMode = UIViewContentModeScaleToFill;
	//		[self.scrollView addSubview:self.signaturesView];
	//
	//		[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	//		[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-self.frame.size.width*0.10];
	//		float scaleFactor = 0.75;
	//		[self.signaturesView autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*scaleFactor];
	//		[self.signaturesView autoSetDimension:ALDimensionHeight toSize:self.frame.size.width*0.296*scaleFactor];
	
	
	if(mainDimension > 450){
		mainDimension = 450;
	}
	
	
	self.thankYouLabel = [UILabel newAutoLayoutView];
	self.thankYouLabel.font = [UIFont fontWithName:@"HoneyScript-SemiBold" size:(mainDimension/414.0)*75.0f];
	self.thankYouLabel.text = NSLocalizedString(@"ThankYou", nil);
	self.thankYouLabel.textAlignment = NSTextAlignmentCenter;
	[self.scrollView addSubview:self.thankYouLabel];
	
	[self.thankYouLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
//	[self.thankYouLabel autoSetDimension:ALDimensionWidth toSize:mainDimension];
	[self.thankYouLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView];
	NSArray *thankYouLabelPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.thankYouLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-mainDimension*0.10];
	}];
	[LMLayoutManager addNewPortraitConstraints:thankYouLabelPortraitConstraints];
	
	NSArray *thankYouLabelLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.thankYouLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:mainDimension*0.10];
	}];
	[LMLayoutManager addNewLandscapeConstraints:thankYouLabelLandscapeConstraints];
	
	
	self.thanksForYourSupportLabel = [UILabel newAutoLayoutView];
	self.thanksForYourSupportLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(mainDimension/414.0)*18.0f];
	self.thanksForYourSupportLabel.text = NSLocalizedString(@"ThankYouDescription", nil);
	self.thanksForYourSupportLabel.textAlignment = NSTextAlignmentLeft;
	self.thanksForYourSupportLabel.numberOfLines = 0;
	[self.scrollView addSubview:self.thanksForYourSupportLabel];
	
	[self.thanksForYourSupportLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.thanksForYourSupportLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView withMultiplier:0.9];
	[self.thanksForYourSupportLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel withOffset:mainDimension*0.05];
	
	
	self.signaturesView = [UIImageView newAutoLayoutView];
	self.signaturesView.image = [UIImage imageNamed:@"signatures"];
	self.signaturesView.contentMode = UIViewContentModeScaleToFill;
	[self.scrollView addSubview:self.signaturesView];
	
	[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thanksForYourSupportLabel withOffset:mainDimension*0.05];
	float scaleFactor = 0.75;
	[self.signaturesView autoSetDimension:ALDimensionWidth toSize:mainDimension*scaleFactor];
	[self.signaturesView autoSetDimension:ALDimensionHeight toSize:mainDimension*0.296*scaleFactor];
	
	
	NSMutableArray *textLabelsArray = [NSMutableArray new];
	
	NSArray *textKeys = @[
						  @"KickstarterBackers",
						  
						  @"RankLigniteLover",
						  @"RankLigniteLoverPeople",
						  
						  @"RankSuperSupporters",
						  @"RankSuperSupportersPeople",
						  
						  @"RankLigniteMusicInfluencers",
						  @"RankLigniteMusicInfluencersPeople",
						  
						  @"RankBetaAccess",
						  @"RankBetaAccessPeople",
						  
						  @"RankEarlyBird",
						  @"RankEarlyBirdPeople",
						  
						  @"RankSuperEarlyBird",
						  @"RankSuperEarlyBirdPeople",
						  
						  @"RankLigniteSupporter",
						  @"RankLigniteSupporterPeople",
						  
						  @"ImageAPI",
						  @"ImageAPIDescription",
						  
						  @"OpenSourceLibraries",
						  @"OpenSourceLibrariesLicensing",
						  
						  @"LibraryYYImage",
						  @"LibraryYYImageDescription",
						  
						  @"LibrarySDWebImage",
						  @"LibrarySDWebImageDescription",
						  
						  @"LibraryImageMagick",
						  @"LibraryImageMagickDescription",
						  
						  @"LibraryPureLayout",
						  @"LibraryPureLayoutDescription",
						  
						  @"LibraryMBProgressHUD",
						  @"LibraryMBProgressHUDDescription",
						  
						  @"LibraryMarqueeLabel",
						  @"LibraryMarqueeLabelDescription",
						  
						  @"LibraryReachability",
						  @"LibraryReachabilityDescription",
						  
						  @"LibraryUnirest",
						  @"LibraryUnirestDescription",
						  
						  @"LibraryMGSwipeTableCell",
						  @"LibraryMGSwipeTableCellDescription",
						  
						  @"LibraryRSKImageCropper",
						  @"LibraryRSKImageCropperDescription",
						  
						  @"LibraryBEMCheckBox",
						  @"LibraryBEMCheckBoxDescription",
						  
						  @"LibraryPeekPop",
						  @"LibraryPeekPopDescription",
						  
						  @"LibraryXCDYouTubeKit",
						  @"LibraryXCDYouTubeKitDescription",
						  
						  
						  @"Icons",
						  @"IconsDescription"
						  ];
	float textFontSizes[] = {
		30.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		30.0,
		18.0,
		
		30.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		18.0,
		18.0,
		
		30.0,
		18.0
	};
	BOOL textFontIsBoldOptions[] = {
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		NO,
		NO,
		
		NO,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		YES,
		NO,
		
		NO,
		NO
	};
	
	//I would comment this better but honestly we don't have time
	
	//Goes through and detects which artists have icons and creates a row of icons
	//Does not adapt for more than 8 in a row
	
	for(int i = 0; i < textKeys.count; i++){
		BOOL isFirst = (i == 0);
		
		UILabel *previousLabelToAttachTo = isFirst ? self.signaturesView : [textLabelsArray lastObject];
		
		NSString *text = NSLocalizedString([textKeys objectAtIndex:i], nil);
		float fontSize = textFontSizes[i];
		
		float actualFontSize = (mainDimension/414.0)*fontSize;
		
		BOOL textFontIsBold = textFontIsBoldOptions[i];
		
		UILabel *textLabel = [UILabel newAutoLayoutView];
		textLabel.text = text;
		textLabel.font = [UIFont fontWithName:textFontIsBold ? @"HelveticaNeue-Bold" : @"HelveticaNeue-Light" size:actualFontSize];
		textLabel.numberOfLines = 0;
		textLabel.textAlignment = NSTextAlignmentLeft;
		[self.scrollView addSubview:textLabel];
		
		[textLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView withMultiplier:0.9];
		[textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[textLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabelToAttachTo withOffset:mainDimension*(i == 0 ? 0.10 : (fontSize == 30.0 ? 0.075 : 0.035))];
		
		[textLabelsArray addObject:textLabel];
	}
	
	UILabel *creditsLinkButton = [UILabel newAutoLayoutView];
	creditsLinkButton.text = NSLocalizedString(@"CreditsLicenses", nil);
	creditsLinkButton.textAlignment = NSTextAlignmentCenter;
	creditsLinkButton.numberOfLines = 0;
	creditsLinkButton.backgroundColor = [LMColour mainColour];
	creditsLinkButton.textColor = [UIColor whiteColor];
	creditsLinkButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
	creditsLinkButton.userInteractionEnabled = YES;
	creditsLinkButton.layer.masksToBounds = YES;
	creditsLinkButton.layer.cornerRadius = 8.0f;
	creditsLinkButton.isAccessibilityElement = YES;
	creditsLinkButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_LicenseLinksButton", nil);
	creditsLinkButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_LicenseLinksButton", nil);
	[self.scrollView addSubview:creditsLinkButton];
	
	[creditsLinkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[textLabelsArray lastObject] withOffset:20];
	[creditsLinkButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView withMultiplier:0.9];
	[creditsLinkButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[creditsLinkButton autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/LMLayoutManager.listEntryHeightFactorial];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(creditLinks)];
	[creditsLinkButton addGestureRecognizer:tapGesture];
	
	if([LMLayoutManager isiPhoneX]){
		[self notchPositionChanged:LMLayoutManager.notchPosition];
	}
}

- (void)dealloc {
	[LMLayoutManager removeAllConstraintsRelatedToView:self.philippAndEdwinView];
	[LMLayoutManager removeAllConstraintsRelatedToView:self.thankYouLabel];
	[LMLayoutManager removeAllConstraintsRelatedToView:self.scrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
