//
//  LMPlaylistManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistManager.h"
#import "LMAlertView.h"
#import "LMColour.h"

@interface LMPlaylistManager()

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPlaylistManager

@synthesize userUnderstandsPlaylistManagement = _userUnderstandsPlaylistManagement;

/* Begin internal playlist management code */

- (NSArray<LMPlaylist*>*)playlists {
	return @[  ];
}

/* End internal playlist management code */

/* Begin playlist management understanding code */

- (void)launchPlaylistManagementWarningOnView:(UIView*)view withCompletionHandler:(void(^)())completionHandler {
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	
	alertView.title = NSLocalizedString(@"PlaylistManagementUnderstandingTitle", nil);
	alertView.body = NSLocalizedString(@"PlaylistManagementUnderstandingBody", nil);
	alertView.alertOptionColours = @[ [LMColour ligniteRedColour] ];
	alertView.alertOptionTitles = @[ NSLocalizedString(@"IUnderstand", nil) ];
	
	[alertView launchOnView:view withCompletionHandler:^(NSUInteger optionSelected) {
		[self setUserUnderstandsPlaylistManagement:YES];
		
		completionHandler();
		
		NSLog(@"Cool, launch playlist creator");
	}];
}

- (BOOL)userUnderstandsPlaylistManagement {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMUserUnderstandsPlaylistManagementKey]){
		return [userDefaults boolForKey:LMUserUnderstandsPlaylistManagementKey];
	}
	return NO;
}

- (void)setUserUnderstandsPlaylistManagement:(BOOL)userUnderstandsPlaylistManagement {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:userUnderstandsPlaylistManagement forKey:LMUserUnderstandsPlaylistManagementKey];
	[userDefaults synchronize];
}

/* End playlist management understanding code */


/* Begin initialization code */

- (instancetype)init {
	self = [super init];
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	NSLog(@"Done.");
	
	return self;
}

+ (LMPlaylistManager*)sharedPlaylistManager {
	static LMPlaylistManager *sharedPlaylistManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPlaylistManager = [self new];
	});
	return sharedPlaylistManager;
}

/* End initialization code */

@end
