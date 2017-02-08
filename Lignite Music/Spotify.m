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

@property SFSafariViewController *authViewController;

@end

@implementation Spotify

+ (id)sharedInstance {
	static Spotify *sharedSpotify;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedSpotify = [self new];
	});
		
	return sharedSpotify;
}

- (void)sessionUpdated {
	SPTAuth *auth = [SPTAuth defaultInstance];
	[self.authViewController dismissViewControllerAnimated:YES completion:nil];
	
	if (auth.session && [auth.session isValid]) {
		NSLog(@"Good to go");
	} else {
		NSLog(@"*** Failed to log in");
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
