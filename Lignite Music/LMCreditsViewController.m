//
//  LMCreditsViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCreditsViewController.h"
#import "LMScrollView.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMExtras.h"

@interface LMCreditsViewController ()

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

@end

@implementation LMCreditsViewController

- (BOOL)prefersStatusBarHidden {
	return NO || [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)creditLinks {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.lignitemusic.com/licenses/"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.scrollView = [LMScrollView newAutoLayoutView];
	self.scrollView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.scrollView];
	
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44];
	
	
	self.philippAndEdwinView = [UIImageView newAutoLayoutView];
	self.philippAndEdwinView.image = [UIImage imageNamed:@"onboarding_us.png"];
	self.philippAndEdwinView.contentMode = UIViewContentModeScaleToFill;
	self.philippAndEdwinView.backgroundColor = [UIColor purpleColor];
	[self.scrollView addSubview:self.philippAndEdwinView];
	
	[self.philippAndEdwinView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.philippAndEdwinView autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width];
	[self.philippAndEdwinView autoSetDimension:ALDimensionHeight toSize:0.88*WINDOW_FRAME.size.width];
	
	
	//		self.signaturesView = [UIImageView newAutoLayoutView];
	//		self.signaturesView.image = [UIImage imageNamed:@"signatures.png"];
	//		self.signaturesView.contentMode = UIViewContentModeScaleToFill;
	//		[self.scrollView addSubview:self.signaturesView];
	//
	//		[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	//		[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-self.frame.size.width*0.10];
	//		float scaleFactor = 0.75;
	//		[self.signaturesView autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*scaleFactor];
	//		[self.signaturesView autoSetDimension:ALDimensionHeight toSize:self.frame.size.width*0.296*scaleFactor];
	
	
	self.thankYouLabel = [UILabel newAutoLayoutView];
	self.thankYouLabel.font = [UIFont fontWithName:@"HoneyScript-SemiBold" size:(WINDOW_FRAME.size.width/414.0)*75.0f];
	self.thankYouLabel.text = NSLocalizedString(@"ThankYou", nil);
	self.thankYouLabel.textAlignment = NSTextAlignmentCenter;
	[self.scrollView addSubview:self.thankYouLabel];
	
	[self.thankYouLabel autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width];
	[self.thankYouLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-WINDOW_FRAME.size.width*0.10];
	
	self.thanksForYourSupportLabel = [UILabel newAutoLayoutView];
	self.thanksForYourSupportLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width/414.0)*18.0f];
	self.thanksForYourSupportLabel.text = NSLocalizedString(@"ThankYouDescription", nil);
	self.thanksForYourSupportLabel.textAlignment = NSTextAlignmentLeft;
	self.thanksForYourSupportLabel.numberOfLines = 0;
	[self.scrollView addSubview:self.thanksForYourSupportLabel];
	
	[self.thanksForYourSupportLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.thanksForYourSupportLabel autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width*0.9];
	[self.thanksForYourSupportLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel withOffset:WINDOW_FRAME.size.width*0.05];
	
	
	self.signaturesView = [UIImageView newAutoLayoutView];
	self.signaturesView.image = [UIImage imageNamed:@"signatures.png"];
	self.signaturesView.contentMode = UIViewContentModeScaleToFill;
	[self.scrollView addSubview:self.signaturesView];
	
	[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thanksForYourSupportLabel withOffset:WINDOW_FRAME.size.width*0.05];
	float scaleFactor = 0.75;
	[self.signaturesView autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width*scaleFactor];
	[self.signaturesView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.width*0.296*scaleFactor];
	
	
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
						  
						  @"LibraryPebbleKit",
						  @"LibraryPebbleKitDescription",
						  
						  @"LibraryPureLayout",
						  @"LibraryPureLayoutDescription",
						  
						  @"LibraryMBProgressHUD",
						  @"LibraryMBProgressHUDDescription",
						  
						  @"LibraryMarqueeLabel",
						  @"LibraryMarqueeLabelDescription",
						  
						  @"LibraryReachability",
						  @"LibraryReachabilityDescription",
						  
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
		
		float actualFontSize = (WINDOW_FRAME.size.width/414.0)*fontSize;
		
		BOOL textFontIsBold = textFontIsBoldOptions[i];
		
		UILabel *textLabel = [UILabel newAutoLayoutView];
		textLabel.text = text;
		textLabel.font = [UIFont fontWithName:textFontIsBold ? @"HelveticaNeue-Bold" : @"HelveticaNeue-Light" size:actualFontSize];
		textLabel.numberOfLines = 0;
		textLabel.textAlignment = NSTextAlignmentLeft;
		[self.scrollView addSubview:textLabel];
		
		[textLabel autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width*0.90];
		[textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[textLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabelToAttachTo withOffset:WINDOW_FRAME.size.width*(i == 0 ? 0.10 : (fontSize == 30.0 ? 0.075 : 0.035))];
		
		[textLabelsArray addObject:textLabel];
	}
	
	UILabel *creditsLinkButton = [UILabel newAutoLayoutView];
	creditsLinkButton.text = NSLocalizedString(@"CreditsLicenses", nil);
	creditsLinkButton.textAlignment = NSTextAlignmentCenter;
	creditsLinkButton.numberOfLines = 0;
	creditsLinkButton.layer.masksToBounds = YES;
	creditsLinkButton.layer.cornerRadius = 10.0;
	creditsLinkButton.backgroundColor = [LMColour ligniteRedColour];
	creditsLinkButton.textColor = [UIColor whiteColor];
	creditsLinkButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
	creditsLinkButton.userInteractionEnabled = YES;
	[self.scrollView addSubview:creditsLinkButton];
	
	[creditsLinkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[textLabelsArray lastObject] withOffset:20];
	[creditsLinkButton autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width * 0.9];
	[creditsLinkButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[creditsLinkButton autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/8.0];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(creditLinks)];
	[creditsLinkButton addGestureRecognizer:tapGesture];
	
    // Do any additional setup after loading the view.
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
