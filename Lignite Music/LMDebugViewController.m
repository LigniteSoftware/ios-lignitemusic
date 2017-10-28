//
//  LMDebugViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMReachability.h"
#import "LMDebugViewController.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "MBProgressHUD.h"
#import "LMImageManager.h"
#import "LMMusicPlayer.h"
#import "LMSettings.h"
#import "LMScrollView.h"

@interface LMDebugViewController ()

@property LMScrollView *scrollView;

@property UILabel *titleLabel;
@property UILabel *toClipboardButton;
@property UILabel *debugLabel;

@end

@implementation LMDebugViewController

+ (uint64_t)diskBytesFree {
	uint64_t totalFreeSpace = 0;
	NSError *error = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
	if (dictionary) {
		NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
		totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
	}
	else {
		NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
	}
	
	return totalFreeSpace;
}

+ (BOOL)isOnCellularData {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status == ReachableViaWWAN;
}

+ (BOOL)hasInternetConnection {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status != NotReachable;
}

- (void)shitpost {
	NSLog(@"heyasd");
	
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = self.debugLabel.text;
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	//	hud.label.text = NSLocalizedString(@"ImagesDeleted", nil);
	
	[hud hideAnimated:YES afterDelay:2.0f];
}

+ (NSString*)currentAppVersion {
	return @"1.1 RC";
}

+ (NSString*)appDebugInfoString {
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSMutableString *debugString = [NSMutableString stringWithFormat:@"\nVersion %@ (build %@)", [LMDebugViewController currentAppVersion], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	[debugString appendString:[NSString stringWithFormat:@"\n\nLanguage: %@", [[NSLocale preferredLanguages] objectAtIndex:0]]];
	[debugString appendString:[NSString stringWithFormat:@"\niOS: %@", [[UIDevice currentDevice] systemVersion]]];
	[debugString appendString:[NSString stringWithFormat:@"\nModel: %@", [[UIDevice currentDevice] model]]];
	
	[debugString appendString:[NSString stringWithFormat:@"\n\nSong count: %lu", (unsigned long)[[musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles] objectAtIndex:0].count]];
	
	
	//	[debugString appendString:[NSString stringWithFormat:@"\n\nSong count: %lu", (unsigned long)[MPMediaQuery songsQuery].items.count]];
	[debugString appendString:[NSString stringWithFormat:@"\nNow playing: %@\nPID: %llu\nSL: %f", musicPlayer.nowPlayingTrack.title, musicPlayer.nowPlayingTrack.persistentID, musicPlayer.nowPlayingTrack.playbackDuration]];
	[debugString appendString:[NSString stringWithFormat:@"\n\nBytes free: %llu", [LMDebugViewController diskBytesFree]]];
	[debugString appendString:[NSString stringWithFormat:@"\nArtist cache: %lu", (unsigned long)[imageManager sizeOfCacheForCategory:LMImageManagerCategoryArtistImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nAlbum cache: %lu", (unsigned long)[imageManager sizeOfCacheForCategory:LMImageManagerCategoryAlbumImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nHigh quality images: %d", [defaults boolForKey:LMSettingsKeyHighQualityImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nExplicit download permission: %d", [imageManager explicitPermissionStatus]]];
	[debugString appendString:[NSString stringWithFormat:@"\nInternet: %d", [LMDebugViewController hasInternetConnection]]];
	[debugString appendString:[NSString stringWithFormat:@"\nCellular: %d", [LMDebugViewController isOnCellularData]]];
	[debugString appendString:[NSString stringWithFormat:@"\n\nStatus bar: %d", [defaults boolForKey:LMSettingsKeyStatusBar]]];
	[debugString appendString:[NSString stringWithFormat:@"\nOBS: %@", [defaults objectForKey:LMSettingsKeyOnboardingComplete]]];
	
	[debugString appendString:[NSString stringWithFormat:@"\n\nNSUserDefault keys: %@", [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]]];
	
	return debugString;
}

- (void)loadShit {
	NSString *debugString = [LMDebugViewController appDebugInfoString];
	
	for(UIView *subview in self.view.subviews) {
		[subview removeFromSuperview];
	}
	
	
	self.scrollView = [LMScrollView newAutoLayoutView];
	self.scrollView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.scrollView];
	
	[self.scrollView autoPinEdgesToSuperviewEdges];
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40];
	self.titleLabel.text = @"Debug Info";
	self.titleLabel.numberOfLines = 0;
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	[self.scrollView addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.scrollView withOffset:88];
	[self.titleLabel autoSetDimension:ALDimensionWidth toSize:self.view.frame.size.width];
	
	
	self.toClipboardButton = [UILabel newAutoLayoutView];
	self.toClipboardButton.text = @"Copy";
	self.toClipboardButton.textAlignment = NSTextAlignmentCenter;
	self.toClipboardButton.numberOfLines = 0;
	self.toClipboardButton.layer.masksToBounds = YES;
	self.toClipboardButton.layer.cornerRadius = 10.0;
	self.toClipboardButton.backgroundColor = [LMColour ligniteRedColour];
	self.toClipboardButton.textColor = [UIColor whiteColor];
	self.toClipboardButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
	self.toClipboardButton.userInteractionEnabled = YES;
	[self.scrollView addSubview:self.toClipboardButton];
	
	[self.toClipboardButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
	[self.toClipboardButton autoSetDimension:ALDimensionWidth toSize:self.view.frame.size.width * 0.9];
	[self.toClipboardButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.toClipboardButton autoSetDimension:ALDimensionHeight toSize:self.view.frame.size.height/8.0];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(shitpost)];
	[self.toClipboardButton addGestureRecognizer:tapGesture];
	
	
	self.debugLabel = [UILabel newAutoLayoutView];
	self.debugLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
	self.debugLabel.text = debugString;
	self.debugLabel.numberOfLines = 0;
	self.debugLabel.textAlignment = NSTextAlignmentLeft;
	[self.scrollView addSubview:self.debugLabel];
	
	[self.debugLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.toClipboardButton withOffset:10.0f];
	[self.debugLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.debugLabel autoSetDimension:ALDimensionWidth toSize:self.view.frame.size.width*0.9];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	UIImageView *hangOnImage = [UIImageView newAutoLayoutView];
	hangOnImage.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	hangOnImage.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:hangOnImage];
	
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:88];
	[hangOnImage autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/3.0)];
	
	UILabel *hangOnLabel = [UILabel newAutoLayoutView];
	hangOnLabel.text = NSLocalizedString(@"HangOn", nil);
	hangOnLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
	hangOnLabel.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:hangOnLabel];
	
	[hangOnLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:hangOnImage withOffset:10];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(loadShit) userInfo:nil repeats:NO];
	
	NSLog(@"Loaded");
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load view");
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
