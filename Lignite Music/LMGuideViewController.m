//
//  LNTutorialViewController.m
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <PebbleKit/PebbleKit.h>
#import <PureLayout/PureLayout.h>
#import "LMGuideViewController.h"
#import "LMGuideViewPagerController.h"
#import "LMColour.h"
#import "LMSettings.h"

@import StoreKit;

@interface LMGuideViewController ()

@property UILabel *titleLabel, *descriptionLabel;
@property UIImageView *screenshotView, *iconView;

@property UIView *buttonArea;
@property UIButton *finishedButton;
@property UIButton *secondaryButton;

@property UIPageControl *pageControl;

@property BOOL checkComplete;

@property int triesToAcceptPermission;

@end

@implementation LMGuideViewController

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)threeBlindMice {
	NSLog(@"Some called the three blind mice");
	
	[self.sourcePagerController setViewControllers:@[self.nextViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
		//Done
	}];
}

- (void)dismissViewController {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)performOnboardingAction {
	switch(self.guideMode){
		case GuideModeOnboarding: {
			
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
						
						NSString *buttonTitleToSet = @"ButtonTitle";
						
						switch(status){
							case SKCloudServiceAuthorizationStatusNotDetermined: {
								//Cannot be determined?
								buttonTitleToSet = @"Error";
								break;
							}
							case SKCloudServiceAuthorizationStatusDenied: {
								//Launch tutorial on how to fix
								buttonTitleToSet = @"OuchDenied";
								
								dispatch_async(dispatch_get_main_queue(), ^{
									LMGuideViewPagerController *guideViewPager = [LMGuideViewPagerController new];
									guideViewPager.guideMode = GuideModeMusicPermissionDenied;
									[self presentViewController:guideViewPager animated:YES completion:nil];
								});
								break;
							}
							case SKCloudServiceAuthorizationStatusRestricted: {
								//Device might be in education mode or something
								buttonTitleToSet = @"Restricted";
								break;
							}
							case SKCloudServiceAuthorizationStatusAuthorized: {
								buttonTitleToSet = @"Checking";
								
								SKCloudServiceController *cloudServiceController;
								cloudServiceController = [SKCloudServiceController new];
								
								[cloudServiceController requestCapabilitiesWithCompletionHandler:^(SKCloudServiceCapability capabilities, NSError * _Nullable error) {
									
									dispatch_async(dispatch_get_main_queue(), ^{
										if (capabilities >= SKCloudServiceCapabilityAddToCloudMusicLibrary){
											NSLog(@"You CAN add to iCloud!");
										}
										else {
											NSLog(@"Windows error!!");
										}
										
										[self.finishedButton setTitle:NSLocalizedString(@"GoodToGo", nil) forState:UIControlStateNormal];
										[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(threeBlindMice) userInfo:nil repeats:NO];
									});
								}];
								
								break;
							}
						}
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.finishedButton setTitle:NSLocalizedString(buttonTitleToSet, nil) forState:UIControlStateNormal];
						});
					}];
					break;
				}
				case 2: {
					NSLog(@"Creating");
					//			CBCentralManager *centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
					//			CBPeripheralManager *peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
					PBPebbleCentral *central = [PBPebbleCentral defaultCentral];
					central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
					[central run];
					//			NSLog(@"Current state %d", (int)[peripheralManager state]);
					NSLog(@"Created.");
					for (NSUInteger index = 0; index < 20; index++) {
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(index * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
							if(self.checkComplete) {
								return;
							}
							
							CBPeripheralManagerAuthorizationStatus status = [CBPeripheralManager authorizationStatus];
							if (status == CBPeripheralManagerAuthorizationStatusNotDetermined) {
								[self.finishedButton setTitle:NSLocalizedString(@"Checking", nil) forState:UIControlStateNormal];
							}
							else if (status == CBPeripheralManagerAuthorizationStatusAuthorized) {
								[self.finishedButton setTitle:NSLocalizedString(@"AllSetHere", nil) forState:UIControlStateNormal];
							}
							else if (status == CBPeripheralManagerAuthorizationStatusDenied) {
								[self.finishedButton setTitle:NSLocalizedString(@"OuchDenied", nil) forState:UIControlStateNormal];
							}
							else if (status == CBPeripheralManagerAuthorizationStatusRestricted) {
								[self.finishedButton setTitle:NSLocalizedString(@"Restricted", nil) forState:UIControlStateNormal];
							}
							
							if(status != CBPeripheralManagerAuthorizationStatusNotDetermined) {
								self.checkComplete = YES;
								[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(threeBlindMice) userInfo:nil repeats:NO];
							}
						});
					}
					//Pebble permission
					break;
				}
				case 3: {
					//Tutorial launch
//					[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
					[self threeBlindMice];
					
					LMGuideViewPagerController *guideViewPager = [LMGuideViewPagerController new];
					guideViewPager.guideMode = GuideModeTutorial;
					[self presentViewController:guideViewPager animated:YES completion:nil];
					break;
				}
				case 4: {
					NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
					[userDefaults setObject:@"tutorialVersion1" forKey:LMSettingsKeyOnboardingComplete];
					[userDefaults synchronize];
					
					[self.coreViewController prepareToLoadView];
					[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
					break;
				}
			}
			
			break;
		}
		case GuideModeTutorial: {
			if(self.index == 3){
				[self dismissViewControllerAnimated:YES completion:nil];
			}
			else{
				[self threeBlindMice];
			}
			break;
		}
		case GuideModeMusicPermissionDenied: {
			[self.finishedButton setTitle:NSLocalizedString(@"Checking", nil) forState:UIControlStateNormal];
			SKCloudServiceController *cloudServiceController;
			cloudServiceController = [SKCloudServiceController new];
			
			[cloudServiceController requestCapabilitiesWithCompletionHandler:^(SKCloudServiceCapability capabilities, NSError * _Nullable error) {
				NSLog(@"%lu %@", (unsigned long)capabilities, error ? error : @"(No error)");
				
				if (capabilities >= SKCloudServiceCapabilityAddToCloudMusicLibrary){
					NSLog(@"You CAN add to iCloud!");
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.finishedButton setTitle:NSLocalizedString(@"GoodToGo", nil) forState:UIControlStateNormal];
						[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissViewController) userInfo:nil repeats:NO];
					});
					
					//Continue to next
				}
				else {
					//Shove the music permission down their throat
					self.triesToAcceptPermission++;
					[self.finishedButton setTitle:NSLocalizedString(@"TapToTryAgain", nil) forState:UIControlStateNormal];
					
					if(self.triesToAcceptPermission > 1){
						UIAlertController *alert = [UIAlertController
													alertControllerWithTitle:NSLocalizedString(@"StillCantAccessMusicTitle", nil)
													message:NSLocalizedString(@"StillCantAccessMusicDescription", nil)
													preferredStyle:UIAlertControllerStyleAlert];
						
						UIAlertAction *yesButton = [UIAlertAction
													actionWithTitle:NSLocalizedString(@"ContactUs", nil)
													style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) {
														NSLog(@"Contact");
														
														dispatch_async(dispatch_get_main_queue(), ^{
															NSString *recipients = [NSString stringWithFormat:@"mailto:contact@lignite.io?subject=%@&body=%@",
																					[@"Lignite Music can't access music library" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
																					[@"Hey guys,\n\nLignite Music can't access my music library for some reason. Please help!" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
//															recipients = [recipients stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
															NSLog(@"Can open %@ %d", recipients, [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:recipients]]);
															
															[[UIApplication sharedApplication] openURL:[NSURL URLWithString:recipients] options:@{} completionHandler:^(BOOL success) {
																NSLog(@"Done %d", success);
															}];
														});
													}];
						
						UIAlertAction *nopeButton = [UIAlertAction
													actionWithTitle:NSLocalizedString(@"DoNothing", nil)
													style:UIAlertActionStyleCancel
													handler:^(UIAlertAction *action) {
														
													}];
						
						[alert addAction:yesButton];
						[alert addAction:nopeButton];
						
						[self presentViewController:alert animated:YES completion:nil];
					}
				}
			}];
			
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

