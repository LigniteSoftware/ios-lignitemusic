//
//  Spotify.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "Spotify.h"

@interface Spotify() <SFSafariViewControllerDelegate>

/**
 The view controller for authorizing Spotify in-app for those that don't have the native Spotify app installed.
 */
@property SFSafariViewController *authViewController;

/**
 The array of delegates.
 */
@property NSMutableArray<id<SpotifyDelegate>> *delegates;

@end

@implementation Spotify

+ (instancetype)sharedInstance {
	static Spotify *sharedSpotify;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedSpotify = [self new];
		
		sharedSpotify.delegates = [NSMutableArray new];
	});
		
	return sharedSpotify;
}

- (void)addDelegate:(id<SpotifyDelegate>)delegate {
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SpotifyDelegate>)delegate {
	[self.delegates removeObject:delegate];
}

- (void)sessionUpdated {
	SPTAuth *auth = [SPTAuth defaultInstance];
	[self.authViewController dismissViewControllerAnimated:YES completion:nil];
	
	BOOL sessionIsGood = auth.session && [auth.session isValid];
	
	for(id<SpotifyDelegate> delegate in self.delegates){
		if([delegate respondsToSelector:@selector(sessionUpdated:)]){
			[delegate sessionUpdated:sessionIsGood];
		}
	}
}

- (void)openLoginOnViewController:(UIViewController*)viewController {
	SPTAuth *auth = [SPTAuth defaultInstance];
	
	if ([SPTAuth supportsApplicationAuthentication] && true == false) {
		[[UIApplication sharedApplication] openURL:[auth spotifyAppAuthenticationURL]];
	} else {
		self.authViewController = [[SFSafariViewController alloc] initWithURL:[[SPTAuth defaultInstance] spotifyWebAuthenticationURL]];
		self.authViewController.delegate = self;
		self.authViewController.modalPresentationStyle = UIModalPresentationPageSheet;
		[viewController presentViewController:self.authViewController
									 animated:YES
								   completion:nil];
	}
}

@end
