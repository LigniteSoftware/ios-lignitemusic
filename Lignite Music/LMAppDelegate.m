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
#import "LMAppleWatchBridge.h"
#import "NSTimer+Blocks.h"

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
	
	[LMAppleWatchBridge sharedAppleWatchBridge]; //This will activate the WCSession if it is supported.
	
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
	
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
    if(LMMusicPlayer.onboardingComplete){
        self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
    }
	
	NSTimeInterval delegateEndTime = [[NSDate new] timeIntervalSince1970];
	NSLog(@"Loaded delegate in %f seconds.", delegateEndTime-delegateStartTime);
	
    return YES;
}

- (UIViewController*)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	
	NSLog(@"Gotem %@", identifierComponents);
	
	return nil;
}


- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
	NSLog(@"See you later");
	return NO;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
	NSLog(@"Restoring application state");
	return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will resign active.");
	
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
	if (timer)
	{
		dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
		dispatch_source_set_event_handler(timer, block);
		dispatch_resume(timer);
	}
	return timer;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Entering background.");
	
	__block UIBackgroundTaskIdentifier bgTask;
	
	bgTask = [application beginBackgroundTaskWithName:@"FixCurrentPlaybackTime" expirationHandler:^{
		// Clean up any unfinished task business by marking where you
		// stopped or ending the task outright.
		
		NSLog(@"Background task is expiring, sorry.");
		
		[application endBackgroundTask:bgTask];
		bgTask = UIBackgroundTaskInvalid;
	}];
	
	// Start the long-running task and return immediately.
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
		
		// Do the work associated with the task, preferably in chunks.
		
		[self.musicPlayer prepareQueueForBackgrounding];
				
		NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:10.0 block:^{
			NSLog(@"Nigger");
			//
			//			dispatch_async(dispatch_get_main_queue(), ^{
			//				NSLog(@"time left %f", application.backgroundTimeRemaining);
			//			});
			
			NSLog(@"Ending background task");
			
			[application endBackgroundTask:bgTask];
			bgTask = UIBackgroundTaskInvalid;
		} repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		[[NSRunLoop currentRunLoop] run];
		
//		CreateDispatchTimer(5.0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//			NSLog(@"time left %f", application.backgroundTimeRemaining);
//
//			[application endBackgroundTask:bgTask];
//			bgTask = UIBackgroundTaskInvalid;
//		});
		
//		[NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
////			dispatch_async(dispatch_get_main_queue(), ^{
//				NSLog(@"time left %f", application.backgroundTimeRemaining);
//
//				[application endBackgroundTask:bgTask];
//				bgTask = UIBackgroundTaskInvalid;
////			});
//		}];
//
//		bgTask = UIBackgroundTaskInvalid;
	});
	
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will enter foreground.");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will become active.");
	
	[self.musicPlayer.queue rebuild];
	
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will terminate.");
	
//	NSLog(@"Setting %@", self.musicPlayer.nowPlayingTrack.title);
	
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
