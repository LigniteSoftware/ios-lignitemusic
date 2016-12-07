//
//  LMDebugView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <PureLayout/PureLayout.h>
#import "LMReachability.h"
#import "LMDebugView.h"
#import "LMColour.h"
#import "LMImageManager.h"
#import "LMMusicPlayer.h"
#import "LMSettings.h"

@interface LMDebugView()

@property UILabel *titleLabel;
@property UILabel *toClipboardButton;
@property UILabel *debugLabel;

@property BOOL didLayout;

@end

@implementation LMDebugView

+ (uint64_t)diskBytesFree {
	uint64_t totalSpace = 0;
	uint64_t totalFreeSpace = 0;
	NSError *error = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
	if (dictionary) {
		NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
		NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
		totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
		totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
	}
	else {
		NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
	}
	
	return totalFreeSpace;
}

- (BOOL)isOnCellularData {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status == ReachableViaWWAN;
}

- (BOOL)hasInternetConnection {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status != NotReachable;
}

- (void)shitpost {
	NSLog(@"heyasd");
	
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = self.debugLabel.text;
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
//	hud.label.text = NSLocalizedString(@"ImagesDeleted", nil);
	
	[hud hideAnimated:YES afterDelay:2.0f];
}

- (void)layoutSubviews {
	if(self.didLayout){
		return;
	}
	
	self.didLayout = YES;
	
	self.backgroundColor = [UIColor whiteColor];
	
	self.userInteractionEnabled = YES;
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40];
	self.titleLabel.text = @"Debug Info";
	self.titleLabel.numberOfLines = 0;
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	[self addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:30];
	[self.titleLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width];
	
	
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
	[self addSubview:self.toClipboardButton];
	
	[self.toClipboardButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:10];
	[self.toClipboardButton autoSetDimension:ALDimensionWidth toSize:self.frame.size.width * 0.9];
	[self.toClipboardButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.toClipboardButton autoSetDimension:ALDimensionHeight toSize:self.frame.size.height/8.0];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(shitpost)];
	[self.toClipboardButton addGestureRecognizer:tapGesture];
	
	
	LMImageManager *imageManager = [LMImageManager sharedImageManager];
	LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
	
	NSMutableString *debugString = [NSMutableString stringWithFormat:@"\nBuild %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	[debugString appendString:[NSString stringWithFormat:@"\n\nSong count: %lu", (unsigned long)[[musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles] objectAtIndex:0].count]];
	
	[debugString appendString:[NSString stringWithFormat:@"\n\nSong count: %lu", (unsigned long)[musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles].count]];
	
	NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to load titles.", endTime-startTime);
	
	
//	[debugString appendString:[NSString stringWithFormat:@"\n\nSong count: %lu", (unsigned long)[MPMediaQuery songsQuery].items.count]];
	[debugString appendString:[NSString stringWithFormat:@"\nNow playing: %@\nNPPID: %llu\nNPTL: %fs", musicPlayer.nowPlayingTrack.title, musicPlayer.nowPlayingTrack.persistentID, musicPlayer.nowPlayingTrack.playbackDuration]];
	[debugString appendString:[NSString stringWithFormat:@"\nBytes free: %llu", [LMDebugView diskBytesFree]]];
	[debugString appendString:[NSString stringWithFormat:@"\nArtist cache: %lu", (unsigned long)[imageManager sizeOfCacheForCategory:LMImageManagerCategoryArtistImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nAlbum cache: %lu", (unsigned long)[imageManager sizeOfCacheForCategory:LMImageManagerCategoryAlbumImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nHigh quality images: %d", [defaults boolForKey:LMSettingsKeyHighQualityImages]]];
	[debugString appendString:[NSString stringWithFormat:@"\nDownload on low storage: %d", [imageManager permissionStatusForSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionLowStorage]]];
	[debugString appendString:[NSString stringWithFormat:@"\nDownload on cellular: %d", [imageManager permissionStatusForSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionCellularData]]];
	[debugString appendString:[NSString stringWithFormat:@"\nInternet: %d", [self hasInternetConnection]]];
	[debugString appendString:[NSString stringWithFormat:@"\nCellular: %d", [self isOnCellularData]]];
	[debugString appendString:[NSString stringWithFormat:@"\nStatus bar: %d", [defaults boolForKey:LMSettingsKeyStatusBar]]];
	[debugString appendString:[NSString stringWithFormat:@"\nOBS: %@", [defaults objectForKey:LMSettingsKeyOnboardingComplete]]];
	
	[debugString appendString:[NSString stringWithFormat:@"\n\nNSUserDefault keys: %@", [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]]];
	
	self.debugLabel = [UILabel newAutoLayoutView];
	self.debugLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
	self.debugLabel.text = debugString;
	self.debugLabel.numberOfLines = 0;
	self.debugLabel.textAlignment = NSTextAlignmentLeft;
	[self addSubview:self.debugLabel];
	
	[self.debugLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.toClipboardButton withOffset:10.0f];
	[self.debugLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.debugLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*0.9];
	
	[super layoutSubviews];
}

@end
