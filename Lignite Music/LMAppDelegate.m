//
//  AppDelegate.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <SecureNSUserDefaults/NSUserDefaults+SecureAdditions.h>
#import <AFNetworking/AFNetworking.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "LMAppDelegate.h"
#import "LMMusicPlayer.h"
#import "LMAppIcon.h"
#import "LMSettings.h"
#import "LMPurchaseManager.h"

#ifdef SPOTIFY
#import "Spotify.h"
#endif

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

#ifdef SPOTIFY
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSLog(@"Got a request for URL %@", url);
	
	SPTAuth *auth = [SPTAuth defaultInstance];
	
	SPTAuthCallback authCallback = ^(NSError *error, SPTSession *session) {
		// This is the callback that'll be triggered when auth is completed (or fails).
		
		if (error) {
			NSLog(@"*** Auth error: %@", error);
		} else {
			auth.session = session;
			NSLog(@"Authenticated");
		}
		[[Spotify sharedInstance] sessionUpdated];
	};
	
	/*
	 Handle the callback from the authentication service. -[SPAuth -canHandleURL:]
	 helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
	 */
	
	if ([auth canHandleURL:url]) {
		[auth handleAuthCallbackWithTriggeredAuthURL:url callback:authCallback];
		return YES;
	}
	
	return NO;
}
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[LMAppDelegate]: Did finish launching with options.");
	
#ifdef SPOTIFY
	NSLog(@"You are running Lignite Music for Spotify! Woohoo!");
	
	SPTAuth *auth = [SPTAuth defaultInstance];
	
	NSLog(@"Auth %@", auth.session);
	auth.clientID = SpotifyClientID;
	auth.requestedScopes = @[SPTAuthStreamingScope, SPTAuthUserLibraryReadScope];
	auth.redirectURL = [NSURL URLWithString:SpotifyCallbackURL];
	auth.tokenSwapURL = [NSURL URLWithString:SpotifyTokenSwapServiceURL];
	auth.tokenRefreshURL = [NSURL URLWithString:SpotifyTokenRefreshServiceURL];
	auth.sessionUserDefaultsKey = SpotifySessionUserDefaultsKey;
#endif
	
	[[Fabric sharedSDK] setDebug:YES];
	
#ifdef DEBUG
	NSLog(@"Setting to internal fabric.io organization.");
	[Crashlytics startWithAPIKey:@"a47ad8454b2466904b779cc64b6dca8ba21db95c"];
#else
	NSLog(@"Setting to production fabric.io organization.");
	[Crashlytics startWithAPIKey:@"63b415ad88e31c971ef0208169ac2967178e23fc"];
#endif
	[Fabric with:@[[Crashlytics class]]];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setSecret:@"efd07a3e-8af2-4b19-9198-c8c67cbe93ab"];
	[userDefaults synchronize];
	
    // Override point for customization after application launch.
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
//	NSLog(@"Actually finished");
	
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
	
	NSLog(@"Email %@", [userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialEmail]);
	
	if([[LMPurchaseManager sharedPurchaseManager] appOwnershipStatus] == LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker) {
		NSDictionary *checkDictionary = @{
										  @"email": [userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialEmail],
										  @"password": @([userDefaults secretIntegerForKey:LMPurchaseManagerKickstarterLoginCredentialPassword]),
										  @"token": [userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialSessionToken]
										  };
		
		NSLog(@"Checking with %@", checkDictionary);
		
		NSString *URLString = @"https://api.lignite.me:1212/check";
		NSURLRequest *urlRequest = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:checkDictionary error:nil];
		
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
		
		AFHTTPResponseSerializer *responseSerializer = manager.responseSerializer;
		
		responseSerializer.acceptableContentTypes = [responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
		
		NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:urlRequest completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
			if (error) {
				NSLog(@"Error checking for validity %@", error);
			}
			else{
				NSDictionary *jsonDictionary = responseObject;
				
				if([jsonDictionary objectForKey:@"error"]){
					
				}
				else{
					BOOL validSession = [[jsonDictionary objectForKey:@"validSession"] boolValue];
					NSLog(@"Valid session %d", validSession);
					
					if(!validSession){
						[[LMPurchaseManager sharedPurchaseManager] logoutBacker];
					}
				}
			}
		}];
		[dataTask resume];
	}
	
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
	
#ifndef SPOTIFY
	[self.musicPlayer prepareForActivation];
#endif
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"[LMAppDelegate]: Will terminate.");
	
//	NSLog(@"Setting %@", self.musicPlayer.nowPlayingTrack.title);
	
	[self.musicPlayer saveNowPlayingState];
	
#ifndef SPOTIFY
	[self.musicPlayer prepareForTermination];
#endif
	
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
