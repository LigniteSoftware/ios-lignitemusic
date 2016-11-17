//
//  LNTutorialViewController.m
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTutorialViewController.h"
#import "LMTutorialViewPagerController.h"
#import "LMColour.h"

@interface LMTutorialViewController ()

@property UILabel *titleLabel, *descriptionLabel;
@property UIImageView *screenshotView, *iconView;
@property UIButton *finishedButton;

@end

@implementation LMTutorialViewController

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)finishTutorial {
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
	//UIGraphicsBeginImageContext(newSize);
	// In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
	// Pass 1.0 to force exact pixel size.
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.finishedButton = [UIButton newAutoLayoutView];
	self.finishedButton.backgroundColor = [LMColour ligniteRedColour];
	self.finishedButton.titleLabel.textColor = [UIColor whiteColor];
	self.finishedButton.layer.masksToBounds = YES;
	self.finishedButton.layer.cornerRadius = 6;
	[self.finishedButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
	[self.finishedButton addTarget:self action:@selector(finishTutorial) forControlEvents:UIControlEventTouchUpInside];
	[self.finishedButton setTitle:self.buttonTitle forState:UIControlStateNormal];
	[self.view addSubview:self.finishedButton];
	
	[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.finishedButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.finishedButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/20.0)];
	[self.finishedButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/3.0)];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
	self.descriptionLabel.numberOfLines = 0;
//	self.descriptionLabel.backgroundColor = [UIColor yellowColor];
	self.descriptionLabel.text = self.contentDescription;
	[self.view addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.finishedButton withOffset:-self.view.frame.size.height/15.0];
	[self.descriptionLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.descriptionLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(8.0/10.0)];
	[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
		[self.descriptionLabel autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
	}];
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:26.0f];
	self.titleLabel.numberOfLines = 0;
//	self.titleLabel.backgroundColor = [UIColor orangeColor];
	self.titleLabel.text = self.contentTitle;
	[self.view addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.descriptionLabel withOffset:-20];
	[self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.titleLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(8.0/10.0)];
	[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
		[self.titleLabel autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
	}];
	
	self.screenshotView = [UIImageView newAutoLayoutView];
//	self.screenshotView.backgroundColor = [UIColor redColor];
	self.screenshotView.contentMode = UIViewContentModeScaleAspectFit;
	self.screenshotView.image = self.screenshotImage;
	[self.view addSubview:self.screenshotView];
	
	[self.screenshotView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel withOffset:-10];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	
//	self.finishedButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/4, self.view.frame.size.height-80, self.view.frame.size.width/2, 34)];
//	self.finishedButton.backgroundColor = [UIColor darkGrayColor];
//	self.finishedButton.titleLabel.textColor = [UIColor whiteColor];
//	self.finishedButton.layer.masksToBounds = YES;
//	self.finishedButton.layer.cornerRadius = 4;
//	[self.finishedButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
//	[self.finishedButton addTarget:self action:@selector(finishTutorial) forControlEvents:UIControlEventTouchUpInside];
//	[self.finishedButton setTitle:NSLocalizedString(@"tutorial_alright_done", nil) forState:UIControlStateNormal];
//	[self.view addSubview:self.finishedButton];
//	
//	int descriptionOriginY = self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height-10;
//	self.descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, descriptionOriginY, self.view.frame.size.width-60, self.view.frame.size.height-descriptionOriginY-80)];
//	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
//	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
//	self.descriptionLabel.numberOfLines = 0;
//	self.descriptionLabel.text = self.contentDescription;
//	[self.view addSubview:self.descriptionLabel];
//	
//	CGRect labelRect = [self.descriptionLabel.text
//						boundingRectWithSize:CGSizeMake(self.view.frame.size.width-80, self.view.frame.size.height/2)
//						options:NSStringDrawingUsesLineFragmentOrigin
//						attributes:@{ NSFontAttributeName : self.descriptionLabel.font }
//						context:nil];
//	
//	labelRect.size.height += 30;
//	labelRect.origin.x = 40;
//	labelRect.origin.y = self.finishedButton.frame.origin.y-labelRect.size.height-20;
//	
//	self.descriptionLabel.frame = labelRect;
//	
//	self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, self.descriptionLabel.frame.origin.y-40, self.view.frame.size.width-20, 30)];
//	self.titleLabel.textAlignment = NSTextAlignmentCenter;
//	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:26.0f];
//	self.titleLabel.numberOfLines = 0;
//	self.titleLabel.text = self.contentTitle;
//	[self.view addSubview:self.titleLabel];
//	
//	self.iconView = [[UIImageView alloc]initWithFrame:CGRectMake(10, self.titleLabel.frame.origin.y-90, self.view.frame.size.width-20, 70)];
//	self.iconView.contentMode = UIViewContentModeScaleAspectFit;
//	self.iconView.image = self.gestureImage;
//	[self.view addSubview:self.iconView];
//	
//	self.screenshotViewHeight = self.iconView.frame.origin.y+40;
//	self.screenshotView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.forcedScreenshotHeight)];
//	self.screenshotView.contentMode = UIViewContentModeScaleAspectFit;
//	self.screenshotView.image = self.screenshotImage;
//	[self.view addSubview:self.screenshotView];
//	
//	CALayer *imageViewLayer = self.screenshotView.layer;
//	CAGradientLayer *maskLayer = [CAGradientLayer layer];
//	maskLayer.colors = @[ (id)([UIColor blackColor].CGColor), (id)([UIColor clearColor].CGColor) ]; // gradient from 100% opacity to 0% opacity (non-alpha components of the color are ignored)
//	// startPoint and endPoint (used to position/size the gradient) are in a coordinate space from the top left to bottom right of the layer: (0,0)–(1,1)
//	maskLayer.startPoint = CGPointMake(0, 0.4); //top left
//	maskLayer.endPoint = CGPointMake(0, 0.9); // bottom right
//	maskLayer.frame = imageViewLayer.bounds; // line it up with the layer it’s masking
//	imageViewLayer.mask = maskLayer;
//	
//	if(self.index == AMOUNT_OF_TUTORIAL_SCREENS-1){
//		self.screenshotView.frame = CGRectMake(self.screenshotView.frame.origin.x, 0, self.screenshotView.frame.size.width, self.screenshotView.frame.size.height);
//		self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.screenshotView.frame.origin.y+self.screenshotView.frame.size.height- 20, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
//		self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x, self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+10, self.descriptionLabel.frame.size.width, self.descriptionLabel.frame.size.height);
//		self.iconView.frame = CGRectMake(self.iconView.frame.origin.x, self.descriptionLabel.frame.origin.y+self.descriptionLabel.frame.size.height+10, self.iconView.frame.size.width, self.iconView.frame.size.height);
//		
//		float percent = self.view.frame.size.width/self.screenshotImage.size.width;
//		NSLog(@"Tutorial view frame %@, image view size %@\npercent %f, new height %f", NSStringFromCGRect(self.view.frame), NSStringFromCGSize(self.screenshotImage.size), percent, percent*self.screenshotImage.size.height);
//		self.screenshotView.frame = CGRectMake(0, 0, self.screenshotView.frame.size.width, percent*self.screenshotImage.size.height);
//	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
