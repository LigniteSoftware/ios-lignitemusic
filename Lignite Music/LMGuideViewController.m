//
//  LNTutorialViewController.m
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMGuideViewPagerController.h"
#import "LMGuideViewController.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMSettings.h"
#import "LMAnswers.h"
#import "LMColour.h"
#ifdef SPOTIFY
#import "Spotify.h"
#endif

@import StoreKit;

@interface LMGuideViewController ()<LMLayoutChangeDelegate>
#ifdef SPOTIFY
<SpotifyDelegate>
#endif

/**
 The content view for centering all of the content on the horizontal axis, adapting to its size.
 */
@property UIView *contentView;

@property UILabel *titleLabel, *descriptionLabel;
@property UIImageView *screenshotView, *iconView;

@property UIView *buttonArea;
@property UIButton *finishedButton;
@property UIButton *secondaryButton;

@property UIPageControl *pageControl;

@property BOOL checkComplete;

@property int triesToAcceptPermission;

@property LMLayoutManager *layoutManager;

@end

@implementation LMGuideViewController

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)threeBlindMice {
	NSLog(@"Some called the three blind mice");

	self.rootViewPagerController.currentPageNumber++;
	
	[self.sourcePagerController setViewControllers:@[self.nextViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (void)dismissViewController {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)completeTutorial {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:@"tutorialVersion1" forKey:LMSettingsKeyOnboardingComplete];
	[userDefaults synchronize];
	
	[[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)performOnboardingAction {
    NSLog(@"Hey bitch");
	switch(self.guideMode){
		case GuideModeOnboarding: {
			
			switch(self.index){
				case 0: {
					//Go to next slide
					[self threeBlindMice];
					break;
				}
//				case 1: {
//					
//					[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
//						[self threeBlindMice];
//					} repeats:NO];
//					
//					LMBackerLoginViewController *backerLoginViewController = [LMBackerLoginViewController new];
//					[self presentViewController:backerLoginViewController animated:YES completion:nil];
//					break;
//				}
				case 1: {
#ifdef SPOTIFY
					NSLog(@"Launch Spotify login");
					[[Spotify sharedInstance] openLoginOnViewController:self];
#else
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
								
								[LMAnswers logCustomEventWithName:@"Music Permission Status" customAttributes:@{ @"Status":@"Denied" }];
								break;
							}
							case SKCloudServiceAuthorizationStatusRestricted: {
								//Device might be in education mode or something
								buttonTitleToSet = @"Restricted";
								
								[LMAnswers logCustomEventWithName:@"Music Permission Status" customAttributes:@{ @"Status":@"Restricted" }];
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
//										[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(threeBlindMice) userInfo:nil repeats:NO];
										
										[self threeBlindMice];
										
//										[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(completeTutorial) userInfo:nil repeats:NO];
									});
								}];
								
								[LMAnswers logCustomEventWithName:@"Music Permission Status" customAttributes:@{ @"Status":@"Authorized" }];
								break;
							}
						}
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.finishedButton setTitle:NSLocalizedString(buttonTitleToSet, nil) forState:UIControlStateNormal];
						});
					}];
#endif
					break;
				}
				case 2: {
//					[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(completeTutorial) userInfo:nil repeats:NO];
					[self completeTutorial];
					break;
				}
			}
			
			break;
		}
		case GuideModeMusicPermissionDenied: {
            NSLog(@"Spookeeeed");
            
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
	if(self.index == 2){
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:@"yeah" forKey:LMGuideViewControllerUserWantsToViewTutorialKey];
		
		[self completeTutorial];
	}
	else{
		[self threeBlindMice];
	}
}

