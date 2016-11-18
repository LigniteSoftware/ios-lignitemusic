//
//  AppDelegate.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMAppDelegate.h"
#import "LMMusicPlayer.h"
#import "LMAppIcon.h"
#import "LMSettings.h"

@interface LMAppDelegate ()

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMAppDelegate

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	
	NSLog(@"Allahu");
	
	int indexOfItem = -1;
	NSArray<UIApplicationShortcutItem*>*shortcutItems = [UIApplication sharedApplication].shortcutItems;
	for(int i = 0; i < shortcutItems.count; i++){
		UIApplicationShortcutItem *item = [shortcutItems objectAtIndex:i];
		if([item.type isEqualToString:shortcutItem.type]){
			indexOfItem = i;
		}
	}
	
	if(indexOfItem > -1){
		LMMusicPlayer *currentMusicPlayer = [LMMusicPlayer sharedMusicPlayer];
		if(currentMusicPlayer.sourceSelector){
			[currentMusicPlayer.sourceSelector setCurrentSourceWithIndex:indexOfItem];
		}
		else{
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setInteger:indexOfItem forKey:LMSettingsKeyLastOpenedSource];
		}
	}
	
	completionHandler(YES);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[LMAppDelegate]: Did finish launching with options");
	
    // Override point for customization after application launch.
//	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	NSLog(@"Actually finished");
	
//	const int amountOfItems = 2;
//	LMIcon icons[] = {
//		LMIconAlbums, LMIconTitles
//	};
//	NSString *titles[] = {
//		@"Albums", @"Titles"
//	};
//	NSMutableArray *shortcutItems = [NSMutableArray new];
//	for(int i = 0; i < amountOfItems; i++){
//		UIApplicationShortcutIcon *icon = [UIApplicationShortcutIcon iconWithTemplateImageName: [LMAppIcon filenameForIcon:icons[i]]]; // your customize icon
//		UIApplicationShortcutItem *item = [[UIApplicationShortcutItem alloc]initWithType:titles[i] localizedTitle:NSLocalizedString(titles[i], nil) localizedSubtitle:nil icon:icon userInfo: nil];
//		[shortcutItems addObject:item];
//	}
	
	[UIApplication sharedApplication].shortcutItems = nil;
	
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
	
	[self.musicPlayer prepareForActivation];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will terminate.");
	
	NSLog(@"Setting %@", self.musicPlayer.nowPlayingTrack.title);
	
	[self.musicPlayer prepareForTermination];
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
