//
//  LNTutorialViewController.m
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <PebbleKit/PebbleKit.h>
#import <PureLayout/PureLayout.h>
#import "LMTutorialViewController.h"
#import "LMTutorialViewPagerController.h"
#import "LMColour.h"

@import StoreKit;

@interface LMTutorialViewController ()

@property UILabel *titleLabel, *descriptionLabel;
@property UIImageView *screenshotView, *iconView;
@property UIButton *finishedButton;

@property UIPageControl *pageControl;

@end

@implementation LMTutorialViewController

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)threeBlindMice {
	[self.sourcePagerController setViewControllers:@[self.nextViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
		//Done
	}];
}

- (void)performOnboardingAction {
	switch(self.index){
		case 0: {
			//Go to next slide
			[self threeBlindMice];
			break;
		}
//		case 1: {
//			//Kickstarter backer login
//			break;
//		}
		case 1: {
			[self.finishedButton setTitle:NSLocalizedString(@"Checking", nil) forState:UIControlStateNormal];
			
			[SKCloudServiceController requestAuthorization:^(SKCloudServiceAuthorizationStatus status) {
				NSLog(@"Status is %ld", (long)status);
				
				SKCloudServiceController *cloudServiceController;
				cloudServiceController = [SKCloudServiceController new];
				
				[cloudServiceController requestCapabilitiesWithCompletionHandler:^(SKCloudServiceCapability capabilities, NSError * _Nullable error) {
					NSLog(@"%lu %@", (unsigned long)capabilities, error ? error : @"(No error)");
					
					if (capabilities >= SKCloudServiceCapabilityAddToCloudMusicLibrary){
						NSLog(@"You CAN add to iCloud!");
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.finishedButton setTitle:NSLocalizedString(@"GoodToGo", nil) forState:UIControlStateNormal];
							[self threeBlindMice];
						});
						
						//Continue to next
					}
					else {
						//Shove the music permission down their throat
						
						[self.finishedButton setTitle:NSLocalizedString(@"OhBoy", nil) forState:UIControlStateNormal];
					}
				}];
			}];
			break;
		}
		case 2: {
			PBPebbleCentral *central = [PBPebbleCentral defaultCentral];
			
			central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
			
			[central run];
			
			[self threeBlindMice];
			
			//Skip to next
			break;
		}
		case 3: {
			//Tutorial launch
			[self threeBlindMice];
			break;
		}
		case 4: {
			[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
			break;
		}
	}
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
	[self.finishedButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
	[self.finishedButton addTarget:self action:@selector(performOnboardingAction) forControlEvents:UIControlEventTouchUpInside];
	[self.finishedButton setTitle:self.buttonTitle forState:UIControlStateNormal];
	[self.view addSubview:self.finishedButton];
	
	[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.view.frame.size.height/30.0];
	[self.finishedButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.finishedButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/17.5)];
	[self.finishedButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
	
	
	self.pageControl = [UIPageControl newAutoLayoutView];
	self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
	self.pageControl.numberOfPages = 5;
	self.pageControl.currentPage = self.index;
	self.pageControl.currentPageIndicatorTintColor = [LMColour ligniteRedColour];
//	self.pageControl.backgroundColor = [UIColor redColor];
	[self.view addSubview: self.pageControl];
	
	[self.pageControl autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.finishedButton];
	[self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.pageControl autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/10.0)];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
	self.descriptionLabel.numberOfLines = 0;
//	self.descriptionLabel.backgroundColor = [UIColor yellowColor];
	self.descriptionLabel.text = self.contentDescription;
	[self.view addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.pageControl];
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