#ifdef SPOTIFY
- (void)sessionUpdated:(BOOL)isValid {
	if(isValid){
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.finishedButton setTitle:NSLocalizedString(@"GoodToGo", nil) forState:UIControlStateNormal];
			[NSTimer scheduledTimerWithTimeInterval:1.00 target:self selector:@selector(completeTutorial) userInfo:nil repeats:NO];
		});
	}
}
#endif

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	if(![LMLayoutManager isiPad]){
		self.descriptionLabel.textAlignment = willBeLandscape ? NSTextAlignmentCenter : NSTextAlignmentLeft;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:LMMusicTypeAlbums forKey:LMSettingsKeyLastOpenedSource];
	[defaults synchronize];
	
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	self.view.backgroundColor = [UIColor clearColor];
    
    self.contentView = [UIView newAutoLayoutView];
    self.contentView.userInteractionEnabled = YES;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentView];
    
    [self.contentView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    

	self.buttonArea = [UIView newAutoLayoutView];
	[self.contentView addSubview:self.buttonArea];
	
	self.finishedButton = [UIButton newAutoLayoutView];
	self.finishedButton.backgroundColor = [LMColour mainColour];
	self.finishedButton.titleLabel.textColor = [UIColor whiteColor];
	self.finishedButton.layer.masksToBounds = YES;
	self.finishedButton.layer.cornerRadius = 8.0;
	self.finishedButton.isAccessibilityElement = YES;
	self.finishedButton.accessibilityLabel = self.buttonAccessibilityLabel;
	self.finishedButton.accessibilityHint = self.buttonAccessibilityHint;
	[self.finishedButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
	[self.finishedButton addTarget:self action:@selector(performOnboardingAction) forControlEvents:UIControlEventTouchUpInside];
	[self.finishedButton setTitle:self.buttonTitle forState:UIControlStateNormal];
	
	if(self.index == 2){ //Tutorial view
		UIView *firstButtonArea = [UIView newAutoLayoutView];
//		firstButtonArea.backgroundColor = [UIColor redColor];
		[self.buttonArea addSubview:firstButtonArea];
		
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[firstButtonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[firstButtonArea autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonArea withMultiplier:(1.0/2.25)];
		
		self.secondaryButton = [UIButton newAutoLayoutView];
		self.secondaryButton.backgroundColor = [LMColour mainColour];
		self.secondaryButton.titleLabel.textColor = [UIColor whiteColor];
		self.secondaryButton.layer.masksToBounds = YES;
		self.secondaryButton.layer.cornerRadius = 8;
		self.secondaryButton.isAccessibilityElement = YES;
		self.secondaryButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_OnboardingButtonOpenTutorial", nil);
		self.secondaryButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_OnboardingButtonOpenTutorial", nil);
		[self.secondaryButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
		[self.secondaryButton addTarget:self action:@selector(secondaryAction) forControlEvents:UIControlEventTouchUpInside];
		[self.secondaryButton setTitle:NSLocalizedString(@"ViewTutorial", nil) forState:UIControlStateNormal];
		
		[firstButtonArea addSubview:self.secondaryButton];
		
		[self.secondaryButton autoPinEdgesToSuperviewEdges];
		
		
		UIView *secondButtonArea = [UIView newAutoLayoutView];
//		secondButtonArea.backgroundColor = [UIColor orangeColor];
		[self.buttonArea addSubview:secondButtonArea];
		
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[secondButtonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[secondButtonArea autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonArea withMultiplier:(1.0/2.25)];
		
		[secondButtonArea addSubview:self.finishedButton];
		
		[self.finishedButton autoPinEdgesToSuperviewEdges];
	}
	else{
        NSLog(@"Fuck is not a fuck");
		[self.buttonArea addSubview:self.finishedButton];
		
		[self.finishedButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.finishedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.finishedButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	}
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
	self.descriptionLabel.numberOfLines = 0;
//	self.descriptionLabel.backgroundColor = [UIColor yellowColor];
	self.descriptionLabel.text = self.contentDescription;
	self.descriptionLabel.textAlignment = (self.layoutManager.isLandscape || [LMLayoutManager isiPad]) ? NSTextAlignmentCenter : NSTextAlignmentJustified;
	[self.contentView addSubview:self.descriptionLabel];
	
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:26.0f];
	self.titleLabel.numberOfLines = 0;
//	self.titleLabel.backgroundColor = [UIColor orangeColor];
	self.titleLabel.text = self.contentTitle;
	[self.contentView addSubview:self.titleLabel];
	
	
	self.screenshotView = [UIImageView newAutoLayoutView];
//	self.screenshotView.backgroundColor = [UIColor redColor];
	self.screenshotView.contentMode = (self.guideMode == GuideModeOnboarding && self.index == 5) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
	self.screenshotView.image = self.screenshotImage;
	[self.contentView addSubview:self.screenshotView];
	
    
    [self.buttonArea autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.buttonArea autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.buttonArea autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:[LMLayoutManager isiPad] ? (1.0/14.0) : (LMLayoutManager.isiPhoneX ? (1.0/17.0) : (1.0/12.0))];
    [self.buttonArea autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(8.0/10.0)];
    
    [self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonArea withOffset:-20];
    [self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.buttonArea];
    [self.descriptionLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonArea];
    
    if(!self.screenshotImage){
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    }
    [self.titleLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.descriptionLabel withOffset:-15];
    [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.descriptionLabel];
    [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.descriptionLabel];

    if(self.screenshotImage){
        [self.screenshotView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.contentView];
        [self.screenshotView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel withOffset:-15];
        [self.screenshotView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
        [self.screenshotView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
        [self.screenshotView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/4.0)];
    }
    
	[self.contentView insertSubview:self.titleLabel aboveSubview:self.screenshotView];
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