- (void)secondaryAction {
	if(self.guideMode == GuideModeTutorial){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"pebble://appstore/579c3ee922f599cf7e0001ea"]];
		
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else{
		[self threeBlindMice];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	

	self.buttonArea = [UIView newAutoLayoutView];
	[self.view addSubview:self.buttonArea];
	
	[self.buttonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.view.frame.size.height/30.0];
	[self.buttonArea autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.buttonArea autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.buttonArea autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.buttonArea autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/16.0)];
	
	self.finishedButton = [UIButton newAutoLayoutView];
	self.finishedButton.backgroundColor = [LMColour ligniteRedColour];
	self.finishedButton.titleLabel.textColor = [UIColor whiteColor];
	self.finishedButton.layer.masksToBounds = YES;
	self.finishedButton.layer.cornerRadius = 6;
	[self.finishedButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
	[self.finishedButton addTarget:self action:@selector(performOnboardingAction) forControlEvents:UIControlEventTouchUpInside];
	[self.finishedButton setTitle:self.buttonTitle forState:UIControlStateNormal];
	
	if((self.guideMode == GuideModeTutorial && self.index == 3) || (self.guideMode == GuideModeOnboarding && self.index == 3)){ //Pebble screen
		UIView *firstButtonArea = [UIView newAutoLayoutView];
//		firstButtonArea.backgroundColor = [UIColor redColor];
		[self.buttonArea addSubview:firstButtonArea];
		
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[firstButtonArea autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonArea withMultiplier:(1.0/2.0)];
		
		self.secondaryButton = [UIButton newAutoLayoutView];
		self.secondaryButton.backgroundColor = [LMColour ligniteRedColour];
		self.secondaryButton.titleLabel.textColor = [UIColor whiteColor];
		self.secondaryButton.layer.masksToBounds = YES;
		self.secondaryButton.layer.cornerRadius = 6;
		[self.secondaryButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
		[self.secondaryButton addTarget:self action:@selector(secondaryAction) forControlEvents:UIControlEventTouchUpInside];
		[self.secondaryButton setTitle:NSLocalizedString(self.guideMode == GuideModeOnboarding ? @"SkipTutorial" : @"Install", nil) forState:UIControlStateNormal];
		
		[firstButtonArea addSubview:self.secondaryButton];
		
		[self.secondaryButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
		[self.secondaryButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.secondaryButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.secondaryButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
		
		
		UIView *secondButtonArea = [UIView newAutoLayoutView];
//		secondButtonArea.backgroundColor = [UIColor orangeColor];
		[self.buttonArea addSubview:secondButtonArea];
		
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[secondButtonArea autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonArea withMultiplier:(1.0/2.0)];
		
		[secondButtonArea addSubview:self.finishedButton];
		
		[self.finishedButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.finishedButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	}
	else{
		[self.buttonArea addSubview:self.finishedButton];
		
		[self.finishedButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.finishedButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	}
	
	
	self.pageControl = [UIPageControl newAutoLayoutView];
	self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
	self.pageControl.numberOfPages = self.amountOfPages;
	self.pageControl.currentPage = self.index;
	self.pageControl.currentPageIndicatorTintColor = [LMColour ligniteRedColour];
	self.pageControl.hidesForSinglePage = YES;
//	self.pageControl.backgroundColor = [UIColor redColor];
	[self.view addSubview: self.pageControl];
	
	[self.pageControl autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonArea];
	[self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.pageControl autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:self.amountOfPages == 1 ? (1.0/25.0) : (1.0/10.0)];
	
	
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
	self.screenshotView.contentMode = (self.guideMode == GuideModeOnboarding && self.index == 4) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
	self.screenshotView.image = self.screenshotImage;
	[self.view addSubview:self.screenshotView];
	
	[self.screenshotView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel withOffset:-10];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.screenshotView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	
	[self.view insertSubview:self.titleLabel aboveSubview:self.screenshotView];
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
