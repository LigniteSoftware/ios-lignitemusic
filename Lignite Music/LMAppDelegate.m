//
//  AppDelegate.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <StoreKit/StoreKit.h>
#import <Crashlytics/Crashlytics.h>

#import "AFNetworking.h"
#import "LMAppDelegate.h"
#import "LMMusicPlayer.h"
#import "LMAppIcon.h"
#import "LMSettings.h"

@interface LMAppDelegate ()

/**
 The delegate's music player.
 */
@property (nonatomic) LMMusicPlayer *musicPlayer;

@end

@implementation LMAppDelegate

- (LMMusicPlayer*)musicPlayer {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(!_musicPlayer && [userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
        return [LMMusicPlayer sharedMusicPlayer];
    }
    return _musicPlayer;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[LMAppDelegate]: Will finish launching with launch options %@", launchOptions);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if(![userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
		NSLog(@"Launch onboarding...");
	}
	else{
		[SKCloudServiceController requestAuthorization:^(SKCloudServiceAuthorizationStatus status) {
			switch(status){
				case SKCloudServiceAuthorizationStatusNotDetermined:
				case SKCloudServiceAuthorizationStatusRestricted:
				case SKCloudServiceAuthorizationStatusDenied: {
					NSLog(@"Launch how to fix");
					break;
				}
				case SKCloudServiceAuthorizationStatusAuthorized: {
					NSLog(@"Push main view controller");
					break;
				}
			}
		}];
	}
	
	NSLog(@"Exiting");
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[LMAppDelegate]: Did finish launching with options %@", launchOptions);
	
	NSTimeInterval delegateStartTime = [[NSDate new] timeIntervalSince1970];
	
	[[Fabric sharedSDK] setDebug:NO];
	
#ifdef DEBUG
	NSLog(@"Setting to internal fabric.io organization.");
	[Crashlytics startWithAPIKey:@"a47ad8454b2466904b779cc64b6dca8ba21db95c"];
#else
	NSLog(@"Setting to production fabric.io organization.");
	[Crashlytics startWithAPIKey:@"63b415ad88e31c971ef0208169ac2967178e23fc"];
#endif
	[Fabric with:@[[Crashlytics class]]];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
    if([userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
        self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
    }
	
	NSTimeInterval delegateEndTime = [[NSDate new] timeIntervalSince1970];
	NSLog(@"Loaded delegate in %f seconds.", delegateEndTime-delegateStartTime);
	
    return YES;
}


- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
	NSLog(@"See you later");
	return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
	NSLog(@"Restoring application state");
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will resign active.");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Entering background.");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will enter foreground.");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will become active.");

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will terminate.");
	
//	NSLog(@"Setting %@", self.musicPlayer.nowPlayingTrack.title);
	
	[self.musicPlayer saveNowPlayingState];
	
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
