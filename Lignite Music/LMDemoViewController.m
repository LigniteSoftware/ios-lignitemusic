//
//  LMDemoViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/6/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMDemoViewController.h"
#import "LMSectionTableView.h"
#import "LMLayoutManager.h"
#import "MBProgressHUD.h"
#import "LMSettings.h"
#import "LMAppIcon.h"
@import SDWebImage;

@interface LMDemoViewController ()<LMSectionTableViewDelegate>

/**
 The table view for the secret settings.
 */
@property LMSectionTableView *sectionTableView;

/**
 The image cache for the artists.
 */
@property SDImageCache *imageCache;

/**
 The progress HUD for downloading demo resources.
 */
@property MBProgressHUD *demoImageProgressHUD;

@end

@implementation LMDemoViewController

- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [LMAppIcon imageForIcon:LMIconFunctionality];
}

- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return @"General";
		default:
			return @"Unknown";
	}
}

- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	return 2;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0: {
			switch(indexPath.row){
				case 0:
					return @"Demo mode";
				case 1:
					return @"Fuck with artists";
			}
		}
	}
	return @"Unknown";
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(indexPath.section){
		case 0: {
			switch(indexPath.row){
				case 0:
					return nil;
//					return @"Only show music with LIGNITE_DEMO composer";
				case 1:
					return @"Make the artists look real";
			}
		}
	}
	return @"Unknown";
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return nil;// [LMAppIcon imageForIcon:LMIconBug];
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSLog(@"Tapped %@", indexPath);
}

- (void)downloadDemoImageWithIndex:(NSInteger)index {
	SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
	NSURL *demoImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.lignite.me/_demo/artists/%ld.png", (long)index]];
	[downloader downloadImageWithURL:demoImageURL
							 options:kNilOptions
							progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
								NSLog(@"%.02f%% complete", (CGFloat)receivedSize/(CGFloat)expectedSize * 100);
							}
						   completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
							   if(image && finished) {
								   NSLog(@"Downloaded image for inded %d with size %lu", (int)index, data.length);
								   
								   [[self imageCache] storeImage:image
														  forKey:[NSString stringWithFormat:@"%@_%d", LMDemoImageCache, (int)index]
													  completion:nil];
								   
								   self.demoImageProgressHUD.progress += 0.05;
								   
								   if(self.demoImageProgressHUD.progress > 0.95){
									   [self.demoImageProgressHUD hideAnimated:YES];
									   
									   UIAlertController *alert = [UIAlertController
																   alertControllerWithTitle:@"Demo Mode Enabled"
																   message:@"\nPlease force-close Lignite Music and open it again to apply your changes.\n\nIn demo mode, only music that has LIGNITE_DEMO in the composer ID3 tag will be displayed.\n\nPlaylists will not be filtered, so they will display their full contents regardless.\n\nEnjoy demo mode!\n"
																   preferredStyle:UIAlertControllerStyleAlert];
									   
									   [self presentViewController:alert animated:YES completion:nil];
								   }
							   }
						   }];
}

- (void)downloadDemoImages {
	for(NSInteger i = 0; i < 20; i++){
		[self downloadDemoImageWithIndex:i];
	}
}

- (void)changedDemoSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyDemoMode];
	[userDefaults synchronize];
	
	if(switchView.on){
		self.demoImageProgressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
		
		self.demoImageProgressHUD.mode = MBProgressHUDModeAnnularDeterminate;
		self.demoImageProgressHUD.userInteractionEnabled = YES;
		self.demoImageProgressHUD.label.text = @"Preparing...";
		
		[self downloadDemoImages];
		
//		[self.demoImageProgressHUD hideAnimated:YES afterDelay:1.5f];
	}
	else{
		[self.imageCache clearDiskOnCompletion:nil];
		
		UIAlertController *alert = [UIAlertController
									alertControllerWithTitle:@"Demo Mode Disabled"
									message:@"\nPlease force-close Lignite Music and open it again to apply your changes.\n"
									preferredStyle:UIAlertControllerStyleAlert];
		
		[self presentViewController:alert animated:YES completion:nil];
	}
}


- (void)changedArtistsFilteredSwitchView:(UISwitch*)switchView {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:switchView.on forKey:LMSettingsKeyArtistsFilteredForDemo];
	[userDefaults synchronize];
	

	NSString *body = @"\nPlease force-close Lignite Music and open it again to apply your changes.\n";
	NSString *title = @"No longer fucking with artists";
	
	if(switchView.on){
		title = @"Fucking with artists";
		body = @"\nPlease force-close Lignite Music and open it again to apply your changes.\n\nWhen artists are being fucked with, unique artists will be used throughout the app instead of the actual artist tag.\n\nThis is great for screenshots of artists, but terrible for anything else.\n\nCheers mate!";
	}
	
	UIAlertController *alert = [UIAlertController
								alertControllerWithTitle:title
								message:body
								preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}


- (id)accessoryViewForIndexPath:(NSIndexPath *)indexPath forSectionTableView:(LMSectionTableView *)sectionTableView {
	UISwitch *switchView = [UISwitch newAutoLayoutView];
	
	NSString *settingsKey = @"";
	BOOL enabled = NO;
	
	switch(indexPath.section){
		case 0:
			if(indexPath.row == 0){
				[switchView addTarget:self action:@selector(changedDemoSwitchView:) forControlEvents:UIControlEventValueChanged];
				
				enabled = NO; //Default
				settingsKey = LMSettingsKeyDemoMode;
			}
			else if(indexPath.row == 1){
				[switchView addTarget:self action:@selector(changedArtistsFilteredSwitchView:) forControlEvents:UIControlEventValueChanged];
				
				enabled = NO; //Default
				settingsKey = LMSettingsKeyArtistsFilteredForDemo;
			}
			break;
			
	}
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:settingsKey]){
		enabled = [userDefaults boolForKey:settingsKey];
	}
	
	switchView.on = enabled;
	
	return switchView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.imageCache = [[SDImageCache alloc] initWithNamespace:LMDemoImageCache];
	
	self.sectionTableView = [LMSectionTableView newAutoLayoutView];
	self.sectionTableView.contentsDelegate = self;
	self.sectionTableView.totalNumberOfSections = 1;
	self.sectionTableView.title = NSLocalizedString(@"SecretSettings", nil);
	self.sectionTableView.restorationIdentifier = @"LMAppSettingsSectionTableView";
	[self.view addSubview:self.sectionTableView];
	
	NSArray *sectionTableViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewPortraitConstraints:sectionTableViewPortraitConstraints];
	
	NSArray *sectionTableViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sectionTableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewLandscapeConstraints:sectionTableViewLandscapeConstraints];
	
	[self.sectionTableView setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor blueColor];
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
