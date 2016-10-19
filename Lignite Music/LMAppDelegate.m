//
//  AppDelegate.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMAppDelegate.h"

@interface LMAppDelegate ()

@end

@implementation LMAppDelegate

//- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
//	
//	NSLog(@"Got shortcut item %@", shortcutItem);
//	
//	completionHandler(YES);
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	NSLog(@"Suck?");
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	NSLog(@"Got options %@", launchOptions);
	
//	UIApplicationShortcutIcon * photoIcon = [UIApplicationShortcutIcon iconWithTemplateImageName: @"selfie-100.png"]; // your customize icon
//	UIApplicationShortcutItem * photoItem = [[UIApplicationShortcutItem alloc]initWithType: @"Test" localizedTitle: @"Testing this" localizedSubtitle:@"Shitpost" icon: [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeAudio] userInfo: nil];
//	UIApplicationShortcutItem * videoItem = [[UIApplicationShortcutItem alloc]initWithType: @"Post" localizedTitle: @"What is this meme" localizedSubtitle:@"Average" icon: [UIApplicationShortcutIcon iconWithType: UIApplicationShortcutIconTypeCaptureVideo] userInfo: nil];
//	
//	[UIApplication sharedApplication].shortcutItems = @[photoItem,videoItem];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"Will resign active.");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"Entering background.");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"Will enter foreground.");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"Will become active.");
	
	[self.musicPlayer prepareForActivation];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"Will terminate.");
	
	NSLog(@"Setting %@", self.musicPlayer.nowPlayingTrack.title);
	
	[self.musicPlayer prepareForTermination];
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
